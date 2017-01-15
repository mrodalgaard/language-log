describe 'Atom log grammar', ->
  grammar = null

  getGrammar = (path, content) ->
    unless content then content = path; path = null
    atom.grammars.selectGrammar(path, content).name

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-log')

    runs ->
      grammar = atom.grammars.grammarForScopeName('source.log')

  it 'does not match first line of arbitrary files', ->
    expect(getGrammar('#!/bin/sh')).not.toBe 'Log'
    expect(getGrammar('')).not.toBe 'Log'
    expect(getGrammar('1 2 3')).not.toBe 'Log'
    expect(getGrammar('abc 2011-09-26 09:43:58')).not.toBe 'Log'
    expect(getGrammar('\n===')).not.toBe 'Log'
    expect(getGrammar('Print Guide\n1 2 3')).not.toBe 'Log'

  it 'parses the grammar', ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe 'source.log'

  it 'parses general grammars', ->
    expect(getGrammar('12-13 INFO')).toBe 'Log'

    line = '(wcp.dll version 0.0.0.6)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[1]).toEqual value: 'version 0.0.0.6', scopes: ['source.log', 'keyword.log.version']

    line = 'Demo SDK v2.25001'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[1]).toEqual value: 'v2.25001', scopes: ['source.log', 'keyword.log.version']

    line = '12-13 This directory z:\\windows\\random\\'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: 'z:\\windows\\random\\', scopes: ['source.log', 'keyword.log.path.win']

    line = '12-13 WARNING: this is a warning'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: 'WARNING', scopes: ['source.log', 'definition.log.log-warning']

    line = '12-13 Some random <Verbose> text'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: '<Verbose>', scopes: ['source.log', 'definition.log.log-verbose']

  it 'parses Android logs', ->
    expect(getGrammar('11-13 05:51:49.819: E/SoundPool()')).toBe 'Log'
    expect(getGrammar('04-08 13:11:50.022  26711-26849/com.')).toBe 'Log'

    line = '11-13 05:51:49.819: E/SoundPool(): error loading /system/media/audio/ui/Effect_Tick.ogg'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '11-13 05:51:49.819:', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'E/SoundPool():', scopes: ['source.log', 'definition.log.log-error']
    expect(tokens[5]).toEqual value: '/system/media/audio/ui/Effect_Tick.ogg', scopes: ['source.log', 'keyword.log.path']

    line = '11-13 05:51:49.929: D/dalvikvm(1359): GC_FOR_ALLOC freed 82K, 5% free 3314K/3484K'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '11-13 05:51:49.929:', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[1]).toEqual value: ' D/dalvikvm(1359): GC_FOR_ALLOC freed 82K, 5% free 3314K/3484K', scopes: ['source.log', 'definition.log.log-verbose']

    line = '11-13 05:51:52.329: I/dalvikvm(1359): "AsyncTask #1" prio=5 tid=11 RUNNABLE'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '11-13 05:51:52.329:', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'I/dalvikvm(1359):', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: '"AsyncTask #1"', scopes: ['source.log', 'log.string.double']

    line = '04-08 13:11:50.022  26711-26849/com.nabto.nabtovideo E/SoundPool: error loading /system/media/audio/ui/Effect_Tick.ogg'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '04-08 13:11:50.022', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'E/SoundPool:', scopes: ['source.log', 'definition.log.log-error']
    expect(tokens[5]).toEqual value: '/system/media/audio/ui/Effect_Tick.ogg', scopes: ['source.log', 'keyword.log.path']

  it 'parses Android logs with option "threadtime"', ->
    expect(getGrammar('02-12 17:25:47.614  2335 26149 D WebSocketC')).toBe 'Log'

    line = '02-12 17:25:47.614  2335 26149 D WebSocketClient: sending websocket request'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '02-12 17:25:47.614', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'D WebSocketClient:', scopes: ['source.log', 'definition.log.log-debug']

    line = '02-12 17:27:08.317  2335 26149 I WebSocketClient: Got error while connecting, will retry, ex: java.net.UnknownHostException: Unable to resolve host'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '02-12 17:27:08.317', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'I WebSocketClient:', scopes: ['source.log', 'definition.log.log-info']

    line = '02-12 17:37:00.539 27023 27023 V EventContext: unregister, observers count: 3698'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '02-12 17:37:00.539', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'V EventContext:', scopes: ['source.log', 'definition.log.log-verbose']

    line = '02-12 17:36:40.271   795   805 W InputMethodManagerService: Starting input on non-focused client'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '02-12 17:36:40.271', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'W InputMethodManagerService:', scopes: ['source.log', 'definition.log.log-warning']

    line = '02-12 17:36:40.190  1723  1736 E ANDR-PERF-LOCK: Failed to apply optimization for resource: 4 level: 0'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '02-12 17:36:40.190', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'E ANDR-PERF-LOCK:', scopes: ['source.log', 'definition.log.log-error']

  it 'parses Android Marshmallow logs', ->
    expect(getGrammar('01-15 20:44:02.331  2149  2905 W GLSUser : ')).toBe 'Log'

    line = '01-15 20:42:22.907  1578  1589 D ActivityManager: cleanUpApplicationRecord -- 2762'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '01-15 20:42:22.907', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'D ActivityManager:', scopes: ['source.log', 'definition.log.log-debug']

    line = '10-13 07:28:57.654  2814  2828 I TestRunner: 	at org.junit.runners.model.RunnerBuilder.runners(RunnerBuilder.java:87)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '10-13 07:28:57.654', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'I TestRunner:', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: '(RunnerBuilder.java:87)', scopes: ['source.log', 'definition.log.string.location']

  it 'parses iOS logs', ->
    expect(getGrammar('[2015-09-17 16:37:57 CEST] <main> INFO')).toBe 'Log'

    line = 'Incident Identifier: A8111234-3CD8-4FF0-BD99-CFF7FDACB212'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Incident Identifier:', scopes: ['source.log', 'definition.log.log-verbose']
    expect(tokens[2]).toEqual value: 'A8111234-3CD8-4FF0-BD99-CFF7FDACB212', scopes: ['source.log', 'keyword.log.serial']

    line = '[2015-09-17 16:37:57 CEST] <main> INFO: Configuration refresh successful.'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[2015-09-17 16:37:57 CEST]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'INFO', scopes: ['source.log', 'definition.log.log-info']

    line = '[2015-09-17 16:37:59 CEST] <main> DBG-X:   parameter BaseVersion = 1.8.3'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[2015-09-17 16:37:59 CEST]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'DBG-X', scopes: ['source.log', 'definition.log.log-debug']

  it 'parses IDEA logs', ->
    expect(getGrammar('2014-12-11 14:00:36,047 [ 200232]   INFO')).toBe 'Log'

    line = '2014-12-11 14:00:36,047 [ 200232]   INFO - ls.idea.gradle.util.GradleUtil - Looking for embedded Maven repo at \'/Applications/Android Studio.app/Contents/gradle/m2repository\' '
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2014-12-11 14:00:36,047', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[ 200232]   INFO', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: '\'/Applications/Android Studio.app/Contents/gradle/m2repository\'', scopes: ['source.log', 'log.string.single']

    line = '2014-12-11 14:00:52,133 [ 216318]   WARN - j.ui.mac.MacMainFrameDecorator - no url bundle present.'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: '[ 216318]   WARN', scopes: ['source.log', 'definition.log.log-warning']

    line = '["your-protocol"] will handle following links: your-protocol://open?file=file&line=line stop'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[1]).toEqual value: '"your-protocol"', scopes: ['source.log', 'log.string.double']
    expect(tokens[3]).toEqual value: 'your-protocol://open?file=file&line=line', scopes: ['source.log', 'keyword.log.url']

  it 'parses syslog', ->
    expect(getGrammar('May 11 11:32:40 scrooge SG_child[1829]: [ID')).toBe 'Log'

    line = 'May 11 10:40:48 scrooge disk-health-nurse[26783]: [ID 702911 user.error] m:SY-mon-full-500 c:H : partition'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'May 11 10:40:48', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[ID 702911 user.error]', scopes: ['source.log', 'definition.log.log-info']

  it 'parses Apache logs', ->
    expect(getGrammar('64.242.88.10 - - [07/Mar/2004:16:45:56 -0800]')).toBe 'Log'
    expect(getGrammar('[07/Mar/2004:16:24:16] "GET /twiki/bin/view/M')).toBe 'Log'

    line = '07/Mar/2004:16:24:16 "GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1" 200 4924'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '07/Mar/2004:16:24:16', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = '[07/03/2004:16:24:16] "GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1" 200 4924'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[07/03/2004:16:24:16]', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = '[07/Mar/2004:16:24:16] "GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1" 200 4924'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[07/Mar/2004:16:24:16]', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = '64.242.88.10 - - [07/Mar/2004:16:24:16 -0800] "GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1" 200 4924'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '64.242.88.10', scopes: ['source.log', 'keyword.log.ip']
    expect(tokens[2]).toEqual value: '[07/Mar/2004:16:24:16 -0800]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[4]).toEqual value: '"GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1"', scopes: ['source.log', 'log.string.double']
    expect(tokens[6]).toEqual value: '200', scopes: ['source.log', 'definition.log.log-success']

    line = '64.242.88.10 - - [07/Mar/2004:16:45:56 -0800] "GET /twiki/bin/attach/Main/PostfixCommands HTTP/1.1" 401 12846'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[6]).toEqual value: '401', scopes: ['source.log', 'definition.log.log-failed']

    line = '::1 - - [20/Apr/2015:18:09:10 +0200] "GET / HTTP/1.1" 304 -'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '::1 - - ', scopes: ['source.log']
    expect(tokens[1]).toEqual value: '[20/Apr/2015:18:09:10 +0200]', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = 'localhost - - [21/Apr/2015:09:20:21 +0200] "GET /favicon.ico HTTP/1.1" 404 209'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'localhost - - ', scopes: ['source.log']
    expect(tokens[1]).toEqual value: '[21/Apr/2015:09:20:21 +0200]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[5]).toEqual value: '404', scopes: ['source.log', 'definition.log.log-failed']

    line = '[Sun Mar  7 16:02:00 2004] [notice] Accept mutex: sysvsem (Default: sysvsem)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[Sun Mar  7 16:02:00 2004]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[notice]', scopes: ['source.log', 'definition.log.log-verbose']

    line = '[Thu Mar 11 07:39:29 2004] [error] [client 140.113.179.131] File does not exist: /usr/local/apache/htdocs/M83A'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[Thu Mar 11 07:39:29 2004]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[error]', scopes: ['source.log', 'definition.log.log-error']
    expect(tokens[4]).toEqual value: '140.113.179.131', scopes: ['source.log', 'keyword.log.ip']
    expect(tokens[7]).toEqual value: '/usr/local/apache/htdocs/M83A', scopes: ['source.log', 'keyword.log.path']

  it 'parses Nabto logs', ->
    expect(getGrammar('141121-14:00:26.095 {00007fff7463f300} [___')).toBe 'Log'

    line = '141121-14:00:26.095 {00007fff7463f300} [_______APP,trace] nabto_client_facade.cpp(439):        Got cert \'demo@gmail.com\''
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '141121-14:00:26.095', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '{00007fff7463f300}', scopes: ['source.log', 'definition.log.comment.location']
    expect(tokens[4]).toEqual value: '[_______APP,trace] nabto_client_facade.cpp(439)', scopes: ['source.log', 'definition.log.log-verbose']
    expect(tokens[6]).toEqual value: '\'demo@gmail.com\'', scopes: ['source.log', 'log.string.single']

    line = '141121-14:00:26.160 {00007fff7463f300} [AUTOMATLST,debug] automatalist.cpp(235):               clientpeer-0 active: 1 closed: 0/0 deleted: 0'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '141121-14:00:26.160', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[4]).toEqual value: '[AUTOMATLST,debug] automatalist.cpp(235)', scopes: ['source.log', 'definition.log.log-debug']

    line = '141121-14:00:26.130 {000000010459f000} [___DEFAULT,error] api_request_handler.cpp(59):         An error occurred when handling url demo1.nabduino.net: 2000042'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[4]).toEqual value: '[___DEFAULT,error] api_request_handler.cpp(59)', scopes: ['source.log', 'definition.log.log-error']

    line = '150813-17:43:26.552 {00007fff74190300} [_______APP,info_] nabto_client_facade.cpp(635):        fetchUrl(nabto://demo.nabto.net/wind_speed.json?) ended (with success) in 0.001148 seconds, result length is 70'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[6]).toEqual value: 'nabto://demo.nabto.net/wind_speed.json?', scopes: ['source.log', 'keyword.log.url']

  it 'parses Adobe logs', ->
    expect(getGrammar('04/25/15 14:51:34:414 | [INFO] |')).toBe 'Log'

    line = '04/25/15 14:51:34:414 | [INFO] |  | OOBE | DE |  |  |  | 2424952 | Visit http://www.adobe.com/go/loganalyzer/ for more information'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '04/25/15 14:51:34:414', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[INFO]', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: 'http://www.adobe.com/go/loganalyzer/', scopes: ['source.log', 'keyword.log.url']

    line = '04/25/15 14:51:35:002 | [WARN] |  | OOBE | DE |  |  |  | 2424970 | AdobeColorEU CC 5.0.0.0 {9E9EB9FD-FDE8-487A-A41C-7713DA91AC89}: 1 (0,1)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '04/25/15 14:51:35:002', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[WARN]', scopes: ['source.log', 'definition.log.log-warning']
    expect(tokens[4]).toEqual value: '5.0.0.0', scopes: ['source.log', 'keyword.log.ip']
    expect(tokens[6]).toEqual value: '9E9EB9FD-FDE8-487A-A41C-7713DA91AC89', scopes: ['source.log', 'keyword.log.serial']

  it 'parses FaceTime logs', ->
    line = '2015-04-16 14:44:00 +0200 [FaceTimeServiceSession(imagent:281:YES):Default] Priming FaceTime Server bag'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-04-16 14:44:00', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses Google logs', ->
    expect(getGrammar('2015-03-11 21:07:03.094 GoogleSoftwareUpdat')).toBe 'Log'

    line = '2015-03-11 21:07:03.094 GoogleSoftwareUpdateAgent[54133/0xb0219000] [lvl=1] -[KSProductsReportingStore updateActivesData:forProductID:withKey:] Updating of actives data started.'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-03-11 21:07:03.094', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[lvl=1]', scopes: ['source.log', 'definition.log.log-info']

    line = '2015-03-11 21:07:03.156 GoogleSoftwareUpdateAgent[54133/0xb0219000] [lvl=2] -[KSUpdateEngine updateProductID:] KSUpdateEngine updating product ID: "com.google.Keystone"'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: '[lvl=2]', scopes: ['source.log', 'definition.log.log-warning']
    expect(tokens[4]).toEqual value: '"com.google.Keystone"', scopes: ['source.log', 'log.string.double']

    line = '2015-03-11 21:07:03.132 GoogleSoftwareUpdateAgent[54133/0xb0219000] [lvl=3] -[KSAgentApp(KeystoneThread) runKeystonesInThreadWithArg:] Failed to connect to system engine.'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: '[lvl=3]', scopes: ['source.log', 'definition.log.log-error']

    line = '		xc=<KSPathExistenceChecker:0x316f20 path=/Users/Random/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle>'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: '/Users/Random/Library/Google/GoogleSoftwareUpdate/GoogleSoftwareUpdate.bundle', scopes: ['source.log', 'keyword.log.path']

  it 'parses VMWare logs', ->
    expect(getGrammar('2015-04-23T13:58:41.657+01:00| VMware Fusio')).toBe 'Log'

    line = '2015-04-23T13:58:41.657+01:00| VMware Fusion| I120: VTHREAD initialize main thread 4 "VMware Fusion" pid 9824'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-04-23T13:58:41.657+01:00', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses SourceForge logs', ->
    line = '[575435.110] Initializing built-in extension Generic Event Extension'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[575435.110]', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses auth logs', ->
    expect(getGrammar('Apr 28 08:46:03 (72.84) AuthenticationAllow')).toBe 'Log'

    line = 'Apr 28 08:46:03 (72.84) AuthenticationAllowed completed: record "Random", result: Success (0).'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Apr 28 08:46:03', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = 'Jan 1 12:47:22 (72.84) AuthenticationAllowed completed: record "Random", result: Success (0).'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Jan 1 12:47:22', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses Apple logs', ->
    expect(getGrammar('Oct 21 09:12:33 Mac.local storeagent[289]')).toBe 'Log'

    line = 'Oct 21 09:12:33 Martins-MacBook-Pro.local storeagent[289] <Critical>: -[ISStoreURLOperation _runURLOperation]: _addStandardQueryParametersForURL: https://init.itunes.apple.com/bag.xml?ix=5'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Oct 21 09:12:33', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '<Critical>', scopes: ['source.log', 'definition.log.log-error']
    expect(tokens[4]).toEqual value: 'https://init.itunes.apple.com/bag.xml?ix=5', scopes: ['source.log', 'keyword.log.url']

    line = 'Oct 21 18:37:48 martins-macbook-pro storeagent[289] <Info>: sending status (OS X Yosemite): 0.762024% (587.465185)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: '<Info>', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: '0.762024%', scopes: ['source.log', 'constant.numeric.log']

    line = 'Mon Dec 30 15:19:10.047 <airportd[78]> _doAutoJoin: Already associated to “Martin-NET”. Bailing on auto-join.'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Mon Dec 30 15:19:10.047', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '“Martin-NET”', scopes: ['source.log', 'log.string.double']

  it 'parses ppp vpn logs', ->
    expect(getGrammar('Thu Oct  9 11:52:14 2014 : IPSec')).toBe 'Log'

    line = 'Thu Oct  9 11:52:14 2014 : IPSec connection established'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Thu Oct  9 11:52:14 2014 :', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses Windows CBS logs', ->
    expect(getGrammar('2015-08-14 05:50:12, Info  ')).toBe 'Log'

    line = '2015-08-14 05:50:12, Info                  CBS    TI: Last boot time: 2015-08-14 03:49:58.302'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-08-14 05:50:12', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'Info', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[3]).toEqual value: '                  CBS', scopes: ['source.log', 'constant.log.cbs']
    expect(tokens[5]).toEqual value: '2015-08-14 03:49:58.302', scopes: ['source.log', 'definition.comment.timestamp.log.inline']

    line = '2015-08-15 00:21:09, Info                  CSI    0000514d Created NT transaction (seq 2) result 0x00000000, handle @0x1118'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-08-15 00:21:09', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'Info', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[3]).toEqual value: '                  CSI', scopes: ['source.log', 'entity.log.csi']

    line = '2015-08-15 00:12:17, Info                  CBS    Loaded Servicing Stack v10.0.10240.16384 with Core: C:\\WINDOWS\\winsxs\\amd64_microsoft-windows\\cbscore.dll PATH'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[5]).toEqual value: 'v10.0.10240.16384', scopes: ['source.log', 'keyword.log.version']
    expect(tokens[7]).toEqual value: 'C:\\WINDOWS\\winsxs\\amd64_microsoft-windows\\cbscore.dll', scopes: ['source.log', 'keyword.log.path.win']

    line = '2015-08-13 11:50:04, Error                 CBS    Failed to process single phase execution. [HRESULT = 0x800f0816 - CBS_E_DPX_JOB_STATE_SAVED]'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: 'Error', scopes: ['source.log', 'definition.log.log-error']

    line = '2015-08-13 11:50:15, Info                  DPX    Started DPX phase: Resume and Download Job'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[3]).toEqual value: '                  DPX', scopes: ['source.log', 'entity.log.csi']

    line = '2014-10-21 14:17:10, Info                  DISM   Service Pack Cleanup UI: PID=4704 WAU editions installed 2  -'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[3]).toEqual value: '                  DISM', scopes: ['source.log', 'variable.log.dism']

    line = '2014-10-21 14:17:52, Info                  CBS    DC: tree root as a root relative path: c\\Windows\\winsxs\\x86_microsoft-win_none_bb705a'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[5]).toEqual value: '\\Windows\\winsxs\\x86_microsoft-win_none_bb705a', scopes: ['source.log', 'keyword.log.path.win']

    line = '2011-09-26 09:43:58, Info                  DPX    CreateFileW failed, FileName:\\\\?\\C:\\Windows\\temp\\$dpx$.tmp\\job.xml, Error:0x80070002'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[5]).toEqual value: 'C:\\Windows\\temp\\$dpx$.tmp\\job.xml', scopes: ['source.log', 'keyword.log.path.win']

  it 'parses jboss logs', ->
    expect(getGrammar('18:35:44,633 WARN org.springframework.beans')).toBe 'Log'

    line = "18:35:44,633 WARN org.springframework.beans.factory.support.DisposableBeanAdapter Invocation of destroy method 'close' failed on bean with name 'sqlSession': java.lang.UnsupportedOperationException: Manual close is"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '18:35:44,633', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'WARN', scopes: ['source.log', 'definition.log.log-warning']
    expect(tokens[4]).toEqual value: "'close'", scopes: ['source.log', 'log.string.single']

  it 'parses npm-debug.log', ->
    expect(getGrammar('npm-debug.log', '0 info it worked if it ends with ok')).toBe 'Log'

    line = "70 http request GET https://registry.npmjs.org/bindings"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '70', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'http', scopes: ['source.log', 'definition.log.log-info']

    line = "71 verbose request uri https://registry.npmjs.org/nan"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '71', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'verbose', scopes: ['source.log', 'definition.log.log-verbose']

    line = "75 http request GET https://registry.npmjs.org/nan"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '75', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'http', scopes: ['source.log', 'definition.log.log-info']

    line = "76 http 304 https://registry.npmjs.org/nan"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '76', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'http', scopes: ['source.log', 'definition.log.log-info']

    line = "85 silly addNamed nan@>=2.2.0 <3.0.0"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '85', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'silly', scopes: ['source.log', 'definition.log.log-verbose']

    line = "344 info lifecycle nan@2.2.0~install: nan@2.2.0"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '344', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'info', scopes: ['source.log', 'definition.log.log-info']

    line = "361 warn EPACKAGEJSON tmp No description"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '361', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'warn', scopes: ['source.log', 'definition.log.log-warning']

    line = "373 error Exit status 1"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '373', scopes: ['source.log', 'comment.block.log.index']
    expect(tokens[2]).toEqual value: 'error', scopes: ['source.log', 'definition.log.log-error']

  it 'parses mail logs', ->
    expect(getGrammar('2008-11-08 06:32:46.354761500 26318 loggin:')).toBe 'Log'

    line = "2008-11-08 06:35:41.724563500 26375 logging::logterse plugin: ` 58.126.113.198	Unknown	[58.126.113.198]	<benny@surecom.com>		rhsbl	901	Not supporting null originator (DSN)	msg denied before queued"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2008-11-08 06:35:41.724563500', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '58.126.113.198', scopes: ['source.log', 'keyword.log.ip']
    expect(tokens[4]).toEqual value: "58.126.113.198", scopes: ['source.log', 'keyword.log.ip']
    expect(tokens[6]).toEqual value: "<benny@surecom.com>", scopes: ['source.log', 'log.string.mail']

    line = "2008-11-08 06:37:31.730609500 26398 logging::logterse plugin: ` 87.103.146.91:5555	pmsn.91.146.103.87.sable.dsl.krasnet.ru	pmsn.91.146.103.87.sable.dsl.krasnet.ru	dnsbl	903	http://www.spamhaus.org/query/bl?ip=87.103.146.91"
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2008-11-08 06:37:31.730609500', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '87.103.146.91:5555', scopes: ['source.log', 'keyword.log.ip']
    expect(tokens[8]).toEqual value: "http://www.spamhaus.org/query/bl?ip=87.103.146.91", scopes: ['source.log', 'keyword.log.url']
