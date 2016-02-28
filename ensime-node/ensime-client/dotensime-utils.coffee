fs = require ('fs')
lisp = require ('./lisp/lisp')
{sexpToJObject} = require './lisp/swank-extras'
_ = require 'lodash'

readDotEnsime = (path) ->
  raw = fs.readFileSync(path)
  rows = raw.toString().split(/\r?\n/)
  filtered = rows.filter (l) -> l.indexOf(';;') != 0
  filtered.join('\n')

parseDotEnsime = (path) ->
  # scala version from .ensime config file of project
  dotEnsime = readDotEnsime(path)
  dotEnsimeLisp = lisp.readFromString(dotEnsime)
  dotEnsimeJs = sexpToJObject(dotEnsimeLisp)
  subprojects = dotEnsimeJs[':subprojects']
  sourceRoots = _.flattenDeep(_.map(subprojects, (sp) -> sp[':source-roots']))
  
  {
    name: dotEnsimeJs[':name']
    scalaVersion: dotEnsimeJs[':scala-version']
    javaHome: dotEnsimeJs[':java-home']
    javaFlags: dotEnsimeJs[':java-flags']
    rootDir: dotEnsimeJs[':root-dir']
    cacheDir: dotEnsimeJs[':cache-dir']
    dotEnsimePath: path
    sourceRoots: sourceRoots
  }

dotEnsimesFilter = (path, stats) ->
  !stats.isDirectory() && ! path.endsWith('.ensime')

module.exports = {
  parseDotEnsime
  dotEnsimesFilter
}
