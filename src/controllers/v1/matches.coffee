Matches  = model('v1/matches')
Users    = model('v1/users')
Ratings  = model('v1/ratings')
config   = include('../config')

module.exports =
	show: (ctx, res) ->
		match = yield Matches.findById(id)
		return res.notFound() unless match?

		res.ok({match})

	create: (ctx, res) ->
		valid = verifyMatchesPayload(ctx.body)
		matchData = ctx.body

		return res.invalid() unless valid

		match = yield Matches.create(matchData)
		yield addMatch(match)
		res.ok({created: true})

	update: (ctx, res) ->
		return res.invalid() unless ctx.body.recalc

		allMatches = yield Matches.listAll()

		allRatings = yield Ratings.listAll()

		allUsers = yield Users.listAll()

		for r in allRatings
			yield Ratings.reset(r)

		for m in allMatches
			yield addMatch(m)

		for r in allRatings when r.retired
			yield Ratings.retire(r)

		res.ok({done: true})

addMatch = (match) ->
	multi = match.winners.length > 1
	{wObjs, lObjs} = yield lookupUsers(match)
	winnersIds = wObjs.map((p) -> p._id)
	losersIds  = lObjs.map((p) -> p._id)

	winnerRating = yield Ratings.findOrCreate({
		sport: match.sport
		type: if multi then 'multi' else 'single'
		ids: winnersIds })
	loserRating = yield Ratings.findOrCreate({
		sport: match.sport
		type: if multi then 'multi' else 'single'
		ids: losersIds
	})

	if match.type == 'ladder'
		match.ladderGain = yield updateLadders(winnerRating, loserRating)

	if match.type in [ 'ladder', 'rated' ]
		match.eloGain = updateRatings(winnerRating, loserRating)

	winnerRating.wins++
	winnerRating.matches++
	loserRating.matches++

	yield Ratings.update(winnerRating)
	yield Ratings.update(loserRating)
	
	yield Matches.update(match)

verifyMatchesPayload = (data) ->
	return false unless data.winners?.length > 0
	return false unless data.losers?.length > 0

	return false unless data.sport? and data.type?

	return true

lookupUsers = (matchData) ->
	wObjs = []
	lObjs = []
	for n in matchData.winners.sort((a,b) -> a > b)
		wObjs.push yield Users.findOrCreateByName(n)
	for n in matchData.losers.sort((a,b) -> a > b)
		lObjs.push yield Users.findOrCreateByName(n)

	return {wObjs, lObjs}

updateLadders = (winnerRating, loserRating) ->
	return 0 if winnerRating.ladderPos < loserRating.ladderPos

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

	return toSlide.length

updateRatings = (winnerRating, loserRating) ->
	wStartRating = winnerRating.rating
	lStartRating = loserRating.rating

	wAdv = wStartRating - lStartRating

	wExp = 1 / (Math.pow(10, ((0-wAdv) / 400)) + 1)
	lExp = 1 / (Math.pow(10, ((0+wAdv) / 400)) + 1)

	thisK = config.kVal

	winnerRating.rating = wStartRating + (thisK * (1 - wExp))
	loserRating.rating  = lStartRating + (thisK * (0 - lExp))

	return (thisK * (1 - wExp))
