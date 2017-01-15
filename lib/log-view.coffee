{View, TextEditorView} = require 'atom-space-pen-views'
{CompositeDisposable, TextBuffer, Point} = require 'atom'

LogFilter = require './log-filter'

deprecatedTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor = require('atom').TextEditor
    new TextEditor(params)

module.exports =
class LogView extends View
  @content: (filterBuffer) ->
    filterEditor = deprecatedTextEditor(
      mini: true
      tabLength: 2
      softTabs: true
      softWrapped: false
      buffer: filterBuffer
      placeholderText: 'Filter in current buffer'
    )

    @div tabIndex: -1, class: 'log-view', =>
      @header class: 'header', =>
        @span 'Log Filter'
        @span class: 'pull-right', 'Level Filters'
        @span outlet: 'descriptionLabel', class: 'description'
        @span outlet: 'descriptionWarningLabel', class: 'description warning'

      @section class: 'input-block', =>
        @div class: 'input-block-item input-block-item--flex editor-container', =>
          @subview 'filterEditorView', new TextEditorView(editor: filterEditor)

        @div class: 'input-block-item', =>
          @div class: 'btn-group', =>
            @button outlet: 'filterButton', class: 'btn', 'Filter'
          @div class: 'btn-group', =>
            @button outlet: 'tailButton', class: 'btn btn-icon icon-arrow-down'
          @div class: 'btn-group', =>
            @button outlet: 'caseSensistiveButton', class: 'btn', 'Aa'
          @div class: 'btn-group btn-group-level', =>
            @button outlet: 'levelVerboseButton', class: 'btn syntax--log-verbose', 'V'
            @button outlet: 'levelInfoButton', class: 'btn syntax--log-info', 'I'
            @button outlet: 'levelDebugButton', class: 'btn syntax--log-debug', 'D'
            @button outlet: 'levelWarningButton', class: 'btn syntax--log-warning', 'W'
            @button outlet: 'levelErrorButton', class: 'btn syntax--log-error', 'E'

  constructor: (@textEditor) ->
    @filterBuffer = new TextBuffer
    super @filterBuffer

  initialize: ->
    @disposables = new CompositeDisposable

    @logFilter = new LogFilter(@textEditor)
    @tailing = false
    @settings =
      verbose: true
      info: true
      debug: true
      warning: true
      error: true

    @handleEvents()
    @handleConfigChanges()
    @updateButtons()
    @updateDescription()

    @disposables.add atom.tooltips.add @filterButton,
      title: "Filter Log Lines"
    @disposables.add atom.tooltips.add @tailButton,
      title: "Tail On File Changes"
    @disposables.add atom.tooltips.add @caseSensistiveButton,
      title: "Toggle case sensitivity"
    @disposables.add atom.tooltips.add @levelVerboseButton,
      title: "Toggle Verbose Level"
    @disposables.add atom.tooltips.add @levelInfoButton,
      title: "Toggle Info Level"
    @disposables.add atom.tooltips.add @levelDebugButton,
      title: "Toggle Debug Level"
    @disposables.add atom.tooltips.add @levelWarningButton,
      title: "Toggle Warning Level"
    @disposables.add atom.tooltips.add @levelErrorButton,
      title: "Toggle Error Level"

  handleEvents: ->
    @disposables.add atom.commands.add @filterEditorView.element,
      'core:confirm': => @confirm()

    @disposables.add atom.commands.add @element,
      'core:cancel': => @focusTextEditor()

    @disposables.add @logFilter.onDidFinishFilter =>
      @updateDescription()

    @filterButton.on 'click', => @confirm()
    @tailButton.on 'click', => @toggleTail()
    @caseSensistiveButton.on 'click', => @toggleCaseSensitivity()
    @levelVerboseButton.on 'click', => @toggleButton('verbose')
    @levelInfoButton.on 'click', => @toggleButton('info')
    @levelDebugButton.on 'click', => @toggleButton('debug')
    @levelWarningButton.on 'click', => @toggleButton('warning')
    @levelErrorButton.on 'click', => @toggleButton('error')

    @filterEditorView.getModel().onDidStopChanging =>
      @liveFilter()

    @textEditor.onDidStopChanging =>
      @tail()
      @updateDescription()

    @on 'focus', => @filterEditorView.focus()

  handleConfigChanges: ->
    @disposables.add atom.config.onDidChange 'language-log.adjacentLines', =>
      @confirm()

  destroy: ->
    @disposables.dispose()
    @detach()

  toggleTail: ->
    atom.config.set('language-log.tail', !atom.config.get('language-log.tail'))
    @updateButtons()
    @tail()

  toggleCaseSensitivity: ->
    atom.config.set('language-log.caseInsensitive', !atom.config.get('language-log.caseInsensitive'))
    @updateButtons()
    @confirm()

  toggleButton: (level) ->
    @settings[level] = if @settings[level] then false else true
    @updateButtons()
    @logFilter.performLevelFilter(@getFilterScopes())

  updateButtons: ->
    @tailButton.toggleClass('selected', atom.config.get('language-log.tail'))
    @caseSensistiveButton.toggleClass('selected', !atom.config.get('language-log.caseInsensitive'))
    @levelVerboseButton.toggleClass('selected', @settings.verbose)
    @levelInfoButton.toggleClass('selected', @settings.info)
    @levelDebugButton.toggleClass('selected', @settings.debug)
    @levelWarningButton.toggleClass('selected', @settings.warning)
    @levelErrorButton.toggleClass('selected', @settings.error)

  confirm: ->
    @logFilter.performTextFilter(@filterBuffer.getText())

  liveFilter: ->
    @logFilter.performTextFilter('') if @filterBuffer.getText().length is 0

  getFilterScopes: ->
    scopes = []
    unless @settings.verbose
      scopes.push 'definition.log.log-verbose'
    unless @settings.info
      scopes.push 'definition.log.log-info'
    unless @settings.debug
      scopes.push 'definition.log.log-debug'
    unless @settings.warning
      scopes.push 'definition.log.log-warning'
    unless @settings.error
      scopes.push 'definition.log.log-error'
    return scopes

  focusTextEditor: ->
    workspaceElement = atom.views.getView(atom.workspace)
    workspaceElement.focus()

  updateDescription: ->
    lines = @textEditor.getLineCount()
    filteredLines = @logFilter.getFilteredCount()

    @descriptionLabel.text(if filteredLines
      "Showing #{lines - filteredLines} of #{lines} log lines"
    else
      "Showing #{lines} log lines"
    )

    @descriptionWarningLabel.text(if lines > 10000
      "(large file warning)"
    else
      ""
    )

  tail: ->
    return unless atom.config.get('language-log.tail') and @textEditor
    return if @textEditor.isDestroyed()
    @textEditor.moveToBottom()
    @tailing = true

    @tailButton.addClass('icon-scroll')
    clearTimeout(@tailTimeout)
    @tailTimeout = setTimeout(() =>
      @tailButton.removeClass('icon-scroll')
      @tailing = false
    , 1000)
