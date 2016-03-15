db = service('db')
path = require('path')
util = include('util')

module.exports =
  create: (context, data) ->
    doc = {
      name: data.name
      createdAt: util.now()
    }
    id = yield db.users.insertOne(doc)
    return id

  update: (updatedDoc) ->
    id = updatedDoc._id
    toSet = {}
    for k, v of updatedDoc when k not in ['_id', 'createdAt']
      toSet[k] = v
    response = yield db.users.updateWithId(id, toSet)
    return response

  findById: (id) ->
    yield db.users.findById(id)

  findByName: (name) ->
    yield db.users.findByField("name", name)

  findOrCreateByName: (name) ->
    user = yield db.users.findByField("name", name)
    return user if user?
    id = yield @create({}, {name: name})
    user = yield @findById(id.toString())
    allUsers = yield @listAll()
    user.ladderPos = allUsers.length
    return user

  listAll: () ->
    yield db.users.toArray({})
