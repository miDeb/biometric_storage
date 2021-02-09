import 'dart:io';

import 'package:biometric_storage/biometric_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _logger = Logger('main');
var logs = "";

void main() {
  _logger.onRecord.listen((record) {
    logs += record.message + "\n";
  });
  Logger.root.level = Level.ALL;
  _logger.fine('Application launched. (v2)');
  runApp(MyApp());
}

class StringBufferWrapper with ChangeNotifier {
  final StringBuffer _buffer = StringBuffer();

  void writeln(String line) {
    _buffer.writeln(line);
    notifyListeners();
  }

  @override
  String toString() => _buffer.toString();
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final String baseName = 'default';
  BiometricStorageFile? _authStorage;
  BiometricStorageFile? _storage;
  BiometricStorageFile? _customPrompt;
  BiometricStorageFile? _noConfirmation;

  final TextEditingController _writeController =
      TextEditingController(text: 'Lorem Ipsum');

  @override
  void initState() {
    super.initState();
    _checkAuthenticate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<CanAuthenticateResponse> _checkAuthenticate() async {
    final response = await BiometricStorage().canAuthenticate();
    _logger.info('checked if authentication was possible: $response');
    return response;
  }

  void _logChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            const Text('Methods:'),
            RaisedButton(
              child: const Text('init'),
              onPressed: () async {
                _logger.finer('Initializing $baseName');
                final authenticate = await _checkAuthenticate();
                bool supportsAuthenticated = false;
                if (authenticate == CanAuthenticateResponse.success) {
                  supportsAuthenticated = true;
                } else if (authenticate !=
                    CanAuthenticateResponse.unsupported) {
                  supportsAuthenticated = false;
                } else {
                  _logger.severe(
                      'Unable to use authenticate. Unable to get storage.');
                  return;
                }
                if (supportsAuthenticated) {
                  _authStorage = await BiometricStorage().getStorage(
                      '${baseName}_authenticated',
                      options: StorageFileInitOptions(
                          authenticationValidityDurationSeconds: 30));
                }
                _storage = await BiometricStorage()
                    .getStorage('${baseName}_unauthenticated',
                        options: StorageFileInitOptions(
                          authenticationRequired: false,
                        ));
                if (supportsAuthenticated) {
                  _customPrompt = await BiometricStorage().getStorage(
                      '${baseName}_customPrompt',
                      options: StorageFileInitOptions(
                          authenticationValidityDurationSeconds: 30),
                      androidPromptInfo: const AndroidPromptInfo(
                        title: 'Custom title',
                        subtitle: 'Custom subtitle',
                        description: 'Custom description',
                        negativeButton: 'Nope!',
                      ));
                  _noConfirmation = await BiometricStorage().getStorage(
                      '${baseName}_customPrompt',
                      options: StorageFileInitOptions(
                          authenticationValidityDurationSeconds: 30),
                      androidPromptInfo: const AndroidPromptInfo(
                        confirmationRequired: false,
                      ));
                }
                setState(() {});
                _logger.info('initiailzed $baseName');
              },
            ),
            ...?_appArmorButton(),
            ...(_authStorage == null
                ? []
                : [
                    const Text('Biometric Authentication',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    StorageActions(
                        storageFile: _authStorage!,
                        writeController: _writeController),
                    const Divider(),
                  ]),
            ...?(_storage == null
                ? null
                : [
                    const Text('Unauthenticated',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    StorageActions(
                        storageFile: _storage!,
                        writeController: _writeController),
                    const Divider(),
                  ]),
            ...?(_customPrompt == null
                ? null
                : [
                    const Text('Custom Authentication Prompt (Android)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    StorageActions(
                        storageFile: _customPrompt!,
                        writeController: _writeController),
                    const Divider(),
                  ]),
            ...?(_noConfirmation == null
                ? null
                : [
                    const Text('No Confirmation Prompt (Android)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    StorageActions(
                        storageFile: _noConfirmation!,
                        writeController: _writeController),
                  ]),
            const Divider(),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Example text to write',
              ),
              controller: _writeController,
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                constraints: const BoxConstraints.expand(),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(logs),
                  ),
                  reverse: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget>? _appArmorButton() => kIsWeb || !Platform.isLinux
      ? null
      : [
          RaisedButton(
            child: const Text('Check App Armor'),
            onPressed: () async {
              if (await BiometricStorage().linuxCheckAppArmorError()) {
                _logger.info('Got an error! User has to authorize us to '
                    'use secret service.');
                _logger.info(
                    'Run: `snap connect biometric-storage-example:password-manager-service`');
              } else {
                _logger.info('all good.');
              }
            },
          )
        ];
}

class StorageActions extends StatelessWidget {
  const StorageActions(
      {Key? key, required this.storageFile, required this.writeController})
      : super(key: key);

  final BiometricStorageFile storageFile;
  final TextEditingController writeController;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        RaisedButton(
          child: const Text('read'),
          onPressed: () async {
            _logger.fine('reading from ${storageFile.name}');
            final result = await storageFile.read();
            _logger.fine('read: {$result}');
          },
        ),
        RaisedButton(
          child: const Text('write'),
          onPressed: () async {
            _logger.fine('Going to write...');
            await storageFile
                .write(' [${DateTime.now()}] ${writeController.text}');
            _logger.info('Written content.');
          },
        ),
        RaisedButton(
          child: const Text('delete'),
          onPressed: () async {
            _logger.fine('deleting...');
            await storageFile.delete();
            _logger.info('Deleted.');
          },
        ),
      ],
    );
  }
}
