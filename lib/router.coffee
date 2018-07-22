postsHandler = require './posts-handler.coffee'

route = (req, res) ->
  switch req.url
    when '/posts'
      postsHandler.handle req, res
    else
      break

module.exports = {
  route: route
}
