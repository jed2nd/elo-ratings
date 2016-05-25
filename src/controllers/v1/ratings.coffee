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
		key = ids.join('|')

		query = {}
		query.ids = {'$in': ids}
		query.retired = {'$exists': false}

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
		query.retired = {'$exists': false}

		if ctx.req.query.sport?
			query.sport = ctx.req.query.sport.toLowerCase()
		if ctx.req.query.type?
			query.type = ctx.req.query.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query)
		if ratings.length == 1
			return res.ok(ratings[0])

		res.ok(ratings)

	update: (ctx, res) ->
		query = {}

		if ctx.req.query.sport?
			query.sport = ctx.query.sport.toLowerCase()
		else
			res.invalid({sport: 'required'})

		if ctx.req.query.type?
			query.type = ctx.query.type.toLowerCase()
		else
			res.invalid({type: 'required'})

		allRatings = yield Ratings.listWithQuery(query)

		names = ctx.params.id.split('|')
		names.sort((a,b) -> a > b)
		ids = []

		for name in names
			user = yield Users.findByName(name)
			ids.push user._id
		
		query.ids = {'$in': ids}

		myRatings = yield Ratings.listWithQuery(query)
		if myRatings.length != 1
			return res.invalid('ambiguous query')
		myRating = myRatings[0]
		if(myRating.retired)
			return res.ok({done: false})
		console.log(myRating)

		toSlide = allRatings.filter((r) -> r.ladderPos > myRating.ladderPos)
		console.log(toSlide)

		for r in toSlide
			r.ladderPos = r.ladderPos - 1
			yield Ratings.update(r)

		myRating.retired = true
		yield Ratings.update(myRating)

		res.ok({done: true})
