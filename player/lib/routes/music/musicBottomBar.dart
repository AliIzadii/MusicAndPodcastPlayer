import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/music/musicDetails.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:provider/provider.dart';


class MusicBottomBarScreen extends StatelessWidget {
  const MusicBottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, child) {
        if (musicProvider.currentSong == null) {
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
                future: musicProvider.getArtwork(musicProvider.currentSong!.id), 
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
                  musicProvider.currentSong?.title ?? 'No Song Playing',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => musicProvider.playPreviousSong(),
                  ),
                  IconButton(
                    icon: Icon(
                      musicProvider.audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (musicProvider.audioPlayer.playing) {
                        musicProvider.pause();
                      } else {
                        musicProvider.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => musicProvider.playNextSong(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.music_note, color: Colors.white),
                    onPressed: () {
                      Get.to(MusicDetailsScreen(song: musicProvider.currentSong!));
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
