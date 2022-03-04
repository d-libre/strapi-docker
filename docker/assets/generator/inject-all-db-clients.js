#!/usr/bin/env node

const dbDepends = require("./lib/utils/db-client-dependencies");
const _ = require("lodash");
const fs = require("fs");
const path = require('path');

appDir = process.env.SRC_PATH || '/src/';
targetPath = path.resolve(appDir, 'package.json');

var packageJson = require(targetPath);
console.log("Original Package was:\n", JSON.stringify(packageJson, null, 2));

strapiVersion = process.env.VERSION;
isV3 = strapiVersion.startsWith("3");
scope = { strapiVersion };

extraClients = ["postgres", "mysql"]; // "sqlite" is included already since the app was generated with --quickstart
// Adding support for mongo (v3.x.x only)
if (isV3) extraClients.unshift("mongo");

dependencies = {};
extraClients.forEach((client) => {
  d = dbDepends({ scope, client });
  // console.log("%j", d);
  dependencies = _.merge(dependencies, d);
});
// console.log("Merged: %j", dependencies);

packageJson = _.merge(packageJson, { dependencies });

try {
  fs.writeFileSync(targetPath, JSON.stringify(packageJson, null, 2) + "\n");
  //file written successfully
} catch (err) {
  console.error(err);
}
