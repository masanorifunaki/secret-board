handleLogout = (req, res) ->
  res.writeHead(401, {
    'Content-Type': 'text/plain; charset=utf-8'
  })
  res.end 'ログアウトしました'

handleNotFound = (req, res) ->
  res.writeHead(404, {
    'Content-Type': 'text/plain; charset=utf-8'
  })
  res.end 'ページがみつかりません'

handleBadRequest = (req, res) ->
  res.writeHead(400, {
    'Content-Type': 'text/plain; charset=utf-8'
  })
  res.end '未対応のメソッドです'


module.exports = {
  handleLogout: handleLogout,
  handleNotFound: handleNotFound,
  handleBadRequest: handleBadRequest
}