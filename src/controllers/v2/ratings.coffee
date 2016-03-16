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

		if ctx.req.query.sport?
			query.sport = ctx.req.query.sport.toLowerCase()
		if ctx.req.query.type?
			query.type = ctx.req.query.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query)
		if ratings.length == 1
			return res.ok(ratings[0])

		res.ok(ratings)

	list: (ctx, res) ->
		query = {}

		if ctx.req.query.sport?
			query.sport = ctx.req.query.sport.toLowerCase()
		if ctx.req.query.type?
			query.type = ctx.req.query.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query)
		if ratings.length == 1
			return res.ok(ratings[0])

		res.ok(ratings)
