server = require('koa')()
require('./initializers/extensions')(server)
logger = require('./logger')

module.export = require('./initializers')
	.then ->
		config = require('../config')
		Context = include('controllers/context')

		server.use(require('koa-body-parser')())
		server.use((next) -> @._context = new Context(@.request, @.response); yield next)
		server.onerror = (err) -> logger.error('server global', err)
		include('controllers/router')(server)

		server.listen(config.http.port)
		console.log("listening: #{config.http.host}:#{config.http.port}") if config.development
		return server
	.catch (err) -> logger.error('global catch', err)
