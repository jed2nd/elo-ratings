empty = Object.freeze({})
class Context
	constructor: (@req, @res) ->
		@body = @req.body || empty

module.exports = Context
