db = service('db')
path = require('path')
util = include('util')

Users = model('v1/users')

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
      if existing.reset
        existing.reset = false
        existing.ladderPos = yield Ratings.getNextLadderPos(data.sport, data.type, true)
        yield Ratings.update(existing)
      return existing
    else
      ladderPos = yield Ratings.getNextLadderPos(data.sport, data.type)
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

  getNextLadderPos: (sport, type, overrideRetired = false) ->
    q = { sport, type, reset: false }
    unless overrideRetired
      q.retired = {'$exists': false}
    all = yield Ratings.listWithQuery(q)
    last = all.sort((a,b) -> a.ladderPos > b.ladderPos)[all.length-1]
    return 1 unless last?
    return last.ladderPos + 1

  reset: (doc) ->
    id = doc._id
    toSet = {}
    toSet.rating = BASE_ELO
    toSet.ladderPos = null
    toSet.wins = 0
    toSet.matches = 0
    toSet.reset = true
    return db.ratings.updateWithId(id, toSet)

  retire: (doc) ->
    id = doc._id
    toSlide = yield Ratings.listWithQuery({ sport: doc.sport, type: doc.type, ladderPos: { '$gt': doc.ladderPos }})
    for r in toSlide
      r.ladderPos = r.ladderPos - 1
      yield Ratings.update(r)

    return db.ratings.updateWithId(id, { retired: true })

  update: (updatedDoc) ->
    id = updatedDoc._id
    toSet = {}
    for k, v of updatedDoc when k not in ['_id', 'createdAt']
      toSet[k] = v
    response = yield db.ratings.updateWithId(id, toSet)
    return response
