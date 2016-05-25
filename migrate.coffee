Promise = require 'bluebird'
mongodb = require('mongodb')
ObjectID = mongodb.ObjectID
Promise.promisifyAll(mongodb.Collection.prototype)
Promise.promisifyAll(mongodb.Cursor.prototype)
connect = Promise.promisify(mongodb.MongoClient.connect)
rp = require 'request-promise'
co = require 'co'

options = server: {auto_reconnect: true}

co ->
  oldDB = yield connect('mongodb://localhost:27017/ratings?poolSize=1', options)
  newDB = yield connect('mongodb://localhost:27017/ratings2?poolSize=1', options)
  users = yield oldDB.collection('users').find().toArray()
  matches = yield oldDB.collection('matches').find().toArray()
  console.log matches.length
  for m in matches
    p1 = users.filter((u) -> String(u._id) == String(m.p1Id))[0]
    p2 = users.filter((u) -> String(u._id) == String(m.p2Id))[0]
    newMatchData = {
      sport: "foos"
      type: m.type || 'ladder'
      winners: [ p1.name ]
      losers:  [ p2.name ]
    }
    console.log newMatchData
    resp = yield rp(method: 'POST', uri: 'http://localhost:3031/v1/matches', body: newMatchData, json:true).catch (e) -> console.log e, JSON.stringify(newMatchData)
    console.log resp
