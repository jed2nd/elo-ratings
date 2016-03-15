Matches  = model('v2/matches')
Users    = model('v2/users')
Ratings  = model('v2/ratings')
config   = include('../config')

module.exports =
	show: (ctx, res) ->
		match = yield Matches.findById(id)
		return res.notFound() unless match?

		res.ok({match})

	create: (ctx, res) ->
		#valid = verifyMatchesPayload(ctx.body)
		matchData = ctx.body

		#return res.invalid() unless valid
		{wObjs, lObjs} = yield lookupUsers(matchData)

		match = yield Matches.create(matchData)
		multi = match.winners.length > 1
		winnersKey = wObjs.map((p) -> p._id).join('|')
		losersKey  = lObjs.map((p) -> p._id).join('|')

		winnerRating = yield Ratings.findOrCreate({
			sport: match.sport
			type: if multi then 'multi' else 'single'
			key: winnersKey })
		loserRating = yield Ratings.findOrCreate({
			sport: match.sport
			type: if multi then 'multi' else 'single'
			key: losersKey
		})

		if match.type == 'ladder'
			yield updateLadders(winnerRating, loserRating)

		if match.type in [ 'ladder', 'rated' ]
			updateRatings(winnerRating, loserRating)

		winnerRating.wins++
		winnerRating.matches++
		loserRating.matches++

		yield Ratings.update(winnerRating)
		yield Ratings.update(loserRating)

		res.ok({created: true})

lookupUsers = (matchData) ->
	wObjs = []
	lObjs = []
	for n in matchData.winners
		wObjs.push yield Users.findOrCreateByName(n)
	for n in matchData.losers
		lObjs.push yield Users.findOrCreateByName(n)

	return {wObjs, lObjs}

updateLadders = (winnerRating, loserRating) ->
	return if winnerRating.ladderPos < loserRating.ladderPos

	query = {
		sport: winnerRating.sport
		type:  winnerRating.type
	}

	allRatings = yield Ratings.listWithQuery(query)
	toSlide = allRatings.filter((r) -> r.ladderPos < winnerRating.ladderPos && r.ladderPos > loserRating.ladderPos)

	for r in toSlide
		r.ladderPos = r.ladderPos + 1
		resp = yield Ratings.update(r)

	winnerNewPos = loserRating.ladderPos
	loserRating.ladderPos = loserRating.ladderPos+1
	winnerRating.ladderPos = winnerNewPos
	yield Ratings.update(winnerRating)
	yield Ratings.update(loserRating)

updateRatings = (winnerRating, loserRating) ->
	wStartRating = winnerRating.rating
	lStartRating = loserRating.rating

	wAdv = wStartRating - lStartRating

	wExp = 1 / (Math.pow(10, ((0-wAdv) / 400)) + 1)
	lExp = 1 / (Math.pow(10, ((0+wAdv) / 400)) + 1)

	thisK = config.kVal
	winDiff = Math.abs(winnerRating.wins - loserRating.wins)

	if winDiff == 2
		thisK *= 1.25
	else if winDiff == 3
		thisK *= 1.5
	else if winDiff > 3
		frac = 0.5 + (winDiff - 3) / 8
		thisK *= (1+frac)

	winnerRating.rating = wStartRating + (thisK * (1 - wExp))
	loserRating.rating  = lStartRating + (thisK * (0 - lExp))
