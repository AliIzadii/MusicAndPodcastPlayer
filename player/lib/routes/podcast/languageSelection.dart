import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/podcast/genreSelection.dart';
import 'package:player/routes/podcast/topPodcasts.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final List<String> languages = ['English', 'French', 'Spanish', 'German'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Language'),
        leading: IconButton(
            onPressed: () {
              Get.to(const TopEpisodesScreen());
            },
            icon: const Icon(Icons.view_compact_alt_outlined)),
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(languages[index]),
            onTap: () {
              Get.to(GenreSelectionScreen(language: languages[index]));
            },
          );
        },
      ),
      bottomNavigationBar: const CombinedBottomBarScreen(),
    );
  }
}
