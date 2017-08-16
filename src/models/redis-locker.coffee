Redlock = require 'redlock'

class RedisLocker
  constructor: ({@redis, @uuid, @timestamp}) ->
    @redlock = new Redlock [@redis], retryCount: 60, retryDelay: 500
    throw new Error('NO TIME') unless @timestamp?
    throw new Error('NO UUID') unless @uuid?


  lockBlock: (callback) =>
    @redlock.lock "lock:uuid:#{@uuid}", 30000, (error, lock) =>
      return callback error if error?
      return _.defer @lockBlock, callback unless lock?
      unlockCallback = (error) =>
        lock.unlock => callback error

      @_isFutureTimestamp (error, canProcess) =>
        return unlockCallback error if error?
        return callback(null, lock) if canProcess

        error = new Error 'Refusing to process older message'
        error.code = 202
        return unlockCallback error

  _isFutureTimestamp: (callback) =>
    @redis.get "cache:timestamp:#{@uuid}", (error, previousTimestamp) =>
      return callback error if error?
      try
        previousTimestamp = JSON.parse previousTimestamp if previousTimestamp?
      catch error
        # ignore

      isFuture = true
      isFuture = @timestamp > previousTimestamp if previousTimestamp?
      return callback null, false unless isFuture
      @redis.set "cache:timestamp:#{@uuid}", JSON.stringify(@timestamp), (error) =>
        return callback error if error?
        return callback null, true

module.exports = RedisLocker
