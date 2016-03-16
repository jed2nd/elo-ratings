Ratings = model('v2/ratings')
Users   = model('v2/users')
config  = include('../config')

module.exports =
	show: (ctx, res) ->
		id = ctx.params.id.toLowerCase()
		return res.invalid() unless id?

		query = {sport: id}

		if ctx.params.type?
			query.type = ctx.params.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query, {hydrate: true})

		ret = {}

		users = []
		for r in ratings

			ret[r.type] ?= []
			ret[r.type].push r

		for type, arr of ret
			ret[type] = ret[type].sort((a,b) -> a.ladderPos > b.ladderPos)
		res.ok(ret)
