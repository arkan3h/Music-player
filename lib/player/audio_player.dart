// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../helper/audio_service_helper.dart';
import '../widgets/animated_text.dart';
import '../widgets/seek_bar.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});
  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final PanelController _panelController = PanelController();
  final AudioPlayerHandler audioHandler = GetIt.I<AudioPlayerHandler>();

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: const Key('playScreen'),
        direction: DismissDirection.down,
        onDismissed: (direction) {
          Navigator.pop(context);
        },
        child: StreamBuilder<MediaItem?>(
          stream: audioHandler.mediaItem,
          builder: (context, snapshot) {
            final MediaItem? mediaItem = snapshot.data;
            if (mediaItem == null) return const SizedBox();
            final offline =
                !mediaItem.extras!['url'].toString().startsWith('http');
            return SafeArea(
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: const Color.fromARGB(255, 239, 247, 251),
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.expand_more_rounded),
                    tooltip: 'Kembali',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    PopupMenuButton(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(15.0),
                          ),
                        ),
                        onSelected: (int? value) {
                          if (value == 10) {
                            showSongInfo(mediaItem, context);
                          }
                        },
                        itemBuilder: (context) => offline
                            ? [
                                PopupMenuItem(
                                  value: 10,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      const SizedBox(width: 10.0),
                                      const Text(
                                        'Info Lagu',
                                      ),
                                    ],
                                  ),
                                ),
                              ]
                            : [
                                PopupMenuItem(
                                  value: 10,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_rounded,
                                        color:
                                            Theme.of(context).iconTheme.color,
                                      ),
                                      const SizedBox(width: 10.0),
                                      const Text(
                                        'Info Lagu',
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                  ],
                ),
                body: LayoutBuilder(
                  builder: (
                    BuildContext context,
                    BoxConstraints constraints,
                  ) {
                    if (constraints.maxWidth > constraints.maxHeight) {
                      return Container(
                        color: const Color.fromARGB(255, 239, 247, 251),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Artwork
                            ArtWorkWidget(
                              mediaItem: mediaItem,
                              width: min(
                                constraints.maxHeight / 0.9,
                                constraints.maxWidth / 1.8,
                              ),
                              audioHandler: audioHandler,
                              offline: offline,
                            ),
                        
                            // title and controls
                            NameNControls(
                              mediaItem: mediaItem,
                              offline: offline,
                              width: constraints.maxWidth / 2,
                              height: constraints.maxHeight,
                              panelController: _panelController,
                              audioHandler: audioHandler,
                            ),
                            NextSong(
                              mediaItem: mediaItem,
                              offline: offline,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              panelController: _panelController,
                              audioHandler: audioHandler,
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      color: const Color.fromARGB(255, 239, 247, 251),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              // Artwork
                              ArtWorkWidget(
                                mediaItem: mediaItem,
                                width: constraints.maxWidth,
                                audioHandler: audioHandler,
                                offline: offline,
                              ),
                              // title and controls
                              NameNControls(
                                mediaItem: mediaItem,
                                offline: offline,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight -
                                    (constraints.maxWidth * 0.85),
                                panelController: _panelController,
                                audioHandler: audioHandler,
                              ),
                            ],
                          ),
                          NextSong(
                            mediaItem: mediaItem,
                            offline: offline,
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            panelController: _panelController,
                            audioHandler: audioHandler,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ));
  }
}

abstract class AudioPlayerHandler implements AudioHandler {
  Stream<QueueState> get queueState;
  Future<void> moveQueueItem(int currentIndex, int newIndex);
  ValueStream<double> get volume;
  Future<void> setVolume(double volume);
  ValueStream<double> get speed;
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class QueueState {
  static const QueueState empty =
      QueueState([], 0, [], AudioServiceRepeatMode.none);

  final List<MediaItem> queue;
  final int? queueIndex;
  final List<int>? shuffleIndices;
  final AudioServiceRepeatMode repeatMode;

  const QueueState(
    this.queue,
    this.queueIndex,
    this.shuffleIndices,
    this.repeatMode,
  );

  bool get hasPrevious =>
      repeatMode != AudioServiceRepeatMode.none || (queueIndex ?? 0) > 0;
  bool get hasNext =>
      repeatMode != AudioServiceRepeatMode.none ||
      (queueIndex ?? 0) + 1 < queue.length;

  List<int> get indices =>
      shuffleIndices ?? List.generate(queue.length, (i) => i);
}

class ControlButtons extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final bool shuffle;
  final bool miniplayer;
  final List buttons;
  final Color? dominantColor;

  const ControlButtons(
    this.audioHandler, {
    super.key,
    this.shuffle = false,
    this.miniplayer = false,
    this.buttons = const ['Previous', 'Play/Pause', 'Next'],
    this.dominantColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.min,
      children: buttons.map((e) {
        switch (e) {
          case 'Previous':
            return StreamBuilder<QueueState>(
              stream: audioHandler.queueState,
              builder: (context, snapshot) {
                final queueState = snapshot.data;
                final resetOnSkip = Hive.box('settings')
                    .get('resetOnSkip', defaultValue: false) as bool;
                return IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: miniplayer ? 24.0 : 45.0,
                  tooltip: 'Lewati Sebelumnya',
                  color: dominantColor ?? Theme.of(context).iconTheme.color,
                  onPressed: ((queueState?.hasPrevious ?? true) || resetOnSkip)
                      ? audioHandler.skipToPrevious
                      : null,
                );
              },
            );
          case 'Play/Pause':
            return SizedBox(
              height: miniplayer ? 40.0 : 65.0,
              width: miniplayer ? 40.0 : 65.0,
              child: StreamBuilder<PlaybackState>(
                stream: audioHandler.playbackState,
                builder: (context, snapshot) {
                  final playbackState = snapshot.data;
                  final processingState = playbackState?.processingState;
                  final playing = playbackState?.playing ?? true;
                  return Stack(
                    children: [
                      if (processingState == AudioProcessingState.loading ||
                          processingState == AudioProcessingState.buffering)
                        Center(
                          child: SizedBox(
                            height: miniplayer ? 40.0 : 65.0,
                            width: miniplayer ? 40.0 : 65.0,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).iconTheme.color!,
                              ),
                            ),
                          ),
                        ),
                      if (miniplayer)
                        Center(
                          child: playing
                              ? IconButton(
                                  tooltip: 'Jeda',
                                  onPressed: audioHandler.pause,
                                  icon: const Icon(
                                    Icons.pause_rounded,
                                  ),
                                  color: Theme.of(context).iconTheme.color,
                                )
                              : IconButton(
                                  tooltip: 'Putar',
                                  onPressed: audioHandler.play,
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                  ),
                                  color: Theme.of(context).iconTheme.color,
                                ),
                        )
                      else
                        Center(
                          child: SizedBox(
                            height: 59,
                            width: 59,
                            child: Center(
                              child: playing
                                  ? FloatingActionButton(
                                      elevation: 5,
                                      tooltip: 'Jeda',
                                      backgroundColor: Colors.white,
                                      onPressed: audioHandler.pause,
                                      child: const Icon(
                                        Icons.pause_rounded,
                                        size: 40.0,
                                        color: Colors.black,
                                      ),
                                    )
                                  : FloatingActionButton(
                                      elevation: 5,
                                      tooltip: 'Putar',
                                      backgroundColor: Colors.white,
                                      onPressed: audioHandler.play,
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 40.0,
                                        color: Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            );
          case 'Next':
            return StreamBuilder<QueueState>(
              stream: audioHandler.queueState,
              builder: (context, snapshot) {
                final queueState = snapshot.data;
                return IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: miniplayer ? 24.0 : 45.0,
                  tooltip: 'Lewati Berikutnya',
                  color: dominantColor ?? Theme.of(context).iconTheme.color,
                  onPressed: queueState?.hasNext ?? true
                      ? audioHandler.skipToNext
                      : null,
                );
              },
            );
          default:
            break;
        }
        return const SizedBox();
      }).toList(),
    );
  }
}

class NowPlayingStream extends StatelessWidget {
  final AudioPlayerHandler audioHandler;
  final ScrollController? scrollController;
  final PanelController? panelController;
  final bool head;
  final double headHeight;

  const NowPlayingStream({
    super.key,
    required this.audioHandler,
    this.scrollController,
    this.panelController,
    this.head = false,
    this.headHeight = 50,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QueueState>(
      stream: audioHandler.queueState,
      builder: (context, snapshot) {
        final queueState = snapshot.data ?? QueueState.empty;
        final queue = queueState.queue;
        final int queueStateIndex = queueState.queueIndex ?? 0;

        return ReorderableListView.builder(
          header: SizedBox(
            height: head ? headHeight : 0,
          ),
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) {
              newIndex--;
            }
            audioHandler.moveQueueItem(
              queueStateIndex + oldIndex,
              queueStateIndex + newIndex,
            );
          },
          scrollController: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 10),
          shrinkWrap: true,
          itemCount: queue.length - queueStateIndex,
          itemBuilder: (context, index) {
            return Dismissible(
              key: ValueKey(
                '${queue[queueStateIndex + index].id}#${queueStateIndex + index}',
              ),
              direction: (queueStateIndex + index) == queueState.queueIndex
                  ? DismissDirection.none
                  : DismissDirection.horizontal,
              onDismissed: (dir) {
                audioHandler.removeQueueItemAt(queueStateIndex + index);
              },
              child: ListTileTheme(
                selectedColor: Theme.of(context).colorScheme.secondary,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.only(left: 16.0, right: 10.0),
                  selected: queueStateIndex + index == queueState.queueIndex,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: (queueStateIndex + index == queueState.queueIndex)
                        ? [
                            IconButton(
                              icon: const Icon(
                                Icons.bar_chart_rounded,
                              ),
                              tooltip: 'Memutar',
                              onPressed: () {},
                            ),
                          ]
                        : [
                            ReorderableDragStartListener(
                              key: Key(
                                '${queue[queueStateIndex + index].id}#${queueStateIndex + index}',
                              ),
                              index: index,
                              enabled: (queueStateIndex + index) !=
                                  queueState.queueIndex,
                              child: const Icon(Icons.drag_handle_rounded),
                            ),
                          ],
                  ),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (queue[queueStateIndex + index]
                              .extras?['addedByAutoplay'] as bool? ??
                          false)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    'Ditambahkan oleh',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 5.0,
                                    ),
                                  ),
                                ),
                                RotatedBox(
                                  quarterTurns: 3,
                                  child: Text(
                                    'Putar otomatis',
                                    textAlign: TextAlign.start,
                                    style: TextStyle(
                                      fontSize: 8.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 5.0,
                            ),
                          ],
                        ),
                      Card(
                        elevation: 5,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: (queue[queueStateIndex + index].artUri == null)
                            ? const SizedBox.square(
                                dimension: 50,
                                child: Image(
                                  image: AssetImage('assets/cover.jpg'),
                                ),
                              )
                            : SizedBox.square(
                                dimension: 50,
                                child: Image(
                                  fit: BoxFit.cover,
                                  errorBuilder: (
                                    BuildContext context,
                                    Object exception,
                                    StackTrace? stackTrace,
                                  ) {
                                    return const Image(
                                      fit: BoxFit.cover,
                                      image: AssetImage('assets/cover.jpg'),
                                    );
                                  },
                                  image: FileImage(
                                    File(
                                      queue[queueStateIndex + index]
                                          .artUri!
                                          .toFilePath(),
                                    ),
                                  ),
                                )),
                      ),
                    ],
                  ),
                  title: Text(
                    queue[queueStateIndex + index].title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          queueStateIndex + index == queueState.queueIndex
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    queue[queueStateIndex + index].artist!,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    audioHandler.skipToQueueItem(queueStateIndex + index);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ArtWorkWidget extends StatefulWidget {
  final MediaItem mediaItem;
  final bool offline;
  final double width;
  final AudioPlayerHandler audioHandler;

  const ArtWorkWidget({
    super.key,
    required this.mediaItem,
    required this.width,
    this.offline = false,
    required this.audioHandler,
  });

  @override
  _ArtWorkWidgetState createState() => _ArtWorkWidgetState();
}

class _ArtWorkWidgetState extends State<ArtWorkWidget> {
  final ValueNotifier<bool> tapped = ValueNotifier<bool>(false);
  final ValueNotifier<bool> done = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.width * 0.85,
      width: widget.width * 0.85,
      child: Hero(
        tag: 'currentArtwork',
        child: StreamBuilder<QueueState>(
          stream: widget.audioHandler.queueState,
          builder: (context, snapshot) {
            final bool enabled = Hive.box('settings')
                .get('enableGesture', defaultValue: true) as bool;
            return GestureDetector(
              onTap: () {
                if (enabled) {
                  tapped.value = true;
                  Future.delayed(const Duration(seconds: 2), () async {
                    tapped.value = false;
                  });
                  Feedback.forTap(context);
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Card(
                      elevation: 10.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image(
                        fit: BoxFit.contain,
                        width: widget.width * 0.85,
                        gaplessPlayback: true,
                        errorBuilder: (
                          BuildContext context,
                          Object exception,
                          StackTrace? stackTrace,
                        ) {
                          return Image(
                            fit: BoxFit.cover,
                            width: widget.width * 0.85,
                            image: const AssetImage('assets/cover.jpg'),
                          );
                        },
                        image: FileImage(
                          File(
                            widget.mediaItem.artUri!.toFilePath(),
                          ),
                        ),
                      )),
                  ValueListenableBuilder(
                    valueListenable: tapped,
                    child: GestureDetector(
                      onTap: () {
                        tapped.value = false;
                      },
                      child: Card(
                        color: Colors.black26,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.black.withOpacity(0.2),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: IconButton(
                                    tooltip: 'Info Lagu',
                                    onPressed: () {
                                      showSongInfo(
                                        widget.mediaItem,
                                        context,
                                      );
                                    },
                                    icon: const Icon(Icons.info_rounded),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    builder: (context, bool value, Widget? child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Visibility(visible: value, child: child!),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class NameNControls extends StatelessWidget {
  final MediaItem mediaItem;
  final bool offline;
  final double width;
  final double height;
  final PanelController panelController;
  final AudioPlayerHandler audioHandler;

  const NameNControls({
    super.key,
    required this.width,
    required this.height,
    required this.mediaItem,
    required this.audioHandler,
    required this.panelController,
    this.offline = false,
  });

  Stream<Duration> get _bufferedPositionStream => audioHandler.playbackState
      .map((state) => state.bufferedPosition)
      .distinct();
  Stream<Duration?> get _durationStream =>
      audioHandler.mediaItem.map((item) => item?.duration).distinct();
  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        AudioService.position,
        _bufferedPositionStream,
        _durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  Widget build(BuildContext context) {
    final double titleBoxHeight = height * 0.25;
    final double seekBoxHeight = height > 500 ? height * 0.15 : height * 0.21;
    final double controlBoxHeight = offline
        ? height > 500
            ? height * 0.2
            : height * 0.25
        : (height < 350
            ? height * 0.4
            : height > 500
                ? height * 0.2
                : height * 0.3);
    return SizedBox(
      child: Stack(
        children: [
          Column(
            children: [
              /// Title and subtitle
              SizedBox(
                height: titleBoxHeight,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.07),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: titleBoxHeight / 10,
                        ),
                        /// Title container
                        AnimatedText(
                          text: mediaItem.title
                              // .split(' (')[0]
                              // .split('|')[0]
                              .trim(),
                          pauseAfterRound: const Duration(seconds: 3),
                          showFadingOnlyWhenScrolling: false,
                          fadingEdgeEndFraction: 0.05,
                          fadingEdgeStartFraction: 0.05,
                          startAfter: const Duration(seconds: 2),
                          style: TextStyle(
                            fontSize: titleBoxHeight / 2.75,
                            fontWeight: FontWeight.bold,
                            // color: Theme.of(context).accentColor,
                          ),
                        ),
                        SizedBox(
                          height: titleBoxHeight / 40,
                        ),
                        /// Subtitle container
                        AnimatedText(
                          text: ((mediaItem.album ?? '').isEmpty ||
                                  ((mediaItem.album ?? '') ==
                                      (mediaItem.artist ?? '')))
                              ? '${(mediaItem.artist ?? "").isEmpty ? "Unknown" : mediaItem.artist}'
                              : '${(mediaItem.artist ?? "").isEmpty ? "Unknown" : mediaItem.artist} • ${mediaItem.album}',
                          pauseAfterRound: const Duration(seconds: 3),
                          showFadingOnlyWhenScrolling: false,
                          fadingEdgeEndFraction: 0.05,
                          fadingEdgeStartFraction: 0.05,
                          startAfter: const Duration(seconds: 2),
                          style: TextStyle(
                            fontSize: titleBoxHeight / 6.75,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              /// Seekbar starts from here
              SizedBox(
                height: seekBoxHeight,
                width: width * 0.95,
                child: StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data ??
                        PositionData(
                          Duration.zero,
                          Duration.zero,
                          mediaItem.duration ?? Duration.zero,
                        );
                    return SeekBar(
                      // width: width,
                      // height: height,
                      duration: positionData.duration,
                      position: positionData.position,
                      bufferedPosition: positionData.bufferedPosition,
                      offline: offline,
                      onChangeEnd: (newPosition) {
                        audioHandler.seek(newPosition);
                      },
                      audioHandler: audioHandler,
                    );
                  },
                ),
              ),
              /// Final row starts from here
              SizedBox(
                height: controlBoxHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Center(
                    child: SizedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 6.0),
                              StreamBuilder<bool>(
                                stream: audioHandler.playbackState
                                    .map(
                                      (state) =>
                                          state.shuffleMode ==
                                          AudioServiceShuffleMode.all,
                                    )
                                    .distinct(),
                                builder: (context, snapshot) {
                                  final shuffleModeEnabled =
                                      snapshot.data ?? false;
                                  return IconButton(
                                    icon: shuffleModeEnabled
                                        ? const Icon(
                                            Icons.shuffle_rounded,
                                          )
                                        : Icon(
                                            Icons.shuffle_rounded,
                                            color:
                                                Theme.of(context).disabledColor,
                                          ),
                                    tooltip: 'Acak',
                                    onPressed: () async {
                                      final enable = !shuffleModeEnabled;
                                      await audioHandler.setShuffleMode(
                                        enable
                                            ? AudioServiceShuffleMode.all
                                            : AudioServiceShuffleMode.none,
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          ControlButtons(
                            audioHandler,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 6.0),
                              StreamBuilder<AudioServiceRepeatMode>(
                                stream: audioHandler.playbackState
                                    .map((state) => state.repeatMode)
                                    .distinct(),
                                builder: (context, snapshot) {
                                  final repeatMode = snapshot.data ??
                                      AudioServiceRepeatMode.none;
                                  const texts = ['None', 'All', 'One'];
                                  final icons = [
                                    Icon(
                                      Icons.repeat_rounded,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                    const Icon(
                                      Icons.repeat_rounded,
                                    ),
                                    const Icon(
                                      Icons.repeat_one_rounded,
                                    ),
                                  ];
                                  const cycleModes = [
                                    AudioServiceRepeatMode.none,
                                    AudioServiceRepeatMode.all,
                                    AudioServiceRepeatMode.one,
                                  ];
                                  final index = cycleModes.indexOf(repeatMode);
                                  return IconButton(
                                    icon: icons[index],
                                    tooltip:
                                        'Repeat ${texts[(index + 1) % texts.length]}',
                                    onPressed: () async {
                                      await Hive.box('settings').put(
                                        'repeatMode',
                                        texts[(index + 1) % texts.length],
                                      );
                                      await audioHandler.setRepeatMode(
                                        cycleModes[
                                            (cycleModes.indexOf(repeatMode) +
                                                    1) %
                                                cycleModes.length],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NextSong extends StatelessWidget {
  final MediaItem mediaItem;
  final bool offline;
  final double width;
  final double height;
  final PanelController panelController;
  final AudioPlayerHandler audioHandler;

  const NextSong({
    super.key,
    required this.width,
    required this.height,
    required this.mediaItem,
    required this.audioHandler,
    required this.panelController,
    this.offline = false,
  });

  @override
  Widget build(BuildContext context) {
    final double nowplayingBoxHeight = min(70, height * 0.2);
    return SlidingUpPanel(
            minHeight: nowplayingBoxHeight,
            maxHeight: 500,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15.0),
              topRight: Radius.circular(15.0),
            ),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, .25), 
                blurRadius: 2.0
              )
            ],
            controller: panelController,
            panelBuilder: (ScrollController scrollController) {
              return Container(
                color: Theme.of(context).colorScheme.background,
                child: NowPlayingStream(
                  head: true,
                  headHeight: nowplayingBoxHeight,
                  audioHandler: audioHandler,
                  scrollController: scrollController,
                  panelController: panelController,
                ),
              );
            },
            header: GestureDetector(
              onTap: () {
                if (panelController.isPanelOpen) {
                  panelController.close();
                } else {
                  if (panelController.panelPosition > 0.9) {
                    panelController.close();
                  } else {
                    panelController.open();
                  }
                }
              },
              onVerticalDragUpdate: (DragUpdateDetails details) {
                if (details.delta.dy > 0.0) {
                  panelController.animatePanelToPosition(0.0);
                }
              },
              child: Container(
                height: nowplayingBoxHeight,
                width: width,
                color: Theme.of(context).colorScheme.background,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: Container(
                        width: 30,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Berikutnya',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                  ],
                ),
              ),
            ),
            color: Colors.indigo.shade700,
          );
  }
}