postsHandler = require './posts-handler.coffee'
util = require './handler-util.coffee'

route = (req, res) ->
  switch req.url
    when '/posts'
      postsHandler.handle req, res
    when '/posts?delete=1'
      postsHandler.handleDelete req, res
    when '/logout'
      util.handleLogout req, res
    else
      util.handleNotFound req, res
      break

module.exports = {
  route: route
}
