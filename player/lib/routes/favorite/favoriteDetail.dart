import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:provider/provider.dart';

class FavoriteDetailsScreen extends StatelessWidget {
  final SongModel song;

  const FavoriteDetailsScreen({super.key, required this.song});

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    var favoriteProvider = Provider.of<FavoriteProvider>(context);
    final currentSong = favoriteProvider.currentSong;
    return Scaffold(
      appBar: AppBar(
        title: Text(currentSong!.title),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder<dynamic>(
                future: favoriteProvider.getArtwork(currentSong.id),
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
                value: favoriteProvider.currentPosition.inSeconds.toDouble(),
                min: 0.0,
                max: favoriteProvider.duration.inSeconds.toDouble(),
                onChanged: (value) {
                  favoriteProvider.audioPlayer
                      .seek(Duration(seconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(favoriteProvider.currentPosition),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    formatDuration(favoriteProvider.duration),
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
                      favoriteProvider.playPreviousSongFromFavorite();
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      favoriteProvider.audioPlayer.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    onPressed: () {
                      if (favoriteProvider.audioPlayer.playing) {
                        favoriteProvider.pause();
                      } else {
                        favoriteProvider.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () {
                      favoriteProvider.playNextSongFromFavorite();
                    },
                  ),
                  DropdownButton<double>(
                    value: favoriteProvider.audioPlayer.speed,
                    items: [1.0, 1.5, 1.8, 2.0].map((speed) {
                      return DropdownMenuItem<double>(
                        value: speed,
                        child: Text('${speed}x'),
                      );
                    }).toList(),
                    onChanged: (speed) {
                      if (speed != null) {
                        favoriteProvider.setSpeed(speed);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          favoriteProvider.playMode == PlayMode.shuffle
                              ? Icons.shuffle
                              : favoriteProvider.playMode == PlayMode.repeat
                                  ? Icons.replay
                                  : favoriteProvider.playMode == PlayMode.normal
                                      ? Icons.repeat
                                      : Icons.repeat_one,
                        ),
                        onPressed: () {
                          favoriteProvider.switchPlayMode();
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
