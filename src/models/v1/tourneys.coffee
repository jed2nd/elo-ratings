db = service('db')
GroupstageTbDuel = require('groupstage-tb-duel')

createTourneyFromRecord = (tourneyRecord) ->
  tourney = GroupstageTbDuel(tourneyRecord.players.length, tourneyRecord.opts)

  for item in tourneyRecord.state
    if item.type == 'score'
      tourney.score(item.id, item.score)
    if item.type == 'next'
      tourney.stageDone()
      tourney.createNextStage()

  return tourney

module.exports = Tourneys =
  create: (data) ->
    opts =
      groupStage:
        groupSize: data.opts?.groupSize || Math.ceil(data.players.length) / 4
        limit: data.opts?.advance || 8
      duel:
        last: 1 + !!data.opts?.doubleElimination
    tourney = GroupstageTbDuel(data.players.length, opts)
    players = data.players
    
    record = {
      sport: data.sport,
      type: data.type,
      name: data.name,
      players,
      opts,
      state: tourney.state
    }
    id = yield db.tourneys.insertOne(record)
    tourneyRecord = yield db.tourneys.findById(id)
    return { tourneyRecord, tourney }

  findByField: (name, value) ->
    tourneyRecord = yield db.tourneys.findByField(name, value)
    tourney = createTourneyFromRecord(tourneyRecord)

    return { tourneyRecord, tourney }

  findById: (id) ->
    tourneyRecord = yield db.tourneys.findById(id)
    tourney = createTourneyFromRecord(tourneyRecord)

    return { tourneyRecord, tourney }

  recordScore: (tourneyRecord, players, score) ->
    console.log('t', tourneyRecord, players, score)
    tourney = createTourneyFromRecord(tourneyRecord)

    playerIds = players.map (p) ->
      tourneyRecord.players.map((p) -> String(p)).indexOf(String(p)) + 1

    matches = tourney.matches.filter (m) ->
      console.log(m, playerIds)
      for id in playerIds
        if m.p.indexOf(id) == -1
          return false
      return true

    if matches.length == 0
      return null

    match = matches[0]

    console.log(tourney.state)
    tourney.score(match.id, score)
    if tourney.matches.filter((t) -> !t.m?).length == 0
      tourney.stageDone()
      tourney.createNextStage()

    console.log(tourney.state)

    yield db.tourneys.updateWithId(tourneyRecord._id, {state: tourney.state})
    return tourney
