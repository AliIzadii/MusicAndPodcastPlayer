import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:player/routes/home.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void showCompleteNotification(String fileName) {
  var android = const AndroidNotificationDetails(
    'channel id',
    'channel name',
    importance: Importance.max,
    priority: Priority.high,
  );
  var platform = NotificationDetails(android: android);

  flutterLocalNotificationsPlugin.show(
    0,
    'Download Complete',
    '$fileName has been successfully downloaded.',
    platform,
  );
}

Future<void> main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',     
    androidNotificationOngoing: false,
    androidStopForegroundOnPause: false,
    androidNotificationIcon: "drawable/ic_music",
  );
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await FlutterDownloader.initialize(
    debug: true,
    ignoreSsl: true,
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('drawable/ic_music');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  await Permission.notification.request();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PodcastProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => PlaylistProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(() => MusicProvider());
    Get.lazyPut(() => PodcastProvider());

    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Podcast App',
      home: HomeScreen(),
    );
  }
}
