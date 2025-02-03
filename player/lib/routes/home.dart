import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:player/routes/combinedBottomBar.dart';
import 'package:player/routes/music/music.dart';
import 'package:player/routes/podcast/languageSelection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: () {
                Get.to(const LanguageSelectionScreen());
              },
              icon: const Icon(
                Icons.podcasts_outlined,
                size: 50,
              ),
            ),
            IconButton(
              onPressed: () {
                Get.to(const MusicScreen());
              },
              icon: const Icon(
                Icons.music_note,
                size: 50,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CombinedBottomBarScreen(),
    );
  }
}
