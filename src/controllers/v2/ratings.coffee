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
		key = ids.join('|')

		query = {}
		query.ids = {'$in': ids}

		if ctx.params.sport?
			query.sport = ctx.params.sport.toLowerCase()
		if ctx.params.type?
			query.type = ctx.params.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query)
		if ratings.length == 1
			return res.ok(ratings[0])

		res.ok(ratings)

	list: (ctx, res) ->
		query = {}

		if ctx.params.sport?
			query.sport = ctx.params.sport.toLowerCase()
		if ctx.params.type?
			query.type = ctx.params.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query)
		if ratings.length == 1
			return res.ok(ratings[0])

		res.ok(ratings)
