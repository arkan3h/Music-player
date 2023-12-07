import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:get_it/get_it.dart';
import 'package:music_player_app1/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'helper/route.dart';
import 'pages/home.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'player/audio_player.dart';
import 'provider/audio_service_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  for (final box in hiveBoxes) {
    await openHiveBox(
      box['name'].toString(),
      limit: box['limit'] as bool? ?? false,
    );
  }
  await startService();
  runApp(const MyApp());
}

Future<void> startService() async {
  final audioHandlerHelper = AudioHandlerHelper();
  final AudioPlayerHandler audioHandler = await audioHandlerHelper.getAudioHandler();
  GetIt.I.registerSingleton<AudioPlayerHandler>(audioHandler);
}

Future<void> openHiveBox(String boxName, {bool limit = false}) async {
  final box = await Hive.openBox(boxName).onError((error, stackTrace) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final String dirPath = dir.path;
    File dbFile = File('$dirPath/$boxName.hive');
    File lockFile = File('$dirPath/$boxName.lock');

    await dbFile.delete();
    await lockFile.delete();
    await Hive.openBox(boxName);
    throw 'Failed to open $boxName Box\nError: $error';
  });
  // clear box if it grows large
  if (limit && box.length > 500) {
    box.clear();
  }
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({super.key, this.savedThemeMode});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'eLagu',
        theme: theme,
        darkTheme: darkTheme,
        home: const MyHomePage(),
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/player') {
            return PageRouteBuilder(
              opaque: false,
              pageBuilder: (_, __, ___) => const PlayScreen(),
            );
          }
          return HandleRoute.handleRoute(settings.name);
        },
      ),
    );
  }
}

