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
      expect(logModule.logView).not.toExist()
      expect(workspaceElement.querySelector('.log-view')).not.toExist()

      waitsForPromise ->
        atom.workspace.open 'android.log'
      runs ->
        expect(logModule.logView).toExist()
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
      waitsForPromise ->
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).toExist()
        expect(logModule.logView.filterBuffer.getText()).toEqual ''
        expect(logModule.logView.settings.verbose).toEqual true
        logModule.logView.filterBuffer.setText '123'
        logModule.logView.settings.verbose = false

        atom.workspace.getActivePane().activatePreviousItem()
        expect(workspaceElement.querySelector('.log-view')).not.toExist()

        atom.workspace.getActivePane().activateNextItem()
        expect(workspaceElement.querySelector('.log-view')).toExist()
        expect(logModule.logView.filterBuffer.getText()).toEqual '123'
        expect(logModule.logView.settings.verbose).toEqual false

    it "toggles on grammar change from log", ->
      waitsForPromise ->
        atom.packages.activatePackage('language-text')
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).toExist()
        item = atom.workspace.getActivePaneItem()
        expect(item.getGrammar().name).toBe 'Log'
        item.setGrammar(atom.grammars.getGrammars()[2])
        expect(workspaceElement.querySelector('.log-view')).not.toExist()
        expect(item.getGrammar().name).not.toBe 'Log'
        item.setGrammar(atom.grammars.getGrammars()[1])
        expect(workspaceElement.querySelector('.log-view')).toExist()
        expect(item.getGrammar().name).toBe 'Log'

    it "toggles on grammar change to log", ->
      waitsForPromise ->
        atom.packages.activatePackage('language-text')
        atom.workspace.open '../log-spec.coffee'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).not.toExist()
        item = atom.workspace.getActivePaneItem()
        expect(item.getGrammar().name).not.toBe 'Log'
        item.setGrammar(atom.grammars.getGrammars()[1])
        expect(workspaceElement.querySelector('.log-view')).toExist()
        expect(item.getGrammar().name).toBe 'Log'

    it "does not fail on image (no grammar) load", ->
      waitsForPromise ->
        atom.packages.activatePackage('image-view')
      waitsForPromise ->
        atom.workspace.open '../../screenshots/preview.png'
      waitsForPromise ->
        atom.workspace.open 'android.log'
      runs ->
        expect(workspaceElement.querySelector('.log-view')).toExist()
        atom.workspace.getActivePane().activatePreviousItem()
        expect(workspaceElement.querySelector('.log-view')).not.toExist()
        atom.workspace.getActivePane().activateNextItem()
        expect(workspaceElement.querySelector('.log-view')).toExist()
        atom.workspace.getActivePane().activatePreviousItem()
        expect(workspaceElement.querySelector('.log-view')).not.toExist()
