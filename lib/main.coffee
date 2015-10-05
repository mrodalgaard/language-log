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
      if item?.getGrammar?().packageName is 'language-log'
        @addLogPanel(item)

  deactivate: ->
    @disposables.dispose()
    @logView?.destroy()

  addLogPanel: (textEditor) ->
    return unless atom.config.get 'language-log.showFilterBar'

    LogView ?= require './log-view'
    logView = new LogView(textEditor)
    @logPanel = atom.workspace.addBottomPanel(item: logView, className: 'log-panel')

  removeLogPanel: ->
    return unless @logPanel
    @logPanel.getItem()?.destroy()
    @logPanel.destroy()
