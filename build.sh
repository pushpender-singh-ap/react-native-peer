#!/bin/bash

exec 2>&1
set -e

rm -rf dist/ peerjs/
git clone --depth 1 --branch v1.5.5 https://github.com/peers/peerjs peerjs
cd peerjs
git apply ../decoupling.diff
echo "export const version = \"$(node -p "require('./package.json').version")\";" > lib/version.ts

# Replace peerjs's multi-target build config with a single bundle target for react-native
node -e '
const fs = require("fs");
const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
for (const field of ["main", "module", "types", "source", "scripts", "targets",
	"browser-minified", "browser-unminified", "browser-minified-msgpack"]) {
	delete pkg[field];
}
pkg["react-native-peer"] = "output/peerjs.min.js";
pkg.targets = {
	"react-native-peer": {
		source: "lib/exports.ts",
		context: "browser",
		outputFormat: "esmodule",
		isLibrary: true,
		optimize: true,
		engines: { browsers: "chrome >= 83" },
	},
};
fs.writeFileSync("package.json", JSON.stringify(pkg, null, "\t"));
'

../node_modules/.bin/parcel build --no-source-maps --no-cache
cd ../
mkdir -p dist
cat imports.js peerjs/output/peerjs.min.js > dist/react-native-peer.js
cp index.d.ts dist/
rm -rf peerjs/

echo "Done. dist/react-native-peer.js"
