path = require 'path'
{TextEditor, TextBuffer} = require 'atom'

LogView = require '../lib/log-view'

describe "LogView", ->
  beforeEach ->
    atom.project.setPaths [path.join(__dirname, 'fixtures')]

  describe "view", ->
    it "has basic elements in view", ->
      logView = new LogView
      expect(logView.settings).toBeDefined()
      expect(logView.find('.input-block')).toBeDefined()
      expect(logView.find('.btn-group-level')).toBeDefined()

  describe "filter log text", ->
    it "filters simple text", ->
      text = 'INFO: 1 2 3'
      buffer = new TextBuffer(text)
      editor = new TextEditor({buffer})
      logView = new LogView(editor)

      expect(logView.textEditor.getText()).toEqual text
      expect(logView.textEditor.getMarkers()).toHaveLength 1

      # TODO: Do a simple filter command

    # TODO: Test advanced regex text filters

  describe "filter log levels", ->

    # TODO: Test filter level buttons
