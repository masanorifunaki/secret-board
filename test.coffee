pug = require 'pug'
assert = require 'assert'

# pug のテンプレートにおける XSS 脆弱性のテスト
html = pug.renderFile './views/posts.pug',
  posts: [{
    id: 1,
    content: '<script>alert(\'test\');</script>',
    postedBy: 'guest1',
    trackingCookie: '5923192338728767_2d8304240bf6b6f4e63c1efe96586ebf036f9260',
    createdAt: new Date(),
  }],
  user: 'guest1'

# スクリプトタグがエスケープされて含まれていることをチェック
assert html.indexOf('&lt;script&gt;alert(\'test\');&lt;/script&gt;') > 0
console.log 'テストが正常に完了しました'