User = model('v1/user')

module.exports =
  list: (ctx, res) ->
    users = yield User.listAll()

    numUsers = users.length

    for user in users
      user.rank = numUsers - users.filter((u) -> u.rating < user.rating).length

    users.sort((a,b) -> b.rating - a.rating)
    res.ok({users: users})
