pug = require 'pug'
MongoClient = require("mongodb").MongoClient
moment = require 'moment-timezone'
URL = "mongodb://localhost:27017/secret_board"
DATABSE = 'secret_board'
util = require './handler-util'
contents = []

handle = (req, res) ->
  switch req.method
    when 'GET'
      MongoClient.connect URL, {useNewUrlParser: true}, (error, client) ->
        col = client.db(DATABSE).collection('Post')
        col.find({}).sort({createdAt: -1}).toArray (err, items) ->
          posts = items
          res.writeHead 200, {
            'Content-Type': 'text/html; charset=utf-8'
          }
          res.end pug.renderFile './views/posts.pug', {
            posts: items
          }
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
          db.collection 'Post'
            .insertOne({
              content: content,
              trackingCookie: null,
              postedBy: req.user,
              createdAt: new Date
            }).then ->
              client.close()
              handleRedirectPosts req, res
    else
      util.handleBadRequest req, res
      break

handleRedirectPosts = (req, res) ->
  res.writeHead 303, {
    'Location': '/posts'
  }
  res.end()

module.exports = {
  handle: handle
}