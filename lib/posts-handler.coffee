crypto = require 'crypto'
pug = require 'pug'
Cookies = require 'cookies'
MongoClient = require("mongodb").MongoClient
autoIncrement = require "mongodb-autoincrement"
moment = require 'moment-timezone'
URL = process.env.MONGODB_URI || "mongodb://localhost:27017/secret_board"
collectionName = process.env.COLLECTION || 'Post'
DATABSE = process.env.DATABSE || 'secret_board'
util = require './handler-util'
contents = []

trackingIdKey = 'tracking_id'

oneTimeTokenMap = new Map # キーをユーザー名、値をトークンとする連想配列

handle = (req, res) ->
  cookies = new Cookies req, res
  trackingId = addTrackingCookie cookies, req.user
  switch req.method
    when 'GET'
      MongoClient.connect URL, { useNewUrlParser: true }
        .then (db, err) ->
          throw err if err
          db = db.db DATABSE
          collection = db.collection collectionName
          collection
            .find({})
            .sort({createdAt: -1})
            .toArray()
            .then (data) ->
              posts = data
              posts.forEach (post) ->
                post.content = post.content.replace(/\+/g, ' ')
                post.formattedCreatedAt = moment(post.createdAt).tz('Asia/Tokyo').format('YYYY年MM月DD日 HH時mm分ss秒')
              oneTimeToken = crypto.randomBytes(8).toString 'hex'
              oneTimeTokenMap.set req.user, oneTimeToken
              res.end pug.renderFile './views/posts.pug', {
                posts: posts
                user: req.user
                oneTimeToken: oneTimeToken
              }
              console.info "閲覧されました:\n
                            user: #{req.user}\n
                            trackingId: #{trackingId}\n
                            remoteAddress: #{req.connection.remoteAddress}\n
                            userAgent: #{req.headers['user-agent']}"
    when 'POST'
      body = []
      req.on('data', (chunk) ->
        body.push(chunk)
      ).on 'end', ->

        body = Buffer.concat(body).toString()
        decoded = decodeURIComponent body
        dataArray = decoded.split('&')
        content = if dataArray[0] then dataArray[0].split('content=')[1] else ''
        requestedOneTimeToken = if dataArray[1] then dataArray[1].split('oneTimeToken=')[1] else ''

        MongoClient.connect URL, {useNewUrlParser: true}
          .then (db, err) ->
            throw err if err
            if oneTimeTokenMap.get(req.user) == requestedOneTimeToken
              console.info "投稿されました: #{content}"
              db = db.db DATABSE
              autoIncrement.getNextSequence db, collectionName, (err, autoIndex) ->
                throw err if err

                query =
                  _id: autoIndex
                  content: content
                  trackingCookie: trackingId
                  postedBy: req.user
                  createdAt: new Date

                collection = db.collection collectionName
                collection
                  .insertOne query
                  .then ->
                    oneTimeTokenMap.delete req.user
                    handleRedirectPosts req, res
            else
              util.handleBadRequest req, res
    else
      util.handleBadRequest req, res
      break

handleDelete = (req, res) ->
  switch req.method
    when 'POST'
      body = []
      req.on('data', (chunk) ->
        body.push(chunk)
      ).on 'end', ->

        body = Buffer.concat(body).toString()
        decoded = decodeURIComponent body
        dataArray = decoded.split '&'
        id = if dataArray[0] then dataArray[0].split('_id=')[1] else ''
        requestedOneTimeToken = if dataArray[1] then dataArray[1].split('oneTimeToken=')[1] else ''

        if oneTimeTokenMap.get(req.user) == requestedOneTimeToken
          MongoClient.connect URL, {useNewUrlParser: true}
            .then (db, err) ->
              throw err if err
              db = db.db DATABSE

              query =
                _id: parseInt id

              collection = db.collection collectionName
              collection
                .deleteOne query
                .then ->
                  console.log '1 document deleted'
                  console.info "削除されました: user: #{req.user}\n
                            remoteAddress: #{req.connection.remoteAddress}\n
                            userAgent: #{req.headers['user-agent']}"
                  oneTimeTokenMap.delete req.user
                  handleRedirectPosts req, res
        else
          util.handleBadRequest req, res
    else
      util.handleBadRequest req, res
      break

# Cookieに含まれているトラッキングIDに異常がなければその値を返し、
# 存在しない場合や異常なものである場合には、再度作成しCookieに付与してその値を返す
# @param {Cookies} cookies
# @param {String} userName
# @return {String} トラッキングID

addTrackingCookie = (cookies, userName) ->
  requestedTrackingId = cookies.get trackingIdKey
  if isValidTrackingId requestedTrackingId, userName
    return requestedTrackingId
  else
    originalId = parseInt crypto.randomBytes(8).toString('hex'), 16
    tomorrow = new Date new Date().getTime() + (1000 * 60 * 60 * 24)
    trackingId = "#{originalId}_#{createValidHash(originalId, userName)}"
    cookies.set trackingIdKey, trackingId, { expires: tomorrow }
    return trackingId

isValidTrackingId = (trackingId, userName) ->
  if !trackingId
    return false

  splitted = trackingId.split('_')
  originalId = splitted[0]
  requestedHash = splitted[1]
  return createValidHash originalId, userName == requestedHash

secretKey = '5a69bb55532235125986a0df24aca759f69bae045c7a66d6e2bc4652e3efb43da4'

createValidHash = (originalId, userName) ->
  sha1sum = crypto.createHash 'sha1'
  sha1sum.update(originalId + userName + secretKey)
  return sha1sum.digest 'hex'

handleRedirectPosts = (req, res) ->
  res.writeHead 303, {
    'Location': '/posts'
  }
  res.end()

module.exports = {
  handle: handle
  handleDelete: handleDelete
}