module.exports =
	error: (message, error) ->
		console.log(message, error)
		if error.stack?
			message += "\t" + error.stack
		else if error instanceof Object
			message += "\t" + JSON.stringify(error)
		else
			message += "\t" + error
		console.log(new Date().toUTCString() + " - " + message)
		null
