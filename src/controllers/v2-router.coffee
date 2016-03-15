router = require('koa-route')
v2 = include('controllers/v2')
console.log v2

loadAction = (resource, action) ->
  r = v2[resource]
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
	server.use(router.get("/v2/:resource", list))
	server.use(router.get("/v2/:resource/:id", show))
	server.use(router.post("/v2/:resource", create))
	server.use(router.put("/v2/:resource/:id", update))
	server.use(router.patch("/v2/:resource/:id", patch))
	server.use(router.delete("/v2/:resource/:id", destroy))
	server.use -> yield invalid(null, @.response)
