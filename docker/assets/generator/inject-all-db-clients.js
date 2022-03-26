#!/usr/bin/env node

const dbDepends = require('./utils/db-client-dependencies');
const _ = require('lodash');
const fs = require('fs');
const path = require('path');

var targetPath = "";
var packageJson = { };

function tryGetPackage(dir) {
  targetPath = path.resolve(dir, 'package.json');
  if (fs.existsSync(targetPath)) {
    packageJson = require(targetPath);
    return true;
  }
}

appDir = process.env.APP_PATH || '/srv/app/';
cfgDir = process.env.CFG_PATH || '/var/local/configs/';

tryGetPackage(appDir) || tryGetPackage(cfgDir);

if (!_.isEmpty(packageJson)) {
  console.log("Original Package found at ", targetPath);
  console.log(JSON.stringify(packageJson, null, 2));
} else {
  console.log("No currently available package.json. A new one will be generated instead");
}

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
