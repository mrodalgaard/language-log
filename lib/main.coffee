{CompositeDisposable} = require 'atom'

LogView = null

module.exports = LanguageLog =
  config:
    showFilterBar:
      type: 'boolean'
      default: true
    tail:
      type: 'boolean'
      default: false
    foldPosition:
      type: 'string'
      default: 'end-of-line'
      description: 'Determine if the fold appears at the end of a filtered line or between two filtered lines.'
      enum: [
        {value: 'end-of-line', description: 'Fold block at the end of filtered lines.'}
        {value: 'between-lines', description: 'Fold block between two filtered lines.'}
      ]
    useMultiLinesLogEntrySupport:
      type: 'boolean'
      title: 'Use multi-lines log entry support (experimental)'
      default: false
      description: """
        Displays the whole log entry after filter instead of only the line even if the log entry has several lines.
        """
    caseInsensitive:
      type: 'boolean'
      default: true
    adjacentLines:
      type: 'integer'
      title: 'Number of lines displayed above and below filter result:'
      default: 0
      minimum: 0

  activate: (state) ->
    @disposables = new CompositeDisposable
    @grammarDisposable = new CompositeDisposable

    @disposables.add atom.workspace.observeActivePaneItem (item) =>
      @itemUpdate(item)
      
    atom.commands.add 'atom-workspace', 'log:toggle-log-panel', => @toggleLogPanel()

  deactivate: ->
    @disposables.dispose()
    @logView?.destroy()
    @removeLogPanel()

  itemUpdate: (item) ->
    @grammarDisposable.dispose()
    return @removeLogPanel() unless item?.observeGrammar

    @grammarDisposable.add item.observeGrammar? (grammar) =>
      @removeLogPanel()
      if grammar.name is 'Log' && atom.config.get 'language-log.showFilterBar'
        @addLogPanel(item)

  addLogPanel: (textEditor) ->
    # Create new log view if opened log differs from previous
    unless @logView?.textEditor is textEditor
      LogView ?= require './log-view'
      @logView?.destroy()
      @logView = new LogView(textEditor)

    @logPanel = atom.workspace.addBottomPanel(item: @logView, className: 'log-panel')

  removeLogPanel: ->
    @logPanel?.destroy()
    @logPanel = null

  toggleLogPanel: ->
    if @logPanel?
      @removeLogPanel()
    else
      @addLogPanel(atom.workspace.getActiveTextEditor())
