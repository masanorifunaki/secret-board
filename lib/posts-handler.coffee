pug = require 'pug'
contents = []

handle = (req, res) ->
  switch req.method
    when 'GET'
      res.writeHead 200, {
        'Content-Type': 'text/html; charset=utf-8'
      }
      res.end pug.renderFile './views/posts.pug', {}
    when 'POST'
      body = []
      req.on('data', (chunk) ->
        body.push(chunk)
      ).on('end', ->
        body = Buffer.concat(body).toString()
        decoded = decodeURIComponent body
        content = decoded.split('content=')[1]
        console.log "投稿されました: #{content}"
        contents.push content
        console.log "投稿された全内容: #{contents}"
        handleRedirectPosts req, res
      )
    else
      break

handleRedirectPosts = (req, res) ->
  res.writeHead 303, {
    'Location': '/posts'
  }
  res.end()

module.exports = {
  handle: handle
}