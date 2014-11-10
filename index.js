require('coffee-script/register');

// Try to require the global log singleton if set
var log, Logger = require('./helpers/Logger');
try {
  log = require('log');
  if (!log instanceof Logger)
    log = null;
} catch (e) {}
if (!log) {
  log = require('./utils/log');
}

module.exports = {
  fs: require('./utils/fs'),
  string: require('./utils/string'),
  object: require('./utils/object'),
  ps: require('./utils/ps'),
  log: log
};
