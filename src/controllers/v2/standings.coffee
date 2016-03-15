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

		ratings = yield Ratings.listWithQuery(query)

		ret = {}

		users = []
		for r in ratings
			users = []
			console.log r
			for id in r.ids
				users.push yield Users.findById(id)
			r.players = users

			ret[r.type] ?= []
			ret[r.type].push r

		for type, arr of ret
			ret[type] = ret[type].sort((a,b) -> a.ladderPos > b.ladderPos)
		res.ok(ret)
