import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/playlist/playlistDetails.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:provider/provider.dart';

class PlaylistBottomBarScreen extends StatelessWidget {
  const PlaylistBottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaylistProvider>(
      builder: (context, playlistProvider, child) {
        if (playlistProvider.currentSong == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          height: 60,
          color: Colors.grey[900],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<dynamic>(
                future: playlistProvider.getArtwork(playlistProvider.currentSong!.id),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    );
                  } else {
                    return Image.asset(
                      'assets/song.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    );
                  }
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  playlistProvider.currentSong?.title ?? 'No Song Playing',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => playlistProvider.playPreviousSongFromPlaylist(),
                  ),
                  IconButton(
                    icon: Icon(
                      playlistProvider.audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
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
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => playlistProvider.playNextSongFromPlaylist(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.music_note, color: Colors.white),
                    onPressed: () {
                      Get.to(PlaylistDetailsScreen(song: playlistProvider.currentSong!));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
