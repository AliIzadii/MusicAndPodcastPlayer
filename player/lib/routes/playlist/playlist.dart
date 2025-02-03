import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/playlist/platlistClass.dart';
import 'package:player/routes/playlist/playlistDetails.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class PlaylistScreen extends StatelessWidget {
  final Playlist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  void _shareSong(SongModel song) async {
    try {
      final filePath = song.data;

      final file = File(filePath);

      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)],
            text: '${song.title} by ${song.artist}');
      }
    } catch (e) {}
  }

  void _showOptionsMenu(
      BuildContext context, SongModel song, Playlist playlist) {
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () {
              _shareSong(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              playlistProvider.removeSongFromPlaylist(song, playlist);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playlist.name),
      ),
      body: Consumer3<PlaylistProvider, FavoriteProvider, MusicProvider>(
        builder: (context, playlistProvider, favoriteProvider, musicProvider,
            child) {
          final songs = playlist.songs;

          if (songs.isEmpty) {
            return const Center(child: Text('No Songs in this Playlist'));
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              final isPlaying = song.id == favoriteProvider.currentSong?.id ||
                  song.id == musicProvider.currentSong?.id ||
                  song.id == playlistProvider.currentSong?.id;

              return ListTile(
                title: Text(
                  song.title,
                  style: TextStyle(
                    color: isPlaying ? Colors.blue : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist ?? 'Unknown Artist',
                  style: TextStyle(
                    color: isPlaying ? Colors.blue : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: FutureBuilder<dynamic>(
                  future: playlistProvider.getArtwork(song.id),
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
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
                      );
                    }
                  },
                ),
                onTap: () {
                  playlistProvider.playSongFromPlaylist(song, playlist);
                  Get.to(PlaylistDetailsScreen(song: song));
                },
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptionsMenu(context, song, playlist),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CombinedBottomBarScreen(),
    );
  }
}
