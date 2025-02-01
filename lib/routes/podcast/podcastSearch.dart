import 'package:flutter/material.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';

class PodcastSearchScreen extends StatefulWidget {
  const PodcastSearchScreen({super.key});

  @override
  _PodcastSearchScreenState createState() => _PodcastSearchScreenState();
}

class _PodcastSearchScreenState extends State<PodcastSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final podcastProvider = Provider.of<PodcastProvider>(context);

    List filteredPodcasts = podcastProvider.episodeList.where((episode) {
      return episode['title']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
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
                itemCount: filteredPodcasts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(filteredPodcasts[index]['title']),
                    onTap: () {
                      podcastProvider.playPodcast(filteredPodcasts[index]);
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
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
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
}