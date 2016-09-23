{CompositeDisposable, Point} = require 'atom'
{Emitter} = require 'atom'

moment = require 'moment'
moment.createFromInputFallback = (config) ->
  config._d = new Date(config._i)

module.exports =
class LogFilter
  constructor: (@textEditor) ->
    @disposables = new CompositeDisposable
    @emitter = new Emitter

    @results =
      text: []
      levels: []
      times: []

  onDidFinishFilter: (cb) -> @emitter.on 'did-finish-filter', cb

  destroy: ->
    @disposables.dispose()
    @removeFilter()
    @detach()

  getFilteredLines: (type) ->
    return res if res = @results[type]

    res = [@results.text..., @results.levels...]
    output = {}
    output[res[key]] = res[key] for key in [0...res.length]
    value for key, value of output

  getFilteredCount: ->
    @results.text.length + @results.levels.length

  performTextFilter: (text) ->
    return unless regex = @getRegexFromText(text)
    return unless buffer = @textEditor.getBuffer()

    return unless regex

    @results.text = for line, i in buffer.getLines()
      if regex.test(line) then else i
    @filterLines()

  performLevelFilter: (scopes) ->
    return unless buffer = @textEditor.getBuffer()

    return unless scopes
    grammar = @textEditor.getGrammar()

    @results.levels = for line, i in buffer.getLines()
      tokens = grammar.tokenizeLine(line)
      if @shouldFilterScopes(tokens, scopes) then i else
    @filterLines()

  # XXX: Experimental log line timestamp extraction
  #      Not used in production
  performTimestampFilter: ->
    return unless buffer = @textEditor.getBuffer()

    for line, i in buffer.getLines()
      if timestamp = @getLineTimestamp(i)
        @results.times[i] = timestamp

  filterLines: ->
    lines = @getFilteredLines()

    @removeFilter()

    for line, i in lines
      if lines[i+1] isnt line + 1
        @foldLineRange(start or lines[0], line)
        start = lines[i+1]

    @emitter.emit 'did-finish-filter'

  foldLineRange: (start, end) ->
    return unless start? and end?

    # Atom folds the line under the selected row
    # and the first line doesn't really fold
    @textEditor.setSelectedBufferRange([[start - 1, 0], [end, 0]])
    @textEditor.getSelections()[0].fold()

  shouldFilterScopes: (tokens, filterScopes) ->
    for tag in tokens.tags
      if scope = tokens.registry.scopeForId(tag)
        return true if filterScopes.indexOf(scope) isnt -1
    return false

  getRegexFromText: (text) ->
    try
      regexpPattern = text
      regexpFlags = ''
      if text[0] is '!'
        regexpPattern = "^((?!#{text.substr(1)}).)*$"
      if atom.config.get('language-log.caseInsensitive')
        regexpFlags += 'i'

      if regexpFlags
        return new RegExp(regexpPattern, regexpFlags)
      else
        return new RegExp(regexpPattern)

    catch error
      atom.notifications.addWarning('Log Language', detail: 'Invalid filter regex')
      return false

  removeFilter: ->
    @textEditor.unfoldAll()

  getLineTimestamp: (lineNumber) ->
    for pos in [0..30] by 10
      point = new Point(lineNumber, pos)
      range = @textEditor.displayBuffer.bufferRangeForScopeAtPosition('timestamp', point)
      if range and timestamp = @textEditor.getTextInRange(range)
        return @parseTimestamp(timestamp)

  parseTimestamp: (timestamp) ->
    regexes = [
      /^\d{6}[-\s]/
      /[0-9]{4}:[0-9]{2}/
      /[0-9]T[0-9]/
    ]

    # Remove invalid timestamp characters
    timestamp = timestamp.replace(/[\[\]]?/g, '')
    timestamp = timestamp.replace(/\,/g, '.')
    timestamp = timestamp.replace(/([A-Za-z]*|[-+][0-9]{4}|[-+][0-9]{2}:[0-9]{2})$/, '')

    # Rearrange string to valid timestamp format
    if part = timestamp.match(regexes[0])?[0]
      part = "20#{part.substr(0,2)}-#{part.substr(2,2)}-#{part.substr(4,2)} "
      timestamp = timestamp.replace(regexes[0], part)
    if timestamp.match(regexes[1])
      timestamp = timestamp.replace(':', ' ')
    if index = timestamp.indexOf(regexes[2]) isnt -1
      timestamp[index+1] = ' '

    # Very small matches are often false positive numbers
    return false if timestamp.length < 8

    time = moment(timestamp)
    # Timestamps without year defaults to 2001 - set to current year
    time.year(moment().year()) if time.year() is 2001
    time
