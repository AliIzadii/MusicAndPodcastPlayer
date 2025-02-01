import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/podcast/podcastDetails.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';

class TopEpisodesScreen extends StatefulWidget {
  const TopEpisodesScreen({super.key});

  @override
  State<TopEpisodesScreen> createState() => _TopEpisodesScreenState();
}

class _TopEpisodesScreenState extends State<TopEpisodesScreen> {
  Future<List<Map<String, dynamic>>>? topPodcastsFuture;

  @override
  void initState() {
    super.initState();
    final podcastProvider =
        Provider.of<PodcastProvider>(context, listen: false);
    topPodcastsFuture = podcastProvider.getTop10Episodes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Podcasts'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: topPodcastsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No top podcasts available.'));
          }

          final topPodcasts = snapshot.data!;

          return ListView.builder(
            itemCount: topPodcasts.length,
            itemBuilder: (context, index) {
              var podcastImg = topPodcasts[index];
              var imageUrl = podcastImg['imageUrl'];

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
                title: Text(podcastImg['title']),
                subtitle: Text('Plays: ${podcastImg['playCount']} times'),
                onTap: () {
                  final podcastProvider = Provider.of<PodcastProvider>(
                      context,
                      listen: false);
                  podcastProvider.playEpisodeFromTop10Section(podcastImg);
                  Get.to(PodcastDetailsScreen(
                    podcast: podcastImg,
                    isFromTop10Episodes: true,
                  ));
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
