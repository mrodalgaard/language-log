{CompositeDisposable} = require 'atom'

LogView = null

module.exports = LanguageLog =
  config:
    showFilterBar:
      type: 'boolean'
      default: true

  activate: (state) ->
    @disposables = new CompositeDisposable
    @disposables.add atom.workspace.observeActivePaneItem (item) =>
      @removeLogPanel()
      if item?.getGrammar?()?.packageName is 'language-log'
        @addLogPanel(item)

  deactivate: ->
    @disposables.dispose()
    @logView?.destroy()
    @removeLogPanel()

  addLogPanel: (textEditor) ->
    return unless atom.config.get 'language-log.showFilterBar'

    # Create new log view if opened log differs from previous
    unless @logView?.textEditor is textEditor
      LogView ?= require './log-view'
      @logView?.destroy()
      @logView = new LogView(textEditor)
      textEditor.onDidChangeGrammar (grammar) =>
        if grammar.name is 'Log' then @addLogPanel(textEditor) else @removeLogPanel()

    @logPanel = atom.workspace.addBottomPanel(item: @logView, className: 'log-panel')

  removeLogPanel: ->
    @logPanel?.destroy()
