import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../player/audio_player.dart';
import '../services/player_service.dart';
import 'audio_query.dart';

class HandleRoute {
  static Route? handleRoute(String? url) {
    if (url == null) return null;
    final RegExpMatch? fileResult = RegExp(r'\/[0-9]+\/([0-9]+)\/').firstMatch('$url/');
    if (fileResult != null) {
      return PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => OfflinePlayHandler(
          id: fileResult[1]!,
        ),
      );
    }
    return null;
  }
}

class OfflinePlayHandler extends StatelessWidget {
  final String id;
  const OfflinePlayHandler({super.key, required this.id});

  Future<List> playOfflineSong(String id) async {
    final OfflineAudioQuery offlineAudioQuery = OfflineAudioQuery();
    await offlineAudioQuery.requestPermission();

    final List<SongModel> songs = await offlineAudioQuery.getSongs();
    final int index = songs.indexWhere((i) => i.id.toString() == id);

    return [index, songs];
  }

  @override
  Widget build(BuildContext context) {
    playOfflineSong(id).then((value) {
      PlayerInvoke.init(
        songsList: value[1] as List<SongModel>,
        index: value[0] as int,
        isOffline: true,
        recommend: false,
      );
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => const PlayScreen(),
        ),
      );
    });
    return const SizedBox();
  }
}

