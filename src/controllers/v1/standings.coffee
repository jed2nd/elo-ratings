Ratings = model('v1/ratings')
Matches = model('v1/matches')
Users   = model('v1/users')
config  = include('../config')

module.exports =
	show: (ctx, res) ->
		id = ctx.params.id.toLowerCase()
		return res.invalid() unless id?

		query = {sport: id}
		query.retired = {'$exists': false}

		if ctx.req.query.type?
			query.type = ctx.req.query.type.toLowerCase()

		ratings = yield Ratings.listWithQuery(query, {hydrate: true})
		
		for r in ratings
			winsQuery = {
				winners: r.players.map((p) -> p.name).sort((a,b) -> a > b)
			}
			wins = yield Matches.listWithQuery(winsQuery)
			wins.sort((a,b) -> b.eloGain - a.eloGain)
			r.bestWin = wins[0] || {}

		if ctx.req.query.type?
			return res.ok(ratings)

		ret = {}

		console.log(ratings)
		for r in ratings
			ret[r.type] ?= []
			ret[r.type].push r

		for type, arr of ret
			ret[type] = ret[type].sort((a,b) -> a.ladderPos > b.ladderPos)
		res.ok(ret)
