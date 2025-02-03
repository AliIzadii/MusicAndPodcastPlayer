import 'package:flutter/material.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:provider/provider.dart';

class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  _MusicSearchScreenState createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final musicProvider = Provider.of<MusicProvider>(context);
    List filteredSongs = musicProvider.songs.where((song) {
      return song.title.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
          song.artist!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: _buildSearchField(),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty) ...[
            Expanded(
              child: ListView.builder(
                itemCount: filteredSongs.length,
                itemBuilder: (context, index) {
                  final songTitle = filteredSongs[index].title;
                  final songArtist = filteredSongs[index].artist ?? '';

                  return ListTile(
                    title: _highlightText(songTitle, _searchQuery),
                    subtitle: _highlightText(songArtist, _searchQuery),
                    leading: FutureBuilder<dynamic>(
                      future: musicProvider.getArtwork(filteredSongs[index].id),
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
                      musicProvider.playSong(filteredSongs[index]);
                    },
                  );
                },
              ),
            ),
          ] else ...[
            Container()
          ]
        ],
      ),
      bottomNavigationBar: const CombinedBottomBarScreen(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
      ),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text);
    } else {
      final matches = text.toLowerCase().split(query.toLowerCase());
      final spans = <TextSpan>[];

      int startIndex = 0;
      for (int i = 0; i < matches.length; i++) {
        final match = matches[i];
        spans.add(TextSpan(
          text: text.substring(startIndex, startIndex + match.length),
          style: const TextStyle(color: Colors.black), 
        ));
        startIndex += match.length;
        if (i < matches.length - 1) {
          spans.add(TextSpan(
            text: text.substring(startIndex, startIndex + query.length),
            style: const TextStyle(color: Colors.blue), 
          ));
          startIndex += query.length;
        }
      }

      return RichText(
        text: TextSpan(
          children: spans,
          style: const TextStyle(fontSize: 16),
        ),
      );
    }
  }
}
