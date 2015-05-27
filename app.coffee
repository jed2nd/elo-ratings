cluster = require 'cluster'
source = if /\.coffee$/.test(process.argv[1]) then './src/' else './lib/'
config = require './config'

return require(source + 'server') if config.development

if cluster.isMaster
	cluster.fork() for i in [1..config.workers]
	cluster.on 'exit', (worker, code, signal) -> cluster.fork() unless code == 0
	process.on 'SIGUSR2', ->
		console.log('reloading')
		old = (w for id, w of cluster.workers)
		cluster.fork() for i in [1..config.workers]
		o.send('shutdown') for i in old
else
	require(source + 'server').then (server) ->
		process.on 'message', (m) ->
			return unless m == 'shutdown'
			server.shutdown = true
			setTimeout ( -> process.exit(0)), 10000
