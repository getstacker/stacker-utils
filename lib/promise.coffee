# Promise utils

module.exports =
  isPromise: (obj) ->
    obj && 'function' == typeof obj.then

  isGenerator: (obj) ->
    obj && 'function' == typeof obj.next && 'function' == typeof obj.throw
