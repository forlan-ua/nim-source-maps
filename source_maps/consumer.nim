import json
import strutils
import sequtils
import typetraits
import os


const VERSION: uint8 = 3


type
    Mapping = object
        generatedLine: uint
        generatedColumn: uint
        source: string
        originalLine: uint
        originalColumn: uint
        name: string

    SourceMap = object
        version: uint8
        sources: seq[string]
        names: seq[string]
        mappings: seq[string]

        file: string
        sourceRoot: string
        sourcesContent: seq[string]

    SourceMapConsumer* = ref object of RootObj
        map: SourceMap
        originalMappings*: seq[Mapping]
        generatedMappings*: seq[ptr Mapping]

    IndexedSourceMapConsumerSection = object
        generatedLine: uint
        generatedColumn: uint
        consumer: SourceMapConsumer

    IndexedSourceMapConsumer = ref object of SourceMapConsumer
        sections = seq[IndexedSourceMapConsumerSection]

    BasicSourceMapConsumer = ref object of SourceMapConsumer


proc initSourceMap*(sm: JsonNode): auto =
    let version = uint8(sm{"version"}.getNum())
    if version != VERSION:
        raise newException(ValueError, "Unsupported version: " & $version)

    var sources = map(sm{"sources"}.getElems(), proc (x: JsonNode): string = x.getStr())
    var names = map(sm{"names"}.getElems(), proc (x: JsonNode): string = x.getStr())
    var mappings = map(sm{"mappings"}.getElems(), proc (x: JsonNode): string = x.getStr())

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


proc initSourceMap*(json: string): auto =
    initSourceMap(parseJson(json))


proc initSourceMap*(filename: string): auto =
    initSourceMap(parseFile(filename))


proc newSourceMapConsumer*(sm: JsonNode): auto =
    let length = 10

    SourceMapConsumer(
        map: initSourceMap(sm = sm),
        generatedMappings: newSeq[Mapping](length),
        originalMappings: newSeq[ptr Mapping](length)
    )


proc newSourceMapConsumer*(filename: string): auto =
    newSourceMapConsumer(parseFile(filename))


proc newSourceMapConsumer*(json: string): auto =
    newSourceMapConsumer(parseJson(json))


proc parseMappings(self: SourceMapConsumer) =
  discard


iterator items(self: SourceMapConsumer): Mapping =
    yield Mapping()


proc allGeneratedPositionsFor(self: SourceMapConsumer, line: uint): seq[Mapping] =
    return @[Mapping()]


proc sourceContentFor =
    discard


proc generatedPositionFor = 
    discard


proc originalPositionFor =
    discard


proc hasContentsOfAllSources = 
    discard