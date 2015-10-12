path = require 'path'

Log = require '../lib/main'

describe "Log", ->
  {workspaceElement, logModule} = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.project.setPaths [path.join(__dirname, 'fixtures')]
    waitsForPromise ->
      atom.packages.activatePackage('language-log')
    runs ->
      logModule = atom.packages.loadedPackages['language-log'].mainModule

  describe "open", ->
    it "shows filter bar when opening a log file", ->
      expect(workspaceElement.querySelector('.log-view')).not.toExist()

      waitsForPromise ->
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).toExist()

    it "does not show on non log files", ->
      waitsForPromise ->
        atom.workspace.open '../main-spec.coffee'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).not.toExist()

    it "does not show when disabled in config", ->
      atom.config.set 'language-log.showFilterBar', false
      waitsForPromise ->
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).not.toExist()

    it "opens when log view is active in split pane", ->
      waitsForPromise ->
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).toExist()

        pane = atom.workspace.getActivePane()
        pane.splitRight()
        expect(atom.workspace.getPanes()).toHaveLength 2
        expect(workspaceElement.querySelector('.log-view')).not.toExist()

        atom.workspace.activatePreviousPane()
        expect(workspaceElement.querySelector('.log-view')).toExist()

    it "remembers filter input", ->
      waitsForPromise ->
        atom.workspace.open '../coffeelint.json'
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).toExist()
        expect(logModule.logView.filterBuffer.getText()).toEqual ''
        expect(logModule.logView.settings.verbose).toEqual true
        logModule.logView.filterBuffer.setText '123'
        logModule.logView.settings.verbose = false

        item = atom.workspace.getPaneItems()[0]
        atom.workspace.getActivePane().activateItem(item)
        expect(workspaceElement.querySelector('.log-view')).not.toExist()

        item = atom.workspace.getPaneItems()[1]
        atom.workspace.getActivePane().activateItem(item)
        expect(workspaceElement.querySelector('.log-view')).toExist()
        expect(logModule.logView.filterBuffer.getText()).toEqual '123'
        expect(logModule.logView.settings.verbose).toEqual false
