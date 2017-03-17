var fs = require("fs");
var path = require("path");
var sm = require("source-map");

var t = Date.now();
var smc = new sm.SourceMapConsumer(
    JSON.parse(
        fs.readFileSync(
            path.join(__dirname, "closure-src-map")
        )
    )
);
smc._parseMappings(smc._mappings, smc.sourceRoot);
console.log((Date.now() - t) / 1000);

while (true) {
    
}
