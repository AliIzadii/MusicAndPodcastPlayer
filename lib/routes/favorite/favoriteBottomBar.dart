import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/favorite/favoriteDetail.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:provider/provider.dart';

class FavoriteBottomBarScreen extends StatelessWidget {
  const FavoriteBottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        if (favoriteProvider.currentSong == null) {
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
                future: favoriteProvider.getArtwork(favoriteProvider.currentSong!.id),
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
                  favoriteProvider.currentSong?.title ?? 'No Song Playing',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => favoriteProvider.playPreviousSongFromFavorite(),
                  ),
                  IconButton(
                    icon: Icon(
                      favoriteProvider.audioPlayer.playing ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
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
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => favoriteProvider.playNextSongFromFavorite(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.music_note, color: Colors.white),
                    onPressed: () {
                      Get.to(FavoriteDetailsScreen(song: favoriteProvider.currentSong!));
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
