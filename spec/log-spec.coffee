describe 'Atom log grammar', ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-log')

    runs ->
      grammar = atom.grammars.grammarForScopeName('source.log')

  it 'parses the grammar', ->
    expect(grammar).toBeTruthy()
    expect(grammar.scopeName).toBe 'source.log'

  it 'parses general grammars', ->
    line = '(wcp.dll version 0.0.0.6)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[1]).toEqual value: 'version 0.0.0.6', scopes: ['source.log', 'keyword.log.version']

    line = 'Demo SDK v2.25001'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[1]).toEqual value: 'v2.25001', scopes: ['source.log', 'keyword.log.version']

    line = '12-34 This directory z:\\windows\\random\\'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: 'z:\\windows\\random\\', scopes: ['source.log', 'keyword.log.path.win']

  it 'parses Android logs', ->
    line = '11-13 05:51:49.819: E/SoundPool(): error loading /system/media/audio/ui/Effect_Tick.ogg'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '11-13 05:51:49.819:', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'E/SoundPool():', scopes: ['source.log', 'definition.log.log-error']
    expect(tokens[5]).toEqual value: '/system/media/audio/ui/Effect_Tick.ogg', scopes: ['source.log', 'keyword.log.path']

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

  it 'parses iOS logs', ->
    line = 'Incident Identifier: A8111234-3CD8-4FF0-BD99-CFF7FDACB212'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Incident Identifier:', scopes: ['source.log', 'definition.log.log-verbose']
    expect(tokens[2]).toEqual value: 'A8111234-3CD8-4FF0-BD99-CFF7FDACB212', scopes: ['source.log', 'keyword.log.serial']

  it 'parses IDEA logs', ->
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

  it 'parses Apache logs', ->
    line = '64.242.88.10 - - [07/Mar/2004:16:24:16 -0800] "GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1" 200 4924'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '64.242.88.10 - -', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '"GET /twiki/bin/view/Main/PeterThoeny HTTP/1.1"', scopes: ['source.log', 'log.string.double']
    expect(tokens[4]).toEqual value: '200', scopes: ['source.log', 'definition.log.log-success']

    line = '64.242.88.10 - - [07/Mar/2004:16:45:56 -0800] "GET /twiki/bin/attach/Main/PostfixCommands HTTP/1.1" 401 12846'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[4]).toEqual value: '401', scopes: ['source.log', 'definition.log.log-failed']

    line = '::1 - - [20/Apr/2015:18:09:10 +0200] "GET / HTTP/1.1" 304 -'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '::1 - -', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = 'localhost - - [21/Apr/2015:09:20:21 +0200] "GET /favicon.ico HTTP/1.1" 404 209'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'localhost - -', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[4]).toEqual value: '404', scopes: ['source.log', 'definition.log.log-failed']

    line = '[Sun Mar  7 16:02:00 2004] [notice] Accept mutex: sysvsem (Default: sysvsem)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[Sun Mar  7 16:02:00 2004]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[notice]', scopes: ['source.log', 'definition.log.log-verbose']

    line = '[Thu Mar 11 07:39:29 2004] [error] [client 140.113.179.131] File does not exist: /usr/local/apache/htdocs/M83A'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[Thu Mar 11 07:39:29 2004]', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[error]', scopes: ['source.log', 'definition.log.log-error']
    expect(tokens[5]).toEqual value: '/usr/local/apache/htdocs/M83A', scopes: ['source.log', 'keyword.log.path']

  it 'parses Nabto logs', ->
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
    line = '04/25/15 14:51:34:414 | [INFO] |  | OOBE | DE |  |  |  | 2424952 | Visit http://www.adobe.com/go/loganalyzer/ for more information'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '04/25/15 14:51:34:414', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[INFO]', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: 'http://www.adobe.com/go/loganalyzer/', scopes: ['source.log', 'keyword.log.url']

    line = '04/25/15 14:51:35:002 | [WARN] |  | OOBE | DE |  |  |  | 2424970 | AdobeColorEU CC 5.0.0.0 {9E9EB9FD-FDE8-487A-A41C-7713DA91AC89}: 1 (0,1)'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '04/25/15 14:51:35:002', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: '[WARN]', scopes: ['source.log', 'definition.log.log-warning']
    expect(tokens[4]).toEqual value: '9E9EB9FD-FDE8-487A-A41C-7713DA91AC89', scopes: ['source.log', 'keyword.log.serial']

  it 'parses FaceTime logs', ->
    line = '2015-04-16 14:44:00 +0200 [FaceTimeServiceSession(imagent:281:YES):Default] Priming FaceTime Server bag'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-04-16 14:44:00', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses Google logs', ->
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
    line = '2015-04-23T13:58:41.657+01:00| VMware Fusion| I120: VTHREAD initialize main thread 4 "VMware Fusion" pid 9824'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-04-23T13:58:41.657+01:00|', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses SourceForge logs', ->
    line = '[575435.110] Initializing built-in extension Generic Event Extension'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '[575435.110]', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses auth logs', ->
    line = 'Apr 28 08:46:03 (72.84) AuthenticationAllowed completed: record "Random", result: Success (0).'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Apr 28 08:46:03', scopes: ['source.log', 'definition.comment.timestamp.log']

    line = 'Jan 1 12:47:22 (72.84) AuthenticationAllowed completed: record "Random", result: Success (0).'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Jan 1 12:47:22', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses Apple logs', ->
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
    line = 'Thu Oct  9 11:52:14 2014 : IPSec connection established'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: 'Thu Oct  9 11:52:14 2014 :', scopes: ['source.log', 'definition.comment.timestamp.log']

  it 'parses Windows CBS logs', ->
    line = '2015-08-14 05:50:12, Info                  CBS    TI: Last boot time: 2015-08-14 03:49:58.302'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-08-14 05:50:12', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'Info', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: 'CBS', scopes: ['source.log', 'constant.log.cbs']
    expect(tokens[6]).toEqual value: '2015-08-14 03:49:58.302', scopes: ['source.log', 'definition.comment.timestamp.log.inline']

    line = '2015-08-15 00:21:09, Info                  CSI    0000514d Created NT transaction (seq 2) result 0x00000000, handle @0x1118'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[0]).toEqual value: '2015-08-15 00:21:09', scopes: ['source.log', 'definition.comment.timestamp.log']
    expect(tokens[2]).toEqual value: 'Info', scopes: ['source.log', 'definition.log.log-info']
    expect(tokens[4]).toEqual value: 'CSI', scopes: ['source.log', 'entity.log.csi.dpx']

    line = '2015-08-15 00:12:17, Info                  CBS    Loaded Servicing Stack v10.0.10240.16384 with Core: C:\\WINDOWS\\winsxs\\amd64_microsoft-windows\\cbscore.dll PATH'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[6]).toEqual value: 'v10.0.10240.16384', scopes: ['source.log', 'keyword.log.version']
    expect(tokens[8]).toEqual value: 'C:\\WINDOWS\\winsxs\\amd64_microsoft-windows\\cbscore.dll', scopes: ['source.log', 'keyword.log.path.win']

    line = '2015-08-13 11:50:04, Error                 CBS    Failed to process single phase execution. [HRESULT = 0x800f0816 - CBS_E_DPX_JOB_STATE_SAVED]'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[2]).toEqual value: 'Error', scopes: ['source.log', 'definition.log.log-error']

    line = '2015-08-13 11:50:15, Info                  DPX    Started DPX phase: Resume and Download Job'
    {tokens} = grammar.tokenizeLine(line)
    expect(tokens[4]).toEqual value: 'DPX', scopes: ['source.log', 'entity.log.csi.dpx']
