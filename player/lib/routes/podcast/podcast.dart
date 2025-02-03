import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/podcast/episode.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:player/routes/podcast/podcastSearch.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PodcastScreen extends StatefulWidget {
  final String language;
  final String genre;

  const PodcastScreen({super.key, required this.language, required this.genre});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<PodcastProvider>(context, listen: false).loadPodcasts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Podcasts'),
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
            .where('language', isEqualTo: widget.language)
            .where('genre', isEqualTo: widget.genre)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var podcasts = snapshot.data!.docs;

          if (podcasts.isEmpty) {
            return const Center(
                child:
                    Text('No podcasts available for this genre and language.'));
          }

          return ListView.builder(
            itemCount: podcasts.length,
            itemBuilder: (context, index) {
              var podcast = podcasts[index].data() as Map<String, dynamic>;
              var imageUrl = podcast['imageUrl'];

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
                title: Text(podcast['title'] ?? 'No title available'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(podcast['artist'] ?? 'Unknown'),
                    FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('podcast')
                          .doc(snapshot.data!.docs[index].id)
                          .collection('episode')
                          .get(),
                      builder: (context,
                          AsyncSnapshot<QuerySnapshot> episodeSnapshot) {
                        if (!episodeSnapshot.hasData) {
                          return const Text('Loading episodes...');
                        }
                        int episodeCount = episodeSnapshot.data!.docs.length;
                        return episodeCount == 1
                            ? Text(
                                '${episodeSnapshot.data!.docs.length} episod',
                                style: const TextStyle(fontSize: 10),
                              )
                            : Text(
                                '${episodeSnapshot.data!.docs.length} episods',
                                style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ],
                ),
                onTap: () async {
                  QuerySnapshot snapshotEpisode = await FirebaseFirestore
                      .instance
                      .collection('podcast')
                      .doc(snapshot.data!.docs[index].id)
                      .collection('episode')
                      .orderBy('created_at', descending: true)
                      .get();
                  Get.to(EpisodeScreen(
                    podcastId: snapshot.data!.docs[index].id,
                    episodeId: snapshotEpisode,
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
