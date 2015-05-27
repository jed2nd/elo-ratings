module.exports = (response) ->

	response.cache = (ttl) ->
		this.set('cache-control', 'public,max-age=' + ttl)
		this

	response.created = -> @._end(201); null

	response.ok = (body) -> @._end(200, body); null

	response.notFound = -> @._end(404, '{"error": "not found", "code": 404}'); null

	response.invalid = (err) ->
		if err?
			err.code = 400 if err instanceof Object && !err.code?
			@._end(400, err)
		else
			@._end(400, '{"error": "invalid", "code": 400}')
		null

	response.notAuthorized = -> @._end(401, '{"error": "not authorized", "code": 401}'); null

	response._end = (status, body = '') ->
		this.set('Content-Type', 'application/json')
		this.status = status
		this.body = body
		null
