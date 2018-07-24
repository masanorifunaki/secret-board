http = require 'http'
auth = require 'http-auth'
router = require './lib/router.coffee'

basic = auth.basic {
  realm: 'Enter username and password.',
  file: './users.htpasswd'
}

server = http.createServer(basic, (req, res) ->
  router.route(req, res)
).on('error', (e) ->
  console.error 'Server Error', e
).on('clientError', (e) ->
  console.error 'Client Error', e
)

port = 8000
server.listen port, ->
  console.info "Listening on #{port}"