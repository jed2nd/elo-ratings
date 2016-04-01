db = service('db')
path = require('path')
util = include('util')

module.exports =
  create: (context, data) ->
    doc = {
      p1Id: data.p1Id
      p2Id: data.p2Id
      p1Wins: data.p1Wins
      p2Wins: data.p2Wins
      p1RatingBefore: data.p1RatingBefore
      p2RatingBefore: data.p2RatingBefore
      p1RatingAfter: data.p1RatingAfter
      p2RatingAfter: data.p2RatingAfter
      type: data.type
      createdAt: util.now()
    }

    id = yield db.matches.insertOne(doc)
    return id

  findById: (id) ->
    yield db.matches.findById(id)

  listAll: () ->
    yield db.matches.toArray({})

  update: (updatedDoc) ->
    id = updatedDoc._id
    toSet = {}
    for k, v of updatedDoc when k not in ['_id', 'createdAt']
      toSet[k] = v
    response = yield db.matches.updateWithId(id, toSet)
    return response
