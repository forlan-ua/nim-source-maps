import os
import times
import json
import strutils

import ../source_maps/consumer

proc runTest* =
    var t = cpuTime()
    let smc = newSourceMapConsumer(filename="tests/closure-src-map", parse=false)
    smc.parse()
    echo "Parse time: " & $(cpuTime() - t)

    var total = 0

    for kind, file in walkDir(getCurrentDir() / "tests"):
        var startIndex = -1
        let filename = extractFilename(file)
        if kind == pcFile and filename.startsWith("parsed") and filename.endsWith(".json"):
            startIndex = parseInt(filename.replace("parsed", "").replace(".json", ""))

        if startIndex == -1:
            continue

        echo file

        let testJson = parseFile(file)
        for index, item in testJson.getElems():
            total.inc

            var myItem = smc.map.parsedMappings[index + startIndex*1000000]

            if myItem.generatedLine != int(item{"generatedLine"}.getNum(-1)):
                raise newException(ValueError, $index & ": generatedLine|" & $myItem.generatedLine & "|" & $int(item{"generatedLine"}.getNum(-1)))

            if myItem.generatedColumn != int(item{"generatedColumn"}.getNum(-1)):
                raise newException(ValueError, $index & ": generatedColumn|" & $myItem.generatedColumn & "|" & $int(item{"generatedColumn"}.getNum(-1)))

            if myItem.source != int(item{"source"}.getNum(-1)):
                raise newException(ValueError, $index & ": source|" & $myItem.source & "|" & $int(item{"source"}.getNum(-1)))

            if myItem.originalLine != int(item{"originalLine"}.getNum(-1)):
                raise newException(ValueError, $index & ": originalLine|" & $myItem.originalLine & "|" & $int(item{"originalLine"}.getNum(-1)))

            if myItem.originalColumn != int(item{"originalColumn"}.getNum(-1)):
                raise newException(ValueError, $index & ": originalColumn|" & $myItem.originalColumn & "|" & $int(item{"originalColumn"}.getNum(-1)))

            if myItem.name != int(item{"name"}.getNum(-1)):
                raise newException(ValueError, $index & ": name|" & $myItem.name & "|" & $int(item{"name"}.getNum(-1)))

    if total != smc.map.parsedMappings.len:
        raise newException(ValueError, "Size: " & $smc.map.parsedMappings.len & "|" & $total)

    echo "All OK!"
