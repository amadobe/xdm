#!/usr/bin/env bash

git clone https://github.com/adobe/xdm.git tempmaster
(cd tempmaster/bin/xed-validation; pwd; cp ../../../xed-master-gen.sh .; ./xed-master-gen.sh) #get master branch xed

(rm -rf tempinput xed; mkdir tempinput)
cp -r ../../schemas ./tempinput/
cp -r ../../extensions ./tempinput/

(echo "++++++++++Start clean-up for XED conversion of platform schemas only.....++++++++++"; sleep 1)
./cleaninput.sh #cleanup non-platform central repo xdms

(echo "++++++++++Start XED conversion pre-processing.....++++++++++"; sleep 1)
node schemaLocGen.js
node tempGen.js -i tempinput/schemas -j xdm
node tempGen.js -i tempinput/extensions -j xdm-extensions

(echo "++++++++++Start XED conversion processing++++++++++....."; sleep 1)
node xedGen.js -i xdm -j tempxed
node xedGen.js -i xdm-extensions -j tempxed

(echo "++++++++++Start XED schemas field tagging..... ++++++++++"; sleep 1)
echo "{}" > tags.json
node tag4xed.js -i tempxed -j xed

(echo "++++++++++Search changed schemas..... ++++++++++"; sleep 1)
diff -rq tempmaster/bin/xed-validation/xed xed/ | sed -E "s/: /\\//g" > schemaChanges.log

(echo "++++++++++Start XED schema validation..... ++++++++++"; sleep 1)
./compile.sh
returnCode=$?

if [ $returnCode -ne 0 ]; then
  echo "There are schema validation errors!"
  (rm -rf tempinput xdm xdm-extensions tempxed tags.json schemaLoc.json schemaChanges.log tempmaster) #cleanup temp folders
  exit 1
else
  echo "All good"
  (rm -rf tempinput xdm xdm-extensions tempxed tags.json schemaLoc.json schemaChanges.log tempmaster) #cleanup temp folders
fi
