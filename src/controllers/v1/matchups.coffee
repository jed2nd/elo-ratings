Ratings = model('v1/ratings')
Users   = model('v1/users')
config  = include('../config')

module.exports =
	show: (ctx, res) ->
		names = ctx.params.id.split('|')
		names.sort((a,b) -> a > b)
		ids = []

		for name in names
			user = yield Users.findByName(name)
			ids.push user._id

		myQuery = {ids: {'$in': ids}}

		query = {ids: {'$nin': ids}}
		if ids.length > 1
			query.type = 'multi'
			myQuery.type = 'multi'
		else if ctx.req.query.type?
			query.type = ctx.req.query.type.toLowerCase()
			myQuery.type = ctx.req.query.type.toLowerCase()

		if ctx.req.query.sport?
			query.sport = ctx.req.query.sport.toLowerCase()
			myQuery.sport = ctx.req.query.sport.toLowerCase()

		ratings = yield Ratings.listWithQuery(query, {hydrate: true})
		myRatings = yield Ratings.listWithQuery(myQuery, {hydrate: true})

		ret = {}
		for r in myRatings
			matching = ratings.filter((s) -> s.sport == r.sport && s.type == r.type)
			ret[r.sport] ?= {}
			ret[r.sport][r.type] ?= {}
			ret[r.sport][r.type].all ?= matching
			ret[r.sport][r.type].mine ?= []

			best = matching.sort((a,b) -> Math.abs(a.rating - r.rating) - Math.abs(b.rating - r.rating))[0]

			ret[r.sport][r.type].mine.push {me: r, best: best}

		if ratings.length == 0
			return res.ok({message: "No valid matchups found!"})

		res.ok({matchups: ret})
