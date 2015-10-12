path = require 'path'
{TextEditor, TextBuffer} = require 'atom'

LogView = require '../lib/log-view'

describe "LogView", ->
  {logView, testText} = []

  logViewWithText = (text) ->
    buffer = new TextBuffer(text)
    editor = new TextEditor({buffer})
    new LogView(editor)

  beforeEach ->
    testText = '12:34 INFO: 1\n12:34 INFO: 2\n12:34 DEBUG: 3'
    logView = logViewWithText(testText)
    atom.project.setPaths [path.join(__dirname, 'fixtures')]

  describe "view", ->
    it "has basic elements in view", ->
      expect(logView.settings).toBeDefined()
      expect(logView.find('.input-block')).toBeDefined()
      expect(logView.find('.btn-group-level')).toBeDefined()

  describe "filter log text", ->
    it "filters simple text", ->
      expect(logView.textEditor.getText()).toEqual testText
      expect(logView.textEditor.getMarkers()).toHaveLength 1
      expect(logView.markers.text).toHaveLength 0

      logView.performTextFilter /INFO/

      expect(logView.textEditor.getMarkers()).toHaveLength 2
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
      expect(logView.textEditor.getMarkers()).toHaveLength 1
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
