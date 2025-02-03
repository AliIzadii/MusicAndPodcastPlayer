import 'package:flutter/material.dart';
import 'package:player/routes/favorite/favoriteBottomBar.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:player/routes/music/musicBottomBar.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/playlist/playlistBottomBar.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:player/routes/podcast/podcastBottomBar.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';

class CombinedBottomBarScreen extends StatelessWidget {
  const CombinedBottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<MusicProvider, PodcastProvider, PlaylistProvider, FavoriteProvider>(
      builder: (context, musicProvider, podcastProvider, playlistProvider, favoriteProvider, child) {
        if (musicProvider.currentSong != null) {
          return const MusicBottomBarScreen();
        }
        else if (podcastProvider.currentEpisode != null) {
          return const PodcastBottomBarScreen();
        }
        else if (playlistProvider.currentSong != null) {
          return const PlaylistBottomBarScreen();
        }
        else if (favoriteProvider.currentSong != null) {
          return const FavoriteBottomBarScreen();
        }
        else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
