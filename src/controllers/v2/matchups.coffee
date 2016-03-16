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

		myQuery = {ids: {'$in': ids}}

		query = {ids: {'$nin': ids}}
		if ids.length > 1
			query.type = 'multi'
			myQuery.type = 'multi'
		else if ctx.params.type?
			query.type = ctx.params.type.toLowerCase()
			myQuery.type = ctx.params.type.toLowerCase()

		if ctx.params.sport?
			query.sport = ctx.params.sport.toLowerCase()
			myQuery.sport = ctx.params.sport.toLowerCase()

		ratings = yield Ratings.listWithQuery(query, {hydrate: true})
		myRatings = yield Ratings.listWithQuery(myQuery, {hydrate: true})

		console.log "myr", myRatings
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
