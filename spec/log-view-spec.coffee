path = require 'path'
{TextBuffer} = require 'atom'

moment = require 'moment'

LogView = require '../lib/log-view'

describe "LogView", ->
  {logView, text} = []

  beforeEach ->
    text = "12:34 INFO: 1\n12:34 INFO: 2\n12:34 DEBUG: 3"
    buffer = new TextBuffer(text)
    editor = atom.workspace.buildTextEditor({buffer})
    logView = new LogView(editor)
    atom.project.setPaths [path.join(__dirname, 'fixtures')]

  describe "view", ->
    it "has basic elements in view", ->
      expect(logView.settings).toBeDefined()
      expect(logView.find('.input-block')).toBeDefined()
      expect(logView.find('.btn-group-level')).toBeDefined()

  describe "filter log text", ->
    it "filters simple text", ->
      expect(logView.textEditor.getText()).toEqual text
      expect(logView.textEditor.getMarkers()).toHaveLength 0
      expect(logView.markers.text).toHaveLength 0

      logView.performTextFilter /INFO/

      expect(logView.textEditor.getMarkers()).toHaveLength 1
      expect(logView.markers.text).toHaveLength 1

    it "can filter out no lines", ->
      expect(logView.markers.text).toHaveLength 0
      logView.performTextFilter /XXX/
      expect(logView.markers.text).toHaveLength 3

    it "can filter out all lines", ->
      logView.performTextFilter /12:34/
      expect(logView.markers.text).toHaveLength 0

    it "accepts advanced regex expressions", ->
      logView.performTextFilter /\d{2}:[0-9]{2}\sD/
      expect(logView.markers.text).toHaveLength 2

    it "fetches the currently set filter", ->
      logView.filterBuffer.setText('INFO')
      expect(logView.getFilterRegex()).toEqual /INFO/i

    it "works with advanced regex filters", ->
      logView.filterBuffer.setText('INFO{1}.*')
      expect(logView.getFilterRegex()).toEqual /INFO{1}.*/i

    it "shows error message on invalid regex", ->
      logView.filterBuffer.setText('*INFO')
      expect(atom.notifications.getNotifications()).toHaveLength 0
      expect(logView.getFilterRegex()).toEqual false
      expect(atom.notifications.getNotifications()).toHaveLength 1

  describe "filter log levels", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')
        logView.textEditor.setGrammar(grammar)

    it "filters out specific levels", ->
      logView.levelVerboseButton.click()
      expect(logView.textEditor.getMarkers()).toHaveLength 0
      expect(logView.markers.levels).toHaveLength 0

      logView.levelInfoButton.click()
      expect(logView.markers.levels).toHaveLength 2

      logView.levelDebugButton.click()
      expect(logView.markers.levels).toHaveLength 3

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

  describe "timestamp extraction", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('language-log')
      runs ->
        grammar = atom.grammars.grammarForScopeName('source.log')
        logView.textEditor.setGrammar(grammar)

    it "ignores invalid timestamps", ->
      logView.textEditor.setText("WARNING: this")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 0

      logView.textEditor.setText("1234 WARNING: this")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 0

      logView.textEditor.setText("123.456 WARNING: this")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 0

    it "parses small timestamps", ->
      logView.textEditor.setText("12-13 1:01 WARNING: this")
      time = moment("12/13 01:01:00.000").year(moment().year())
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses android timestamps", ->
      logView.textEditor.setText("11-13 05:51:52.279: I/NDK_DEBUG(1359): C")
      time = moment("11/13 05:51:52.279").year(moment().year())
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses iOS timestamps", ->
      logView.textEditor.setText("[2015-09-17 16:37:57 CEST] <main> INFO")
      time = moment("2015/09/17 16:37:57.000")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses idea timestamps", ->
      logView.textEditor.setText("2014-12-11 14:00:36,047 [ 200232]")
      time = moment("2014/12/11 14:00:36.047")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses apache timestamps", ->
      logView.textEditor.setText("64.242.88.10 - - [07/Mar/2004:16:45:56 -0800] details")
      time = moment("2004/03/07 16:45:56.000")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

      logView.textEditor.setText("[11/Dec/2004:16:24:16] GET /twiki/bin/view/M")
      time = moment("2004/12/11 16:24:16.000")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses nabto timestamps", ->
      logView.textEditor.setText("141121-14:00:26.160 {00007fff7463f300} [AUTOMATLST,debug]")
      time = moment("2014/11/21 14:00:26.160")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses adobe timestamps", ->
      logView.textEditor.setText("04/25/15 14:51:34:414 | [INFO] |  | OOBE | D")
      time = moment("2015/04/25 14:51:34.414")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses facetime timestamps", ->
      logView.textEditor.setText("2015-04-16 14:44:00 +0200 [FaceTimeServiceSe")
      time = moment("2015/04/16 14:44:00.000")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses google timestamps", ->
      logView.textEditor.setText("2015-03-11 21:07:03.094 GoogleSoftwareUpdate")
      time = moment("2015/03/11 21:07:03.094")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses vmware timestamps", ->
      logView.textEditor.setText("2015-04-23T13:58:41.657+01:00| VMware Fusio")
      time = moment("2015/04/23 13:58:41.657")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses auth timestamps", ->
      logView.textEditor.setText("Apr 28 08:46:03 (72.84) AuthenticationAllowe")
      time = moment("04/28 08:46:03.000").year(moment().year())
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses apple timestamps", ->
      logView.textEditor.setText("Oct 21 09:12:33 Random-MacBook-Pro.local sto")
      time = moment("10/21 09:12:33.000").year(moment().year())
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

      logView.textEditor.setText("Mon Dec 30 15:19:10.047 <airportd[78]> _doAu")
      time = moment("12/30 15:19:10.047").year(moment().year())
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses ppp timestamps", ->
      logView.textEditor.setText("Thu Oct  9 11:52:14 2014 : IPSec connection ")
      time = moment("2014/10/09 11:52:14.000")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time

    it "parses windows cbs timestamps", ->
      logView.textEditor.setText("2015-08-14 05:50:12, Info                CBS")
      time = moment("2015/08/14 05:50:12.000")
      logView.performTimestampFilter()
      expect(logView.markers.times).toHaveLength 1
      expect(+logView.markers.times[0]).toBe +time
