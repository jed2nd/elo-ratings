router = require('koa-route')
v1 = include('controllers/v1')

loadAction = (resource, action) ->
  r = v1[resource]
  console.log 'load', resource, action
  if r? then r[action] || invalid else invalid

list = (resource) ->
	yield loadAction(resource, 'list')(this._context, this.response)

show = (resource, id) ->
	this._context.params = {id: id}
	yield loadAction(resource, 'show')(this._context, this.response)

create = (resource) ->
	yield loadAction(resource, 'create')(this._context, this.response)

update = (resource, id) ->
	this._context.params = {id: id}
	yield loadAction(resource, 'update')(this._context, this.response)

patch = (resource, id) ->
	this._context.params = {id: id}
	yield loadAction(resource, 'patch')(this._context, this.response)

destroy = (resource, id) ->
	this._context.params = {id: id}
	yield loadAction(resource, 'destroy')(this._context, this.response)

invalid = (ctx, res) ->
	res.notFound(404)
	yield return

module.exports = (server) ->
	server.use(router.get("/v1/:resource", list))
	server.use(router.get("/v1/:resource/:id", show))
	server.use(router.post("/v1/:resource", create))
	server.use(router.put("/v1/:resource/:id", update))
	server.use(router.patch("/v1/:resource/:id", patch))
	server.use(router.delete("/v1/:resource/:id", destroy))
	server.use -> yield invalid(null, @.response)
