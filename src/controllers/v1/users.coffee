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
