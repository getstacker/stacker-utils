require('coffee-script/register');
require('stacker-globals');

module.exports = {
  fs: require('./lib/fs'),
  string: require('./lib/string'),
  object: require('./lib/object'),
  ps: require('./lib/ps')
};
