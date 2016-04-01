User = model('v1/user')
config = require('../../../config')

module.exports =

  list: (ctx, res) ->
    console.log "listing"
    users = yield User.listAll()
    res.ok({users: users})
    
  show: (ctx, res) ->
    id = ctx.params.id

    user = yield User.findById(id)
    return res.notFound() unless user?

    res.ok({user: user})

  create: (ctx, res) ->
    return res.invalid() unless ctx.body.name?

    id = yield User.create(ctx, ctx.body)
    res.ok({id: id})

  update: (ctx, res) ->
    return res.invalid() unless ctx.params.id?

    user = yield User.findByName(ctx.params.id)
    return res.ok({user}) unless ctx.body.retire

    console.log 'retiring', user

    user.retired = true
    
    yield slide(Infinity, user.ladderPos)

    yield User.update(user)

    res.ok({user})

slide = (high, low) ->
  users = yield User.listAll()
  for user in users when !user.retired
    if user.ladderPos > low && user.ladderPos <= high
      user.ladderPos = user.ladderPos-1
      yield User.update(user)
  return
