node_spawn = require('child_process').spawn
escapeRegExp = require('./string').escapeRegExp
path = require 'path'

# globals
_ = require 'stacker/_'
{Promise} = require 'stacker/promise'
log = require 'stacker/log'

node_exec = Promise.promisify require('child_process').exec


setOptions = (opts) ->
  {log, execDefaults} = opts


execDefaults = (cmd, opts) ->
  # remove spaces from cmd and extract the bin name
  cmd = cmd.replace /\/(.+?)\s+(.+?)\//g, '/$1$2/'
  cmd = cmd.split(' ')[0].split(path.sep).slice(-1)[0]
  debug = (type, msg) ->
    log.debug type, msg.toString().trim()  if msg
    msg
  _.defaults opts,
    stdout: debug.bind null, "#{cmd} stdout >>".grey
    stderr: debug.bind null, '#{cmd} stderr >>'.grey
    timeout: 1000


###*
# @param {Array} cmds  Array of string or array commands.
#                      String commands will use process.exec.
#                      Array commands will use process.spawn.
###
# runCmds = (cmds, opts = {}) ->
#   _.defaults opts,
#     sequential: false
#     timeout: 1000
#   execFunc = (cmd) ->
#     if _.isArray cmd
#       spawn.apply null, arguments
#     else
#       exec.apply null, arguments
#   if sequential
#     execFunc cmds.shift(), opts
#     .then ->
#       runCmds cmds, opts
#   else
#     pcmds = for c in cmds
#       execFunc c, opts
#     Promise.all pcmds



###*
@return Promise
Usage:
exec(cmd, opts).spread (stdout, stderr) ->
###
exec = (cmd, opts = {}) ->
  execDefaults cmd, opts
  log.debug "[exec]".grey, cmd
  node_exec cmd, opts
  .spread (stdout, stderr) ->
    opts.stdout stdout
    opts.stderr stderr
    [stdout, stderr]


###*
@param {mixed} cmd  String cmd or Array of [cmd, args]
@return {Number}    Process ID
###
spawn = (cmd, args = [], opts = {}) ->
  if _.isArray cmd
    opts = args
    args = cmd[1]
    cmd = cmd[0]
  execDefaults cmd, opts
  # todo: use cancellable and timeout
  new Promise (resolve, reject) ->
    log.debug "[spawn]".grey, "#{cmd} #{args.join ' '}"
    proc = node_spawn cmd, args, opts
    if opts.detached
      pid = proc.pid
      proc.unref()
      resolve pid: pid
    else
      _stdout = ''
      _stderr = ''
      proc.stdout.on 'data', (data) ->
        _stdout += opts.stdout data
      proc.stderr.on 'data', (data) ->
        _stderr += opts.stderr data
      proc.on 'close', (code) ->
        ret = stdout: _stdout, stderr: _stderr, code: code
        code is 0 and resolve(ret) or reject(ret)


# @return {Array}  pids
pgrep = (cmd, opts = {}) ->
  _.defaults opts,
    timeout: 100
    oldest: false
    stdout: helpers.silent
  flags = if opts.oldest then '-o' else ''
  exec "pgrep #{flags} -d ',' -f #{cmd}", opts
  .spread (stdout, stderr) ->
    pids = stdout.trim().split(',').map (pid) ->
      parseInt pid
    _.compact pids
  .catch (err) ->
    # pgrep returns 1 when process is not found
    if err.cause and err.cause.code is 1
      Promise.resolve []
    else
      log.error '[pgrep]'.grey, err
      Promise.reject err


kill = (pid, signal = 'SIGTERM') ->
  if pid
    log.debug '[kill]'.grey, "Sending #{signal} to #{pid}"
    process.kill pid, signal


killAll = (cmd, signal = 'SIGTERM', opts = {}) ->
  pgrep cmd, opts
  .then (pids) ->
    kill pid, signal for pid in pids


stats = (cmd, opts = {}) ->
  # ps -A -c -o pid,%cpu,%mem,rss,time,etime,command | awk 'NR == 1 || /[V]Box/' | sed -e 's/^ */"/' -e 's/$/\"/g' -e $'s/[[:space:]]\{1,\}/","/g'
  pscmd = 'ps -A -c -o pid,%cpu,%mem,rss,time,etime,args'
  pscmd += " | awk 'NR == 1 || /#{escapeRegExp cmd}/"
  pscmd += ' | sed -e \'s/^ */"/\' -e \'s/$/\"/g\' -e $\'s/[[:space:]]\{1,\}/","/g\''
  exec pscmd, opts
  .spread (stdout, stderr) ->
    stdout.trim().split ','


helpers =
  intercept: (msg) ->
    process.stderr.write msg.toString()
    ''
  # Discard output
  ignore: (msg) ->
    ''
  # Suppress debug output
  silent: (msg) ->
    msg


# API
module.exports =
  setOptions: setOptions
  exec: exec
  spawn: spawn
  pgrep: pgrep
  kill: kill
  killAll: killAll
  stats: stats
