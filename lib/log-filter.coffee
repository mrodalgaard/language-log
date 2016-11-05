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
      linesWithTimestamp: []

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

    if atom.config.get('language-log.useMultiLinesLogEntrySupport')
      # We build a list of log entries, instead of lines,
      # to be able to parse an entry at once and as a whole
      logEntriesArray = []
      # To stick to the original way the folding is done,
      # because now we are working with several lines at a time,
      # we need to fill for each recognized log entry a list of lines instead of a single one.
      linesIndexes = []
      @performLinesWithTimestampFilter()
      for line, i in @results.linesWithTimestamp
        start = line
        end = line
        if i + 1 < @results.linesWithTimestamp.length
          start = line
          end = @results.linesWithTimestamp[i+1]-1
        logEntriesArray.push(buffer.getTextInRange([[start, 0], [end, @textEditor.getBuffer().lineLengthForRow(end)]]))
        indexesForLines = []
        for lineNumber in [start..end]
          indexesForLines.push(lineNumber)
        linesIndexes.push(indexesForLines)
      lineToDisplayIndexes = []
      for logLine, i in logEntriesArray
        if regex.test(logLine) then else lineToDisplayIndexes = lineToDisplayIndexes.concat(linesIndexes[i])
      @results.text = lineToDisplayIndexes
    else
      @results.text = for line, i in buffer.getLines()
        if regex.test(line) then else i

    @results.text = @addAdjacentLines(@results.text)
    @filterLines()

  addAdjacentLines: (textResults) ->
    if adjLines = atom.config.get('language-log.adjacentLines')
      total = @textEditor.getLineCount()
      temp = []

      for lineNumber, lineIndex in textResults
        if (lineIndex + adjLines < textResults.length and lineNumber + adjLines >= textResults[lineIndex + adjLines]) or
           (lineIndex + adjLines >= textResults.length and (textResults.length - lineIndex) - (total - lineNumber) == 0)
          temp.push lineNumber

      textResults = temp.reverse()
      temp = []

      for lineNumber, lineIndex in textResults
        if (lineIndex + adjLines < textResults.length and lineNumber - adjLines <= textResults[lineIndex + adjLines]) or
           (lineIndex + adjLines >= textResults.length and 0 == (textResults.length - lineIndex) - (lineNumber + 1))
          temp.push lineNumber

      return temp.reverse()
    textResults

  performLevelFilter: (scopes) ->
    return unless buffer = @textEditor.getBuffer()

    return unless scopes
    grammar = @textEditor.getGrammar()

    @results.levels = for line, i in buffer.getLines()
      tokens = grammar.tokenizeLine(line)
      if @shouldFilterScopes(tokens, scopes) then i else
    @filterLines()

  # XXX: Based on experimental code for log line timestamp extraction
  performLinesWithTimestampFilter: ->
    return unless buffer = @textEditor.getBuffer()

    @results.linesWithTimestamp = for line, i in buffer.getLines()
      if !timestamp = @getLineTimestamp(i) then else i

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

    # By default,as fallback case, we keep the safest possibility,
    # the fold start at the first character of the first line to fold
    actualStartLine = start
    actualStartColumn = 0
    foldPositionConfig = atom.config.get('language-log.foldPosition')
    if 'end-of-line' == foldPositionConfig
      # We fold at the end of the last filtered line
      # except if the first line to fold is the first line in the text editor
      actualStartLine = start-1
      actualStartColumn = 0
      if actualStartLine <= 0
        actualStartLine = 0
        actualStartColumn = 0
      else
        actualStartColumn = @textEditor.getBuffer().lineLengthForRow(actualStartLine)
    else if 'between-lines' == foldPositionConfig
      # The fold start at the first character of the first line to fold
      actualStartLine = start
      actualStartColumn = 0

    # We fold until the end of the last line to fold
    start = [actualStartLine, actualStartColumn]
    end = [end, @textEditor.getBuffer().lineLengthForRow(end)]
    @textEditor.setSelectedBufferRange([start, end])
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
      # DEPRECATED
      # range = @textEditor.displayBuffer.bufferRangeForScopeAtPosition('timestamp', point)
      # REPLACEMENT
      @textEditor.setCursorBufferPosition(point)
      range = @textEditor.bufferRangeForScopeAtCursor('timestamp')

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
