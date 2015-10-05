path = require 'path'

Log = require '../lib/main'

describe "Log", ->
  workspaceElement = null

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    atom.project.setPaths [path.join(__dirname, 'fixtures')]
    waitsForPromise ->
      atom.packages.activatePackage('language-log')

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
