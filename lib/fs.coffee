path = require 'path'
os = require 'os'
randomString = require('./string').random

# globals
_ = 'stacker/_'
Promise = 'stacker/promise'

fs = Promise.promisifyAll require('fs')


module.exports = UtilsFs =
  ###*
  Create specified directory.

  Creates parent directories as needed. Same as `mkdir -p`.
  @return {promise}
  ###
  mkdir: (dir, mode) ->
    dir = path.resolve dir
    if _.isUndefined mode
      mode = 0o777 & (~process.umask())
    fs.statAsync dir
    .then (stat) ->
      unless stat.isDirectory()
        throw "#{dir} exists and is not a directory"
      stat
    .catch (err) =>
      if err.cause.code is 'ENOENT'
        UtilsFs.mkdir path.dirname(dir), mode
        .then ->
          fs.mkdirAsync dir, mode
      else
        throw err

  ###*
  Get a random file name in the OS's tmp dir.

  Does not guarantee uniqueness.
  ###
  randomTmpFile: (filename) ->
    filename = randomString 10  unless filename
    path.join os.tmpdir(), UtilsFs.randomTmpDir(), filename


  ###*
  Get random dir in OS's tmp dir.

  Does not guarantee uniqueness.
  ###
  randomTmpDir: (base) ->
    base ?= path.join os.tmpdir(), 'stacker'
    dir = [
      'tmp-'
      process.pid
      '-'
      (Math.random() * 0x1000000000).toString 36
    ].join ''
    path.join base, dir, randomString 5
