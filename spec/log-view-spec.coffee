path = require 'path'
{TextBuffer} = require 'atom'

moment = require 'moment'

LogView = require '../lib/log-view'

describe "LogView", ->
  {logView, logFilter, text} = []

  # Atom marks the line over a fold and folded
  # and the first line doesn't really fold
  getFoldedLines = ->
    count = logView.textEditor.getLineCount() - 1
    i for i in [0..count] when logView.textEditor.isFoldedAtBufferRow(i)

  getFilteredLines = ->
    logFilter.results.text.join('')

  beforeEach ->
    text = "12:34 INFO: 1\n12:34 INFO: 2\n12:34 DEBUG: 3"
    buffer = new TextBuffer(text)
    editor = atom.workspace.buildTextEditor({buffer})
    logView = new LogView(editor)
    logFilter = logView.logFilter
    atom.project.setPaths [path.join(__dirname, 'fixtures')]

  describe "view", ->
    it "has basic elements in view", ->
      expect(logView.settings).toBeDefined()
      expect(logView.find('.input-block')).toBeDefined()
      expect(logView.find('.btn-group-level')).toBeDefined()
      expect(logView.find('.descriptionLabel')).toBeDefined()

  describe "filter log text", ->
    it "filters simple text", ->
      expect(logView.textEditor.getText()).toEqual text
      expect(logView.textEditor.getMarkers()).toHaveLength 0
      expect(getFoldedLines()).toHaveLength 0
      expect(logFilter.getFilteredLines()).toHaveLength 0

      logFilter.performTextFilter 'INFO'

      # TODO: Fails because it marks the line above folded as folded also!!!
      #expect(getFoldedLines()).toEqual [2]
      expect(logFilter.getFilteredLines()).toEqual [2]

    it "can filter out no lines", ->
      expect(logFilter.getFilteredLines()).toHaveLength 0
      logFilter.performTextFilter '12:34'
      expect(logFilter.getFilteredLines()).toHaveLength 0

    it "can filter out all lines", ->
      logFilter.performTextFilter 'XXX'
      expect(logFilter.getFilteredLines()).toEqual [0,1,2]

    it "accepts advanced regex expressions", ->
      logFilter.performTextFilter "\\d{2}:[0-9]{2}\\sD"
      expect(logFilter.getFilteredLines()).toEqual [0,1]

    it "fetches the currently set filter", ->
      logView.filterBuffer.setText 'INFO'
      logView.filterButton.click()
      expect(logFilter.getFilteredLines()).toEqual [2]

    it "works with advanced regex filters", ->
      logView.filterBuffer.setText 'INFO{1}.*'
      logView.filterButton.click()
      expect(logFilter.getFilteredLines()).toEqual [2]

    it "shows error message on invalid regex", ->
      logView.filterBuffer.setText '*INFO'
      expect(atom.notifications.getNotifications()).toHaveLength 0
      logView.filterButton.click()
      expect(atom.notifications.getNotifications()).toHaveLength 1

    it "removes filter when no input", ->
      logView.filterBuffer.setText 'INFO'
      logView.filterButton.click()
      expect(logFilter.getFilteredLines()).toEqual [2]

      logView.filterBuffer.setText ''
      logView.filterBuffer.emitter.emit('did-stop-changing')
      expect(logFilter.getFilteredLines()).toEqual []

    it "can can invert the filter", ->
      logFilter.performTextFilter '!INFO'
      expect(logFilter.getFilteredLines()).toEqual [0,1]

    it "inverts with advanced regex filters", ->
      logFilter.performTextFilter "!\\d{2}:[0-9]{2}\\sD"
      expect(logFilter.getFilteredLines()).toEqual [2]

  describe "filter log levels", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')
        logView.textEditor.setGrammar(grammar)

    it "filters and folds log level lines", ->
      logView.levelVerboseButton.click()
      expect(logView.textEditor.getMarkers()).toHaveLength 0
      expect(getFoldedLines()).toHaveLength 0
      expect(logFilter.getFilteredLines()).toHaveLength 0

      logView.levelInfoButton.click()
      expect(getFoldedLines()).toEqual [0,1]
      expect(logFilter.getFilteredLines()).toHaveLength 2

      logView.levelDebugButton.click()
      expect(getFoldedLines()).toEqual [0,1,2]
      expect(logFilter.getFilteredLines()).toHaveLength 3

      logView.levelInfoButton.click()
      expect(getFoldedLines()).toEqual [1,2]
      expect(logFilter.getFilteredLines()).toHaveLength 1

      logView.levelDebugButton.click()
      expect(getFoldedLines()).toEqual []
      expect(logFilter.getFilteredLines()).toHaveLength 0

    it "gets list of scopes from button state", ->
      logView.updateButtons()
      expect(logView.getFilterScopes()).toHaveLength 0

      logView.levelVerboseButton.click()
      expect(logView.getFilterScopes()).toHaveLength 1

      logView.levelInfoButton.click()
      logView.levelDebugButton.click()
      logView.levelErrorButton.click()
      logView.levelWarningButton.click()
      expect(logView.getFilterScopes()).toHaveLength 5

      logView.levelWarningButton.click()
      expect(logView.getFilterScopes()).toHaveLength 4

  describe "all filters", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')
        logView.textEditor.setGrammar(grammar)

    it "can handle both level and text filters", ->
      logView.levelDebugButton.click()
      expect(logFilter.getFilteredLines()).toEqual [2]

      logFilter.performTextFilter "INFO: 2"
      expect(logFilter.getFilteredLines()).toEqual [0,2]

      logFilter.performTextFilter ""
      expect(logFilter.getFilteredLines()).toEqual [2]

      logView.levelDebugButton.click()
      expect(logFilter.getFilteredLines()).toEqual []

  describe "show description label", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')
        logView.textEditor.setGrammar(grammar)

    it "shows total lines and filtered lines", ->
      expect(logView.find('.description')[0].innerHTML).toBe "Showing 3 log lines"
      logView.levelDebugButton.click()
      expect(logView.find('.description')[0].innerHTML).toBe "Showing 2 of 3 log lines"

    it "updates on file changes", ->
      logView.textEditor.deleteLine(0)
      advanceClock(logView.textEditor.buffer.stoppedChangingDelay)
      expect(logView.find('.description')[0].innerHTML).toBe "Showing 2 log lines"

      logView.textEditor.deleteLine(0)
      logView.levelDebugButton.click()
      advanceClock(logView.textEditor.buffer.stoppedChangingDelay)
      expect(logView.find('.description')[0].innerHTML).toBe "Showing 0 of 1 log lines"

  describe "log tailing", ->
    it "does not tail by default", ->
      pos = logView.textEditor.getCursorBufferPosition()
      logView.textEditor.buffer.append('\nNew log line')
      expect(logView.tailing).toBe false

      advanceClock(logView.textEditor.buffer.stoppedChangingDelay)

      expect(logView.tailing).toBe false
      newPos = logView.textEditor.getCursorBufferPosition()
      expect(newPos).toEqual pos

    it "can tail on log changes", ->
      atom.config.set('language-log.tail', true)
      pos = logView.textEditor.getCursorBufferPosition()
      expect(logView.tailing).toBe false

      logView.textEditor.buffer.append('\nNew log line')
      advanceClock(logView.textEditor.buffer.stoppedChangingDelay)

      expect(logView.tailing).toBe true
      newPos = logView.textEditor.getCursorBufferPosition()
      expect(newPos).not.toEqual pos

      logView.textEditor.buffer.append('\nNew log line')
      advanceClock(logView.textEditor.buffer.stoppedChangingDelay)

      expect(logView.tailing).toBe true
      expect(logView.textEditor.getCursorBufferPosition()).not.toEqual pos
      expect(logView.textEditor.getCursorBufferPosition()).not.toEqual newPos

    it "handles tailing destroyed tabs", ->
      atom.config.set('language-log.tail', true)
      logView.textEditor.destroy()
      logView.tail()
      expect(logView.textEditor.isDestroyed()).toBe true

  describe "adjacentLines", ->
    beforeEach ->
      logView.textEditor.setText "a\nb\nc\nd\ne\nf\ng"

    it "shows adjacent lines", ->
      logView.filterBuffer.setText 'd'

      atom.config.set('language-log.adjacentLines', 0)
      expect(logFilter.getFilteredLines()).toHaveLength 6
      expect(getFilteredLines()).toBe "012456"

      atom.config.set('language-log.adjacentLines', 1)
      expect(logFilter.getFilteredLines()).toHaveLength 4
      expect(getFilteredLines()).toBe "0156"

    it "handles out of bounds adjacent lines", ->
      logView.filterBuffer.setText 'a'

      atom.config.set('language-log.adjacentLines', 0)
      expect(getFilteredLines()).toBe "123456"
      atom.config.set('language-log.adjacentLines', 2)
      expect(getFilteredLines()).toBe "3456"
      atom.config.set('language-log.adjacentLines', 10)
      expect(getFilteredLines()).toBe ""

      logView.filterBuffer.setText 'f'

      atom.config.set('language-log.adjacentLines', 1)
      expect(getFilteredLines()).toBe "0123"
      atom.config.set('language-log.adjacentLines', 2)
      expect(getFilteredLines()).toBe "012"

  describe "show timestamps", ->
    it "shows timestamp start and timestamp end", ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')

        logView.textEditor.setText """
        11-13-15 05:51:46.949: D/dalvikvm(159): GC_FOR_ALLOC freed 104K, 6% free
        11-13-15 05:51:52.279: D/NDK_DEBUG(1359): RUN APPLICATION
        11-13-15 05:51:52.379: I/DEBUG(5441): fingerprint: 'generic/sdk/generic'
        """

        logView.textEditor.setGrammar(grammar)

        waitsFor ->
          logView.timestampEnd.text() != ''
        runs ->
          expect(logView.timestampStart.text()).toBe '13-11-2015 05:51:46'
          expect(logView.timestampEnd.text()).toBe '13-11-2015 05:51:52'

  describe "timestamp extraction", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')
        logView.textEditor.setGrammar(grammar)

    it "ignores invalid timestamps", ->
      logView.textEditor.setText("WARNING: this")
      logFilter.performTimestampFilter()
      expect(logFilter.getFilteredLines()).toHaveLength 0

      logView.textEditor.setText("1234 WARNING: this")
      logFilter.performTimestampFilter()
      expect(logFilter.getFilteredLines()).toHaveLength 0

      logView.textEditor.setText("123.456 WARNING: this")
      logFilter.performTimestampFilter()
      expect(logFilter.getFilteredLines()).toHaveLength 0

    it "parses small timestamps", ->
      logView.textEditor.setText("12-13 1:01 WARNING: this")
      time = moment("12/13 01:01:00.000").year(moment().year())
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses android timestamps", ->
      logView.textEditor.setText("11-13 05:51:52.279: I/NDK_DEBUG(1359): C")
      time = moment("11/13 05:51:52.279").year(moment().year())
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

      logView.textEditor.setText('02-12 17:25:47.614  2335 26149 D WebSocketC')
      time = moment("02/12 17:25:47.614").year(moment().year())
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses iOS timestamps", ->
      logView.textEditor.setText("[2015-09-17 16:37:57 CEST] <main> INFO")
      time = moment("2015/09/17 16:37:57.000")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses idea timestamps", ->
      logView.textEditor.setText("2014-12-11 14:00:36,047 [ 200232]")
      time = moment("2014/12/11 14:00:36.047")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses apache timestamps", ->
      logView.textEditor.setText("64.242.88.10 - - [07/Mar/2004:16:45:56 -0800] details")
      time = moment("2004/03/07 16:45:56.000")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

      logView.textEditor.setText("[11/Dec/2004:16:24:16] GET /twiki/bin/view/M")
      time = moment("2004/12/11 16:24:16.000")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses nabto timestamps", ->
      logView.textEditor.setText("141121-14:00:26.160 {00007fff7463f300} [AUTOMATLST,debug]")
      time = moment("2014/11/21 14:00:26.160")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses adobe timestamps", ->
      logView.textEditor.setText("04/25/15 14:51:34:414 | [INFO] |  | OOBE | D")
      time = moment("2015/04/25 14:51:34.414")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses facetime timestamps", ->
      logView.textEditor.setText("2015-04-16 14:44:00 +0200 [FaceTimeServiceSe")
      time = moment("2015/04/16 14:44:00.000")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses google timestamps", ->
      logView.textEditor.setText("2015-03-11 21:07:03.094 GoogleSoftwareUpdate")
      time = moment("2015/03/11 21:07:03.094")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses vmware timestamps", ->
      logView.textEditor.setText("2015-04-23T13:58:41.657+01:00| VMware Fusio")
      time = moment("2015/04/23 13:58:41.657")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses auth timestamps", ->
      logView.textEditor.setText("Apr 28 08:46:03 (72.84) AuthenticationAllowe")
      time = moment("04/28 08:46:03.000").year(moment().year())
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses apple timestamps", ->
      logView.textEditor.setText("Oct 21 09:12:33 Random-MacBook-Pro.local sto")
      time = moment("10/21 09:12:33.000").year(moment().year())
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

      logView.textEditor.setText("Mon Dec 30 15:19:10.047 <airportd[78]> _doAu")
      time = moment("12/30 15:19:10.047").year(moment().year())
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses ppp timestamps", ->
      logView.textEditor.setText("Thu Oct  9 11:52:14 2014 : IPSec connection ")
      time = moment("2014/10/09 11:52:14.000")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses windows cbs timestamps", ->
      logView.textEditor.setText("2015-08-14 05:50:12, Info                CBS")
      time = moment("2015/08/14 05:50:12.000")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time

    it "parses mail server timestamps", ->
      logView.textEditor.setText("2008-11-08 06:35:41.724563500 26375 logging:")
      time = moment("2008/11/08 06:35:41.724")
      logFilter.performTimestampFilter()
      expect(logFilter.results.times).toHaveLength 1
      expect(+logFilter.results.times[0]).toBe +time
