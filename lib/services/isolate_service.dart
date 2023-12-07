import 'dart:io';
import 'dart:isolate';

import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../player/audio_player.dart';

SendPort? isolateSendPort;

Future<void> startBackgroundProcessing() async {
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  final receivePort = ReceivePort();
  await Isolate.spawn(_backgroundProcess, receivePort.sendPort);

  receivePort.listen((message) async {
    if (isolateSendPort == null) {
      isolateSendPort = message as SendPort;
      final appDocumentDirectoryPath =
          (await getApplicationDocumentsDirectory()).path;
      isolateSendPort?.send(appDocumentDirectoryPath);
    } else {
      await audioHandler.customAction('refreshLink', {'newData': message});
    }
  });
}

// The function that will run in the background Isolate
Future<void> _backgroundProcess(SendPort sendPort) async {
  final isolateReceivePort = ReceivePort();
  sendPort.send(isolateReceivePort.sendPort);
  bool hiveInit = false;

  await for (final message in isolateReceivePort) {
    if (!hiveInit) {
      String path = message.toString();
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        path += '/BlackHole/Database';
      } else if (Platform.isIOS) {
        path += '/Database';
      }
      Hive.init(path);
      await Hive.openBox('ytlinkcache');
      await Hive.openBox('settings');
      hiveInit = true;
      continue;
    }
  }
}

void addIdToBackgroundProcessingIsolate(String id) {
  isolateSendPort?.send(id);
}
