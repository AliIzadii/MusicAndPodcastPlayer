import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/playlist/platlistClass.dart';
import 'package:player/routes/playlist/playlist.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:provider/provider.dart';

class PlaylistListScreen extends StatelessWidget {
  const PlaylistListScreen({super.key});

  void _showOptionsMenu(BuildContext context, Playlist playlist) {
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete'),
            onTap: () {
              playlistProvider.deletePlaylist(playlist);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline),
            title: const Text('Rename'),
            onTap: () async {
              await showEditPlaylistDialog(context, playlist);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> showEditPlaylistDialog(BuildContext context, Playlist playlist) {
    TextEditingController nameController =
        TextEditingController(text: playlist.name);
    final playlistProvider =
        Provider.of<PlaylistProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Playlist Name'),
          content: TextField(
            autofocus: true,
            controller: nameController,
            decoration:
                const InputDecoration(hintText: "Enter new playlist name"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                playlistProvider.editPlaylistName(
                    playlist, nameController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, playlistProvider, child) {
          if (playlistProvider.playlists.isEmpty) {
            return const Center(child: Text('No Playlists Available'));
          }

          return ListView.builder(
            itemCount: playlistProvider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlistProvider.playlists[index];
              return ListTile(
                title: Text(playlist.name),
                onTap: () {
                  Get.to(PlaylistScreen(playlist: playlist));
                },
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showOptionsMenu(context, playlist),
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
