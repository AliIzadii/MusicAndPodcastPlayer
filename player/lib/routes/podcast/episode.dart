import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/podcast/podcastDetails.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:player/routes/podcast/podcastSearch.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EpisodeScreen extends StatefulWidget {
  final String podcastId;
  final QuerySnapshot episodeId;

  const EpisodeScreen({
    super.key,
    required this.podcastId,
    required this.episodeId,
  });

  @override
  State<EpisodeScreen> createState() => _EpisodeScreenState();
}

class _EpisodeScreenState extends State<EpisodeScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<PodcastProvider>(context, listen: false)
        .loadEpisods(widget.podcastId);
  }

  @override
  Widget build(BuildContext context) {
    var podcastProvider = Provider.of<PodcastProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Episods'),
        actions: [
          IconButton(
            onPressed: () {
              Get.to(const PodcastSearchScreen());
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('podcast')
            .doc(widget.podcastId)
            .collection('episode')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var episodes = snapshot.data!.docs;

          if (episodes.isEmpty) {
            return const Center(
                child: Text('No podcasts available for this podcast'));
          }

          return ListView.builder(
            itemCount: episodes.length,
            itemBuilder: (context, index) {
              var episode = episodes[index].data() as Map<String, dynamic>;
              var imageUrl = episode['imageUrl'];

              return ListTile(
                leading: Image.network(
                  imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return Image.asset(
                      'assets/podcast.jpg',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    );
                  },
                ),
                title: Text(episode['title'] ?? 'No title available'),
                subtitle: Text(episode['artist'] ?? 'Unknown'),
                onTap: () {
                  podcastProvider.playPodcastHelper(
                      episode, widget.podcastId, widget.episodeId);
                  Get.to(PodcastDetailsScreen(
                      podcast: podcastProvider.currentEpisode!));
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
