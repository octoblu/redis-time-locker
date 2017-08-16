moment      = require 'moment'
_           = require 'lodash'
RedisLocker = require '../models/redis-locker'

locker = ({redis, reqPath='body', uuidPath, timestampPath}) ->
  (req, res, next) ->
    data      = _.get req, reqPath
    uuid      = _.get data, uuidPath
    timestamp = _.get data, timestampPath, moment.utc().format()

    redisLocker = new RedisLocker {uuid, timestamp, redis}
    redisLocker.lockBlock (error, lock) =>
      return res.sendStatus error.code || 500 if error?
      req.lock = lock
      next()

unlocker = ->
  (req, res, next) ->
    return next() unless req.lock?
    req.lock.unlock -> next()

module.exports = {locker, unlocker}
