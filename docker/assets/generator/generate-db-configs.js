#!/usr/bin/env node

const _ = require("lodash");
const fs = require("fs");
const path = require('path');

const defaultConfigs = require('./lib/utils/db-configs');
const parseDatabaseArguments = require('./lib/utils/parse-db-arguments');
const createDatabaseConfig = require('./lib/resources/templates/database.js');

const strapiVersion = process.env.VERSION;
const rootPath = process.env.SRC_PATH;

let inArgs = process.argv.slice(2);
const configsDir = inArgs.length > 0 ? inArgs[0] : '/var/local/configs';
// Create directory (if required)
if (!fs.existsSync(configsDir)){
  fs.mkdirSync(configsDir);
}

const clientPorts = {
  sqlite: null,
  mysql: 3306,
  postgres: 5432,
  mongo: 27017,
}

const baseScope = {
  rootPath,
  strapiVersion,
};

const baseArguments = {
  dbhost: "localhost",
  dbname: "strapi",
  dbusername: "strapi",
  dbpassword: "SecretPassphrase",
}

function generateDbConfigFor(client) {
  var clientScope = Object.assign({ client }, baseScope);
  console.log("Client Scope for %s: %j", client, clientScope);
  
  var defaultClientArgs = Object.assign({ dbclient : client, dbport: clientPorts[client] }, baseArguments);
  console.log("Default Arguments for %s Client: %j", client, defaultClientArgs);
  
  parseDatabaseArguments({ scope : clientScope, args: defaultClientArgs });
  
  // const client = scope.database.settings.client;  // LOL
  connection = _.merge({}, defaultConfigs[client] || {}, clientScope.database);
  
  configFileContent = createDatabaseConfig({
    client,
    connection,
  });
  
  console.log("Connection for %s:\n%s\n", client, JSON.stringify(connection, null, 2));
  
  try {
    filePath = path.resolve(configsDir, client + ".js");
    fs.writeFileSync(filePath, configFileContent+'\n');
    //file written successfully
  } catch (err) {
    console.error(err);
  }
}

Object.keys(clientPorts).forEach(client => {
  generateDbConfigFor(client);
});
