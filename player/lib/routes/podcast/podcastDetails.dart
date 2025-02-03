import 'package:flutter/material.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';

class PodcastDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> podcast;
  final bool isFromTop10Episodes;

  const PodcastDetailsScreen(
      {super.key, required this.podcast, this.isFromTop10Episodes = false});

  @override
  _PodcastDetailsScreenState createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  bool isDownloading = false;
  double downloadProgress = 0.0;
  String? downloadedFilePath;

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    var podcastProvider = Provider.of<PodcastProvider>(context);
    final downloadProvider = Provider.of<PodcastProvider>(context);
    var podcastUrl = widget.podcast['audioUrl'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          podcastProvider.currentTitle ?? 'No Title',
        ),
      ),
      body: Column(
        children: [
          Image.network(
            podcastProvider.currentImageUrl!,
            width: 300,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return Image.asset(
                'assets/podcast.jpg',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            podcastProvider.currentTitle ?? 'No Title',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            podcastProvider.currentArtist ?? 'Unknown',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(podcastProvider.currentEpisode?['description'] ??
              'No Description'),
          const SizedBox(height: 16),
          Column(
            children: [
              Slider(
                value: podcastProvider.currentPosition.inSeconds.toDouble(),
                min: 0.0,
                max: podcastProvider.duration.inSeconds.toDouble(),
                onChanged: (value) {
                  podcastProvider.audioPlayer
                      .seek(Duration(seconds: value.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDuration(podcastProvider.currentPosition),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    formatDuration(podcastProvider.duration),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: () async {
                      widget.isFromTop10Episodes
                          ? await podcastProvider.playPreviousEpisodeFromTop10()
                          : await podcastProvider.playPreviousPodcast();
                      setState(() {});
                    },
                  ),
                  IconButton(
                    icon: Icon(podcastProvider.audioPlayer.playing
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () {
                      if (podcastProvider.audioPlayer.playing) {
                        podcastProvider.pause();
                      } else {
                        podcastProvider.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: () async {
                      widget.isFromTop10Episodes
                          ? await podcastProvider.playNextEpisodeFromTop10()
                          : await podcastProvider.playNextPodcast();
                      setState(() {}); 
                    },
                  ),
                  DropdownButton<double>(
                    value: podcastProvider.audioPlayer.speed,
                    items: [1.0, 1.5, 1.8, 2.0].map((speed) {
                      return DropdownMenuItem<double>(
                        value: speed,
                        child: Text('${speed}x'),
                      );
                    }).toList(),
                    onChanged: (speed) {
                      if (speed != null) {
                        podcastProvider.setSpeed(speed);
                      }
                    },
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          downloadProvider.isDownloading &&
                                  downloadProvider.downloadingPodcastUrl ==
                                      podcastUrl
                              ? Column(
                                  children: [
                                    CircularProgressIndicator(
                                      value: downloadProvider.downloadProgress,
                                      strokeWidth: 8.0,
                                    ),
                                    Text(
                                      '${(downloadProvider.downloadProgress * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(fontSize: 20.0),
                                    ),
                                  ],
                                )
                              : ElevatedButton.icon(
                                  onPressed: () {
                                    downloadProvider.downloadPodcast(
                                        podcastProvider
                                            .currentEpisode?['audioUrl'],
                                        podcastProvider
                                            .currentEpisode?['title']);
                                  },
                                  icon: const Icon(Icons.download),
                                  label: const Text("Download"),
                                ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
