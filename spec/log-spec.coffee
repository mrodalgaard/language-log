describe 'Htaccess grammar', ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-log')

    runs ->
      grammar = atom.grammars.grammarForScopeName('source.log')
  
  it 'parses the grammar', ->
    expect(grammar).toBeTruthy()
    return expect(grammar.scopeName).toBe("source.log")
  
  it 'parses simple IDEA timestamp', ->
    line = "2014-12-11 13:16:10,563 [      0]   INFO -        #com.intellij.idea.Main - IDE: Android Studio (build #AI-135.1629389, 05 Dec 2014 00:00) "
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2014-12-11 13:16:10,563 ', scopes: ['source.log', 'definition.comment.log']

  it 'parses android errors', ->
    line = "11-13 05:51:49.819: E/SoundPool(): error loading /system/media/audio/ui/Effect_Tick.ogg"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[1]).toEqual value: 'E/SoundPool():', scopes: ['source.log', 'definition.log.log-error']
