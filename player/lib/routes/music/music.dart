import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/favorite/favorite.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:player/routes/music/musicDetails.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/music/musicSearch.dart';
import 'package:player/routes/playlist/platlistClass.dart';
import 'package:player/routes/playlist/playlistList.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
            'Permission to access storage is required to load songs.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('Go to Settings'),
          ),
        ],
      ),
    ).then((_) async {
      await Future.delayed(const Duration(seconds: 3));
      _checkPermissions();
    });
  }

  Future<void> _checkPermissions() async {
    final musicProvider =
        Provider.of<MusicProvider>(Get.context!, listen: false);
    bool permissionStatus = await _audioQuery.permissionsStatus();

    if (!permissionStatus) {
      permissionStatus = await _audioQuery.permissionsRequest();
    }

    if (permissionStatus) {
      musicProvider.loadSongs();
      musicProvider.setPermissionDenied(false);
    } else {
      musicProvider.setPermissionDenied(true);
      _showPermissionDeniedDialog();
    }
  }

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

  void _deleteSong(SongModel song) {
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    musicProvider.deleteSong(song);
    for (var playlist in playlistProvider.playlists) {
      if (playlist.songs.contains(song)) {
        playlistProvider.removeSongFromPlaylist(song, playlist);
      }
    }
  }

  Future<void> showPlaylistDialog(SongModel song, BuildContext context) {
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (context) {
        String newPlaylistName = '';

        return AlertDialog(
          title: const Text("Add to Playlist"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (playlistProvider.playlists.isNotEmpty)
                ...playlistProvider.playlists.map((playlist) {
                  return ListTile(
                    title: Text(playlist.name),
                    onTap: () {
                      playlistProvider.addSongToPlaylist(song, playlist);
                      Navigator.pop(context);
                    },
                  );
                }),
              const Divider(),
              TextField(
                decoration: const InputDecoration(
                  labelText: "New Playlist Name",
                ),
                onChanged: (value) {
                  newPlaylistName = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Create"),
              onPressed: () {
                if (newPlaylistName.isNotEmpty) {
                  bool duplicate =
                      playlistProvider.createPlaylist(newPlaylistName);
                  if (duplicate == true) {
                    Playlist newPlaylist = playlistProvider.playlists.first;
                    playlistProvider.addSongToPlaylist(song, newPlaylist);
                    Navigator.pop(context);
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showOptionsMenu(BuildContext context, SongModel song) {
    var favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
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
              _deleteSong(song);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add),
            title: const Text('Add Playlist'),
            onTap: () async {
              await showPlaylistDialog(song, context);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Add Favorite'),
            onTap: () {
              favoriteProvider.addSongToFavorite(song);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoriteProvider =
        Provider.of<FavoriteProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(const MusicSearchScreen());
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              Get.to(const PlaylistListScreen());
            },
            icon: const Icon(Icons.playlist_add_check),
          ),
          IconButton(
            onPressed: () {
              favoriteProvider.load();
              Get.to(const FavoriteScreen());
            },
            icon: const Icon(Icons.favorite),
          ),
        ],
      ),
      body: Consumer3<MusicProvider, PlaylistProvider, FavoriteProvider>(
        builder: (context, musicProvider, playlistProvider, favoriteProvider,
            child) {
          if (musicProvider.permissionDenied) {
            return const Center(
                child: Text("Permission to access storage is denied."));
          }

          if (musicProvider.songs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: musicProvider.songs.length,
            itemBuilder: (context, index) {
              final song = musicProvider.songs[index];
              final isPlaying = song.id == musicProvider.currentSong?.id ||
                  song.id == playlistProvider.currentSong?.id ||
                  song.id == favoriteProvider.currentSong?.id;

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
                  future: musicProvider.getArtwork(song.id),
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
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptionsMenu(context, song),
                ),
                onTap: () async {
                  musicProvider.playSong(song);
                  Get.to(MusicDetailsScreen(song: song));
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CombinedBottomBarScreen(),
    );
  }
}
