Ratings = model('v2/ratings')
Users   = model('v2/users')
config  = include('../config')

module.exports =
	show: (ctx, res) ->
		names = ctx.params.id.split('|')
		names.sort((a,b) -> a > b)
		ids = []

		for name in names
			user = yield Users.findByName(name)
			ids.push user._id

		query = {ids: {'$nin': ids}}
		if ids.length > 1
			query.type = 'multi'
		else if ctx.params.type?
			query.type = ctx.params.type.toLowerCase()

		if ctx.params.sport?
			query.sport = ctx.params.sport.toLowerCase()

		ratings = yield Ratings.listWithQuery(query)

		if ratings.length == 0
			return res.ok({message: "No valid matchups found!"})

		res.ok({matchups: ratings})
