import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:provider/provider.dart';

class PlaylistDetailsScreen extends StatelessWidget {
  final SongModel song;

  const PlaylistDetailsScreen({super.key, required this.song});

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    var playlistProvider = Provider.of<PlaylistProvider>(context);
    final currentSong = playlistProvider.currentSong;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong!.title),
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<dynamic>(
                future: playlistProvider.getArtwork(currentSong.id),
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
                value: playlistProvider.currentPosition.inSeconds.toDouble(),
                min: 0.0,
                max: playlistProvider.duration.inSeconds.toDouble(),
                onChanged: (value) {
                  playlistProvider.audioPlayer
                      .seek(Duration(seconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(playlistProvider.currentPosition),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    formatDuration(playlistProvider.duration),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () {
                      playlistProvider.playPreviousSongFromPlaylist();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      playlistProvider.audioPlayer.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      if (playlistProvider.audioPlayer.playing) {
                        playlistProvider.pause();
                      } else {
                        playlistProvider.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      playlistProvider.playNextSongFromPlaylist();
                    },
                  ),
                  DropdownButton<double>(
                    value: playlistProvider.audioPlayer.speed,
                    items: [1.0, 1.5, 1.8, 2.0].map((speed) {
                      return DropdownMenuItem<double>(
                        value: speed,
                        child: Text('${speed}x'),
                      );
                    }).toList(),
                    onChanged: (speed) {
                      if (speed != null) {
                        playlistProvider.setSpeed(speed);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          playlistProvider.playMode == PlayMode.shuffle
                              ? Icons.shuffle
                              : playlistProvider.playMode == PlayMode.repeat
                                  ? Icons.replay
                                  : playlistProvider.playMode == PlayMode.normal
                                      ? Icons.repeat
                                      : Icons.repeat_one,
                        ),
                        onPressed: () {
                          playlistProvider.switchPlayMode();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
