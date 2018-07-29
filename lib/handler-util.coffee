fs = require 'fs'

handleLogout = (req, res) ->
  res.writeHead(401, {
    'Content-Type': 'text/html; charset=utf-8'
  })
  res.end '<!DOCTYPE html><html lang="ja"><body>
          <h1>ログアウトしました</h1>
          <a href="/posts">ログイン</a>
          </body></html>'

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

handleFavicon = (req, res) ->
  res.writeHead(200, {
    'Content-Type': 'image/vnd.microsoft.icon'
  })
  favicon = fs.readFileSync './favicon.ico'
  res.end favicon

module.exports = {
  handleLogout: handleLogout,
  handleNotFound: handleNotFound,
  handleBadRequest: handleBadRequest,
  handleFavicon: handleFavicon
}