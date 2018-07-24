pug = require 'pug'
Cookies = require 'cookies'
MongoClient = require("mongodb").MongoClient
autoIncrement = require "mongodb-autoincrement"
moment = require 'moment-timezone'
URL = "mongodb://localhost:27017/secret_board"
collectionName = 'Post'
DATABSE = 'secret_board'
util = require './handler-util'
contents = []

trackingIdKey = 'tracking_id'

handle = (req, res) ->
  cookies = new Cookies req, res
  addTrackingCookie cookies
  switch req.method
    when 'GET'
      MongoClient.connect URL, {useNewUrlParser: true}, (err, client) ->
        throw err if err
        db = client.db(DATABSE)
        collection = db.collection collectionName
        collection.find({}).sort({createdAt: -1}).toArray (err, items) ->
          throw err if err
          posts = items
          res.writeHead 200, {
            'Content-Type': 'text/html; charset=utf-8'
          }
          res.end pug.renderFile './views/posts.pug', {
            posts: items
            user: req.user
          }
          console.info "閲覧されました:\n
                        user: #{req.user}\n
                        trackingId: #{cookies.get(trackingIdKey)}\n
                        remoteAddress: #{req.connection.remoteAddress}\n
                        userAgent: #{req.headers['user-agent']}"
          client.close()
    when 'POST'
      body = []
      req.on('data', (chunk) ->
        body.push(chunk)
      ).on 'end', ->
        body = Buffer.concat(body).toString()
        decoded = decodeURIComponent body
        content = decoded.split('content=')[1]
        console.log "投稿されました: #{content}"
        MongoClient.connect URL, {useNewUrlParser: true}, (error, client) ->
          db = client.db DATABSE
          autoIncrement.getNextSequence db, collectionName, (err, autoIndex) ->
            collection = db.collection collectionName
            collection
              .insertOne({
                _id: autoIndex
                content: content
                trackingCookie: cookies.get trackingIdKey
                postedBy: req.user
                createdAt: new Date
              }).then ->
                client.close()
                handleRedirectPosts req, res
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
        id = decoded.split('_id=')[1]
        MongoClient.connect URL, {useNewUrlParser: true}, (error, client) ->
          db = client.db DATABSE
          query = { _id : parseInt id }
          collection = db.collection collectionName
          collection
            .deleteOne query, (err, obj) ->
              throw err if err
              console.log '1 document deleted'
              client.close()
              console.info "削除されました: user: #{req.user}\n
                        remoteAddress: #{req.connection.remoteAddress}\n
                        userAgent: #{req.headers['user-agent']}"
              handleRedirectPosts req, res
    else
      util.handleBadRequest req, res
      break


addTrackingCookie = (cookies) ->
  if !cookies.get(trackingIdKey)
    trackingId = Math.floor Math.random() * Number.MAX_SAFE_INTEGER
    tomorrow = new Date new Date().getTime() + (1000 * 60 * 60 * 24)
    cookies.set trackingIdKey, trackingId, { expires: tomorrow }

handleRedirectPosts = (req, res) ->
  res.writeHead 303, {
    'Location': '/posts'
  }
  res.end()

module.exports = {
  handle: handle
  handleDelete: handleDelete
}