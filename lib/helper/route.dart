import 'package:flutter/material.dart';
import 'package:music_player_app1/pages/home.dart';

final Map<String, Widget Function(BuildContext)> namedRoutes = {
  '/': (context) => const MyHomePage(),
};
