module.exports =
  development: true
      # of workers to launch (via node cluster)
  workers: 1
  http:
    host: '127.0.0.1'
    port: 3031
  mongo: 'mongodb://localhost:27017/ratings2?poolSize=1'
  kVal: 30
