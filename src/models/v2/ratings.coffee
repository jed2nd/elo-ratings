db = service('db')
path = require('path')
util = include('util')

BASE_ELO = 2000

module.exports = Ratings =
  create: (data) ->
    doc = {
      sport: data.sport
      type:  data.type
      key:   data.key
      rating: data.rating
      ladderPos: data.ladderPos
      wins:  data.wins
      matches: data.matches
      createdAt: util.now()
    }

    id = yield db.ratings.insertOne(doc)
    return id

  findOrCreate: (data) ->
    existing = yield db.ratings.findByQuery({sport: data.sport, type: data.type, key: data.key})
    if existing?
      return existing
    else
      console.log "new user rating #{data.key}"
      ladderPos = yield Ratings.getNextLadderPos(data.sport, data.type)
      console.log ladderPos
      createdId = yield Ratings.create({sport: data.sport, type: data.type, key: data.key, rating: BASE_ELO, ladderPos: ladderPos, wins: 0, matches: 0})
      return yield Ratings.findById(createdId)

  findById: (id) ->
    yield db.ratings.findById(id)

  listAll: () ->
    yield db.ratings.toArray({})

  listWithQuery: (query) ->
    yield db.ratings.toArray(query)

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
