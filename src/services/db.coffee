util = include('util')
mongodb = require('mongodb')
ObjectID = mongodb.ObjectID
Promise.promisifyAll(mongodb.Collection.prototype)
Promise.promisifyAll(mongodb.Cursor.prototype)

m = module.exports =
	initialize: ->
		connect = Promise.promisify(mongodb.MongoClient.connect)
		options = server: {auto_reconnect: true}
		connect(require('../../config').mongo, options).then (db) ->
			m.db = db
			m.users   = db.collection('users')
			m.matches = db.collection('matches')
			m.ratings = db.collection('ratings')
			m.tourneys = db.collection('tourneys')
			null

mongodb.Collection.prototype.insertOne = (doc) ->
	response = yield this.insertAsync(doc)
	response.ops[0]._id

mongodb.Collection.prototype.updateWithId = (id, doc) ->
  response = yield this.updateAsync({_id: new ObjectID(id)}, {$set: doc})
  return response

mongodb.Collection.prototype.findById = (id) ->
	return null unless ObjectID.isValid(id)
	cursor = yield this.findAsync(_id: new ObjectID(id))
	object = yield cursor.limit(1).nextObjectAsync()
	cursor.close()
	return object

mongodb.Collection.prototype.findByQuery = (query) ->
	return yield this.findOneAsync(query)

mongodb.Collection.prototype.findByField = (field, value) ->
  query = {}
  query[field] = value
  cursor = yield this.findAsync(query)
  object = yield cursor.limit(1).nextObjectAsync()
  cursor.close()
  return object

mongodb.Collection.prototype.toArray = (where) ->
	cursor = yield this.findAsync(where)
	yield cursor.toArrayAsync()
