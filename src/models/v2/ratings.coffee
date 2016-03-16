db = service('db')
path = require('path')
util = include('util')

Users = model('v2/users')

BASE_ELO = 2000

module.exports = Ratings =
  create: (data) ->
    doc = {
      sport: data.sport
      type:  data.type
      ids:   data.ids
      rating: data.rating
      ladderPos: data.ladderPos
      wins:  data.wins
      matches: data.matches
      createdAt: util.now()
    }

    id = yield db.ratings.insertOne(doc)
    return id

  findOrCreate: (data) ->
    existing = yield db.ratings.findByQuery({sport: data.sport, type: data.type, ids: data.ids})
    if existing?
      return existing
    else
      console.log "new user rating #{data.ids}"
      ladderPos = yield Ratings.getNextLadderPos(data.sport, data.type)
      console.log ladderPos
      createdId = yield Ratings.create({sport: data.sport, type: data.type, ids: data.ids, rating: BASE_ELO, ladderPos: ladderPos, wins: 0, matches: 0})
      return yield Ratings.findById(createdId)

  findById: (id) ->
    yield db.ratings.findById(id)

  listAll: () ->
    yield db.ratings.toArray({})

  listWithQuery: (query, opts) ->
    ratings = yield db.ratings.toArray(query)
    return ratings unless opts?.hydrate

    for r in ratings
      users = []
      for id in r.ids
        users.push yield Users.findById(id)
      r.players = users

    return ratings

  getNextLadderPos: (sport, type) ->
    all = yield Ratings.listWithQuery({sport, type})
    console.log all.map((r) -> r.ladderPos)
    return all.length + 1

  update: (updatedDoc) ->
    id = updatedDoc._id
    toSet = {}
    for k, v of updatedDoc when k not in ['_id', 'createdAt']
      toSet[k] = v
    response = yield db.ratings.updateWithId(id, toSet)
    return response
