GLOBAL.Promise = require('bluebird')
GLOBAL.include = (name) -> require('../' + name)
GLOBAL.service = (name) -> require('../services/' + name)
GLOBAL.model   = (name) -> require('../models/' + name)

config = require('../../config')
module.exports =
	Promise.all [
		service('db').initialize()
	]
