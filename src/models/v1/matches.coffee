db = service('db')
path = require('path')
util = include('util')

module.exports =
  create: (data) ->
    doc = {
      sport: data.sport.toLowerCase()
      type:  data.type.toLowerCase()
      winners: data.winners
      losers:  data.losers
      createdAt: data.createdAt || util.now()
      ladderGain: data.ladderGain
      eloGain: data.eloGain
    }

    id = yield db.matches.insertOne(doc)
    return yield db.matches.findById(id)

  findById: (id) ->
    return yield db.matches.findById(id)

  listAll: () ->
    return yield db.matches.toArray({})

  listWithQuery: (query, opts) ->
    return yield db.matches.toArray(query)

  update: (updatedDoc) ->
    id = updatedDoc._id
    toSet = {}
    for k, v of updatedDoc when k not in ['_id', 'createdAt']
      toSet[k] = v
    response = yield db.matches.updateWithId(id, toSet)
    return response
