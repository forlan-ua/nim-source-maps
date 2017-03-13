import json
import strutils
import sequtils
import tables

import moz_base64vlq


const VERSION: uint8 = 3


type
    Mapping = object
        generatedLine*: int
        generatedColumn*: int
        source*: int
        originalLine*: int
        originalColumn*: int
        name*: int

    SourceMap = ref object
        version*: uint8
        sources*: seq[string]
        names*: seq[string]
        mappings*: string

        file*: string
        sourceRoot*: string
        sourcesContent*: seq[string]

        parsedMappings*: seq[Mapping]

    SourceMapConsumer* = ref object of RootObj
        map*: SourceMap
        originalMappings*: seq[ptr Mapping]
        generatedMappings*: seq[ptr Mapping]


proc `$`*(self: Mapping): string =
    """{"generatedLine":$generatedLine,"generatedColumn":$generatedColumn,"source":$source,"originalLine":$originalLine,"originalColumn":$originalColumn,"name":$name}""" % [
        "generatedLine", $self.generatedLine,
        "generatedColumn", $self.generatedColumn,
        "source", $self.source,
        "originalLine", $self.originalLine,
        "originalColumn", $self.originalColumn,
        "name", $self.name
    ]


proc parse*(self: SourceMap) =
    self.parsedMappings = newSeq[Mapping]()

    var generatedLine = 1
    var previousGeneratedColumn = 0
    var previousOriginalLine = 0
    var previousOriginalColumn = 0
    var previousSource = 0
    var previousName = 0
    var length = self.mappings.len
    var index = 0

    var generatedColumn, source, originalLine, originalColumn, name: int

    var endIndex: int
    var str: string

    var size = 1;
    var size_2 = float(high(self.names))
    while size_2 > 2:
        size = size shl 1
        size_2 = size_2 / 2

    var cachedSegments = initTable[string, array[6, int]](initialSize=size*64)
    var segment: array[6, int]

    while index < length:
        if self.mappings[index] == ';':
            generatedLine.inc
            index.inc
            previousGeneratedColumn = 0;
            continue

        if self.mappings[index] == ',':
            index.inc;
            continue

        # Because each offset is encoded relative to the previous one,
        # many segments often have the same encoding. We can exploit this
        # fact by caching the parsed variable length fields of each segment,
        # allowing us to avoid a second parse if we encounter the same
        # segment again.
        endIndex = index
        while endIndex < length:
            if self.mappings[endIndex] == ',' or self.mappings[endIndex] == ';':
                break
            endIndex.inc

        str = self.mappings[index..endIndex-1]

        if cachedSegments.hasKey(str):
            segment = cachedSegments[str]
        else:
            segment = [0, 0, 0, 0, 0, 0]

            var indexInSegment, indexInStr: int;
            while indexInStr < str.len:
                let temp = moz_base64vlq.decode(str, indexInStr)
                indexInStr = temp[1]
                if indexInSegment < 5:
                    segment[indexInSegment] = temp[0]
                indexInSegment.inc

            case indexInSegment:
                of 0, 1: segment[5] = -1
                of 2: raise newException(ValueError, "Found a source, but no line and column")
                of 3: raise newException(ValueError, "Found a source and line, but no column")
                of 4: discard
                else: segment[5] = 1

            cachedSegments.add(str, segment)

        generatedColumn = -1
        source = -1
        originalLine = -1
        originalColumn = -1
        name = -1

        if segment[5] > -1:
            # Generated column.
            generatedColumn = previousGeneratedColumn + segment[0]
            previousGeneratedColumn = generatedColumn

            # Original source.
            source = previousSource + segment[1]
            previousSource += segment[1];

            # Original line.
            # Lines are stored 0-based
            originalLine = previousOriginalLine + segment[2] + 1;
            previousOriginalLine = originalLine - 1;

            # Original column.
            originalColumn = previousOriginalColumn + segment[3];
            previousOriginalColumn = originalColumn;

            if segment[5] == 1:
                # Original name.
                name = previousName + segment[4]
                previousName += segment[4]

        self.parsedMappings.add(
            Mapping(
                generatedLine: generatedLine,
                generatedColumn: generatedColumn,
                source: source,
                originalLine: originalLine,
                originalColumn: originalColumn,
                name: name
            )
        )

        index = endIndex


proc initSourceMap*(sm: JsonNode): auto =
    let version = uint8(sm{"version"}.getNum())
    if version != VERSION:
        raise newException(ValueError, "Unsupported version: " & $version)

    var sources = map(sm{"sources"}.getElems(), proc (x: JsonNode): string = x.getStr())
    var names = map(sm{"names"}.getElems(), proc (x: JsonNode): string = x.getStr())
    var mappings = sm{"mappings"}.getStr()

    var file = sm{"file"}.getStr("")
    var sourceRoot = sm{"sourceRoot"}.getStr("")

    var sourcesContent: seq[string]
    if sm.hasKey("sourcesContent"):
        sourcesContent = map(sm{"sourcesContent"}.getElems(), proc (x: JsonNode): string = x.getStr())
    else:
        sourcesContent = newSeq[string](high(names))

    SourceMap(
        version: version,
        sources: sources,
        names: names,
        mappings: mappings,

        file: file,
        sourceRoot: sourceRoot,
        sourcesContent: sourcesContent
    )


proc parse*(self: SourceMapConsumer) =
    self.map.parse()


proc newSourceMapConsumer*(sm: JsonNode, parse=true): auto =
    result = SourceMapConsumer(
        map: initSourceMap(sm)
    )

    if parse:
        result.parse()

proc newSourceMapConsumer*(json: string, parse=true): auto =
    newSourceMapConsumer(parseJson(json), parse)


proc newSourceMapConsumer*(filename: string, parse=true): auto =
    newSourceMapConsumer(parseFile(filename), parse)
