import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:provider/provider.dart';

class MusicDetailsScreen extends StatelessWidget {
  final SongModel song;

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  const MusicDetailsScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    var musicProvider = Provider.of<MusicProvider>(context);
    final currentSong = musicProvider.currentSong;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong!.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FutureBuilder<dynamic>(
            future: musicProvider.getArtwork(currentSong.id),
            builder: (context, snapshot) {
              if (snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                );
              } else {
                return Image.asset(
                  'assets/song.png',
                  width: 250,
                  height: 250,
                );
              }
            },
          ),
          const SizedBox(height: 20),
          Text(
            currentSong.title,
            style: const TextStyle(fontSize: 24),
          ),
          Text(
            currentSong.artist ?? 'Unknown Artist',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Slider(
            value: musicProvider.currentPosition.inSeconds.toDouble(),
            min: 0.0,
            max: musicProvider.duration.inSeconds.toDouble(),
            onChanged: (value) {
              musicProvider.audioPlayer.seek(Duration(seconds: value.toInt()));
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(musicProvider.currentPosition),
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                formatDuration(musicProvider.duration),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => musicProvider.playPreviousSong(),
              ),
              IconButton(
                icon: Icon(musicProvider.audioPlayer.playing
                    ? Icons.pause
                    : Icons.play_arrow),
                onPressed: () {
                  if (musicProvider.audioPlayer.playing) {
                    musicProvider.pause();
                  } else {
                    musicProvider.resume();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => musicProvider.playNextSong(),
              ),
              DropdownButton<double>(
                value: musicProvider.audioPlayer.speed,
                items: [1.0, 1.5, 1.8, 2.0].map((speed) {
                  return DropdownMenuItem<double>(
                    value: speed,
                    child: Text('${speed}x'),
                  );
                }).toList(),
                onChanged: (speed) {
                  if (speed != null) {
                    musicProvider.setSpeed(speed);
                  }
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      musicProvider.playMode == PlayMode.shuffle
                          ? Icons.shuffle
                          : musicProvider.playMode == PlayMode.repeat
                              ? Icons.replay
                              : musicProvider.playMode == PlayMode.normal ? Icons.repeat : Icons.repeat_one,
                    ),
                    onPressed: () {
                      musicProvider.switchPlayMode();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
