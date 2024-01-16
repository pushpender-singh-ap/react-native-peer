#!/bin/bash

exec 2>&1

rm -rf dist/ peerjs/
git clone https://github.com/peers/peerjs peerjs
cd peerjs
git checkout tags/v1.5.2
git apply ../decoupling.diff
../node_modules/.bin/parcel build --no-source-maps lib/exports.ts -d ../dist --out-file peerjs.min.js
cd ../
cat imports.js dist/peerjs.min.js > dist/react-native-peer.js
cp index.d.ts dist/
rm dist/peerjs.min.js
rm -rf peerjs/

echo "Done. dist/react-native-peer.js"

