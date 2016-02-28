path = require 'path'
fs = require 'fs'
log = require('loglevel').getLogger('ensime.startup')
chokidar = require 'chokidar'
Client = require './client'

# Start an ensime client given path to .ensime. If server already running, just use, else startup that too.
module.exports = startClient = (startEnsimeServer) -> (parsedDotEnsime, generalHandler, callback) ->
  removeTrailingNewline = (str) -> str.replace(/^\s+|\s+$/g, '')
  
  portFilePath = parsedDotEnsime.cacheDir + path.sep + "port"
  httpPortFilePath = parsedDotEnsime.cacheDir + path.sep + "http"

  if fs.existsSync(portFilePath) && fs.existsSync(httpPortFilePath)
    # server running, no need to start
    port = fs.readFileSync(portFilePath).toString()
    httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
    callback(new Client(port, httpPort, generalHandler))
  else
    serverPid = undefined

    whenAllAdded = (files, f) ->
      log.trace('starting watching for: '+files)
      file = files.pop() # NB: mutates files
      watcher = chokidar.watch(file, {
        persistent: true
      }).on('add', (path) ->
        log.trace 'Seen: ', path
        watcher.close()
        if 0 == files.length
          log.trace('All files seen. Starting client')
          f()
        else
          whenAllAdded(files, f)
      )

    whenAllAdded([portFilePath, httpPortFilePath], () ->
      atom?.notifications.addSuccess("Ensime server started!") # quickfix :)
      port = fs.readFileSync(portFilePath).toString()
      httpPort = removeTrailingNewline(fs.readFileSync(httpPortFilePath).toString())
      callback(new Client(port, httpPort, generalHandler, serverPid))
    )

    # no server running, start that first
    startEnsimeServer(parsedDotEnsime, (pid) -> serverPid = pid)
