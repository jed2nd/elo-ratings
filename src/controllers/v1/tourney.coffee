Tourneys = model('v1/tourneys')
Users = model('v1/users')
Ratings = model('v1/ratings')

config = include('../config')

module.exports =
  show: (ctx, res) ->
    { tourneyRecord, tourney } = yield Tourneys.findByField('name', ctx.params.id)
    return res.notFound() unless tourney?

    ratings = []
    for player in tourneyRecord.players
      r = yield Ratings.listWithQuery({_id: player}, {hydrate: true})
      ratings.push r[0]

    matches = tourney.matches.filter((m) -> !m.m?).map (m) ->
      {
        group: m.id.s
        players: m.p.map((p) -> ratings[p-1])
      }

    res.ok({tourneyRecord, tourney, matches})

  create: (ctx, res) ->
    valid = verifyTourneyPayload(ctx.body)
    return res.invalid() unless valid

    tourneyData = ctx.body

    ratings = []
    for player in tourneyData.players
      user = yield Users.findOrCreateByName(player)
      ratings.push yield Ratings.findOrCreate({
        sport: tourneyData.sport
        type: tourneyData.type
        ids: [user._id]
      })

    ratings.sort((a,b) -> a.ladderPos - b.ladderPos)
    tourneyData.players = ratings.map((r) -> r._id)
    { tourneyRecord, tourney } = yield Tourneys.create(tourneyData)
    res.ok({tourneyRecord, tourney})

  update: (ctx, res) ->
    return res.invalid() unless ctx.body.match?

    { tourneyRecord } = yield Tourneys.findByField('name', ctx.params.id)

    return res.notFound() unless tourneyRecord?

    { match } = ctx.body
    winnerUser = yield Users.findOrCreateByName(match.winner)
    loserUser = yield Users.findOrCreateByName(match.loser)
    winnerRating = yield Ratings.findOrCreate({
      sport: ctx.body.sport
      type: ctx.body.type
      ids: [winnerUser._id]
    })
    loserRating = yield Ratings.findOrCreate({
      sport: ctx.body.sport
      type: ctx.body.type
      ids: [loserUser._id]
    })
    players = [ winnerRating._id, loserRating._id ]
    score = [ 1, 0 ]
    tourney = yield Tourneys.recordScore(tourneyRecord, players, score)

    if !tourney
      return res.invalid({match: "invalid"})

    res.ok({tourney})

verifyTourneyPayload = (data) ->
  return false unless data.players?.length > 0
  return false unless data.sport? and data.type?
  return true
