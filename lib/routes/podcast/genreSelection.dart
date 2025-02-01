import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/podcast/podcast.dart';

class GenreSelectionScreen extends StatelessWidget {
  final String language;
  final List<String> genres = ['Crime', 'romantic', 'drama', 'History'];

  GenreSelectionScreen({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select a Genre for $language'),
      ),
      body: ListView.builder(
        itemCount: genres.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(genres[index]),
            onTap: () {
              Get.to(
                PodcastScreen(
                  language: language,
                  genre: genres[index],
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
