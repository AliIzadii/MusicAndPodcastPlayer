import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/podcast/podcastDetails.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';

class PodcastBottomBarScreen extends StatelessWidget {
  const PodcastBottomBarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var podcastProvider = Provider.of<PodcastProvider>(context);

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Image.network(
            podcastProvider.currentImageUrl!,
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              podcastProvider.currentTitle ?? 'No Podcast Playing',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(
              podcastProvider.audioPlayer.playing
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              if (podcastProvider.audioPlayer.playing) {
                podcastProvider.pause();
              } else {
                podcastProvider.resume();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: () async {
              await podcastProvider.playNextPodcast();
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            onPressed: () async {
              await podcastProvider.playPreviousPodcast();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () {
              Get.to(PodcastDetailsScreen(
                  podcast: podcastProvider.currentEpisode!));
            },
          ),
        ],
      ),
    );
  }
}
