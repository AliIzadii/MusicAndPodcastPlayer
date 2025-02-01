import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:player/main.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:provider/provider.dart';

class PodcastProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic>? _currentEpisode;
  List<Map<String, dynamic>> _podcastList = [];
  List<Map<String, dynamic>> _episodeList = [];
  final List<Map<String, dynamic>> _top10EpisodesList = [];
  int _currentIndex = 0;
  Duration _currentPosition = Duration.zero;
  QuerySnapshot? episodeId;
  String? podcastId;
  double downloadProgress = 0.0;
  bool isDownloading = false;
  String? downloadingPodcastUrl;
  
  Dio dio = Dio();
  AudioPlayer get audioPlayer => _audioPlayer;
  List<Map<String, dynamic>> get podcastList => _podcastList;
  List<Map<String, dynamic>> get episodeList => _episodeList;
  Map<String, dynamic>? get currentEpisode => _currentEpisode;
  String? get currentImageUrl => _currentEpisode?['imageUrl'];
  String? get currentTitle => _currentEpisode?['title'];
  String? get currentArtist => _currentEpisode?['artist'];
  Duration get currentPosition => _currentPosition;
  int get currentIndex => _currentIndex;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;

  Future<void> loadPodcasts() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('podcast').get();

      _podcastList = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('Connection terminated during handshake') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('SocketException')) {
        Get.snackbar('NetWork Error', 'Please check your internet connection.');
      } else {
        Get.snackbar(
            'Error', 'There was an issue loading podcasts. Please try again.');
      }
    }
  }

  Future<void> loadEpisods(String podcastId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('podcast')
          .doc(podcastId)
          .collection('episode') 
          .orderBy('created_at', descending: true)
          .get();

      _episodeList = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      notifyListeners();
    } catch (e) {
      if (e.toString().contains('Connection terminated during handshake') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('SocketException')) {
        Get.snackbar('NetWork Error', 'Please check your internet connection.');
      } else {
        Get.snackbar(
            'Error', 'There was an issue loading podcasts. Please try again.');
      }
    }
  }

  void playPodcastHelper(
      Map<String, dynamic> episode, String podId, QuerySnapshot? epId) {
    episodeId = epId;
    podcastId = podId;
    playPodcast(episode);
  }

  Future<void> playPodcast(Map<String, dynamic> episode) async {
    try {
      final musicProvider =
          Provider.of<MusicProvider>(Get.context!, listen: false);
      final playlistProvider =
          Provider.of<PlaylistProvider>(Get.context!, listen: false);
      final favoriteProvider =
          Provider.of<FavoriteProvider>(Get.context!, listen: false);
      musicProvider.clearCurrentSong();
      playlistProvider.clearCurrentPlaylist();
      favoriteProvider.clearCurrentFavorite();
      await _audioPlayer.stop();

      _currentEpisode = episode;
      _currentIndex =
          _episodeList.indexWhere((episod) => episod['id'] == episode['id']);

      final AudioSource audioSource = AudioSource.uri(
        Uri.parse(episode['audioUrl']),
        tag: MediaItem(
            id: episode['id'],
            title: episode['title'],
            artist: episode['artist'],
            artUri: Uri.parse(episode['imageUrl'])),
      );
      await _audioPlayer.setAudioSource(
        audioSource,
      );

      _audioPlayer.play();
      notifyListeners(); 
      FirebaseFirestore.instance
          .collection('podcast')
          .doc(podcastId)
          .collection('episode') 
          .doc(episodeId?.docs[_currentIndex].id)
          .update({'playCount': FieldValue.increment(1)});
      _audioPlayer.processingStateStream.listen((processingState) {
        if (processingState == ProcessingState.completed) {
          playNextPodcast();
        }
      });

      _audioPlayer.positionStream.listen((position) {
        _currentPosition = position;
        notifyListeners();
      });
    } catch (e) {
      if (e.toString().contains('Connection terminated during handshake') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('SocketException')) {
        Get.snackbar('NetWork Error', 'Please check your internet connection.');
      } else {
        Get.snackbar(
            'Error', 'There was an issue loading podcasts. Please try again.');
      }
    }
  }

  Future<void> playEpisodeFromTop10Section(Map<String, dynamic> episode) async {
    try {
      final musicProvider =
          Provider.of<MusicProvider>(Get.context!, listen: false);
      final playlistProvider =
          Provider.of<PlaylistProvider>(Get.context!, listen: false);
      final favoriteProvider =
          Provider.of<FavoriteProvider>(Get.context!, listen: false);
      musicProvider.clearCurrentSong();
      playlistProvider.clearCurrentPlaylist();
      favoriteProvider.clearCurrentFavorite();
      await _audioPlayer.stop();

      _currentEpisode = episode;
      _currentIndex = _top10EpisodesList
          .indexWhere((episod) => episod['id'] == episode['id']);

      final AudioSource audioSource = AudioSource.uri(
        Uri.parse(episode['audioUrl']),
        tag: MediaItem(
            id: episode['id'],
            title: episode['title'],
            artist: episode['artist'],
            artUri: Uri.parse(episode['imageUrl'])),
      );
      await _audioPlayer.setAudioSource(
        audioSource,
      );

      _audioPlayer.play();
      notifyListeners();
      _audioPlayer.processingStateStream.listen((processingState) {
        if (processingState == ProcessingState.completed) {
          playNextEpisodeFromTop10();
        }
      });

      _audioPlayer.positionStream.listen((position) {
        _currentPosition = position;
        notifyListeners();
      });
    } catch (e) {
      if (e.toString().contains('Connection terminated during handshake') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('Network is unreachable') ||
          e.toString().contains('SocketException')) {
        Get.snackbar('NetWork Error', 'Please check your internet connection.');
      } else {
        Get.snackbar(
            'Error', 'There was an issue loading podcasts. Please try again.');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getTop10Episodes() async {
    try {
    _top10EpisodesList.clear();
      QuerySnapshot podcastSnapshot =
          await FirebaseFirestore.instance.collection('podcast').get();

      for (var podcastDoc in podcastSnapshot.docs) {
        QuerySnapshot episodeSnapshot = await FirebaseFirestore.instance
            .collection('podcast')
            .doc(podcastDoc.id)
            .collection('episode')
            .get();

        for (var episodeDoc in episodeSnapshot.docs) {
          _top10EpisodesList.add({
            'id': episodeDoc['id'],
            'created_at':
                episodeDoc['created_at'],
            'description': episodeDoc['description'],
            'playCount': episodeDoc['playCount'],
            'title': episodeDoc['title'],
            'audioUrl': episodeDoc['audioUrl'],
            'artist': episodeDoc['artist'],
            'imageUrl': episodeDoc['imageUrl'],
          });
        }
      }

      _top10EpisodesList
          .sort((a, b) => b['playCount'].compareTo(a['playCount']));
      return _top10EpisodesList.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> downloadPodcast(String url, String fileName) async {
    isDownloading = true;
    notifyListeners();
    downloadingPodcastUrl = url;
    String savePath = "";
    try {
      await Permission.manageExternalStorage.request();
      if (await Permission.manageExternalStorage.status.isGranted) {
        String directoryPath = "/storage/emulated/0/Download";

        Future<String> getUniqueFileName(
            String fileName, String directoryPath) async {
          int fileCounter = 0;
          String newFileName = "$fileName.mp3";
          String filePath = "$directoryPath/$newFileName";

          while (await File(filePath).exists()) {
            fileCounter++;
            newFileName = "$fileName ($fileCounter).mp3";
            filePath = "$directoryPath/$newFileName";
          }

          return newFileName;
        }

        String uniqueFileName =
            await getUniqueFileName(fileName, directoryPath);
        savePath = "$directoryPath/$uniqueFileName";

        await dio.download(
          url,
          savePath,
          options: Options(
            followRedirects: true,
            validateStatus: (status) {
              return status! < 500;
            },
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              downloadProgress = (received / total);
              notifyListeners();
            }
          },
        );

        if (downloadProgress < 1.0) {
          File(savePath).deleteSync();
        } else {
          if (downloadProgress == 1.0) {
            showCompleteNotification(fileName);
          }
          isDownloading = false;
          downloadProgress = 0;
          notifyListeners();
        }
      } else {
        await openAppSettings();
      }
    } catch (e) {}
  }

  void showCompleteNotification(String fileName) {
    var android = const AndroidNotificationDetails(
      'channel id',
      'channel name',
      importance: Importance.max,
      priority: Priority.high,
    );
    NotificationDetails platformDetails = NotificationDetails(android: android);

    flutterLocalNotificationsPlugin.show(
      0,
      'Download Complete',
      '$fileName has been successfully downloaded.',
      platformDetails,
    );
  }

  void clearCurrentPodcast() {
    if (_currentEpisode != null) {
      _currentEpisode = null;
      _audioPlayer.stop();
      notifyListeners();
    }
  }

  Future<void> playNextPodcast() async {
    if (_episodeList.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _episodeList.length;
    playPodcast(_episodeList[_currentIndex]);
  }

  Future<void> playPreviousPodcast() async {
    if (_episodeList.isEmpty) return;
    _currentIndex =
        (_currentIndex - 1 + _episodeList.length) % _episodeList.length;
    playPodcast(_episodeList[_currentIndex]);
  }

  Future<void> playNextEpisodeFromTop10() async {
    if (_top10EpisodesList.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _top10EpisodesList.length;
    playEpisodeFromTop10Section(_top10EpisodesList[_currentIndex]);
  }

  Future<void> playPreviousEpisodeFromTop10() async {
    if (_top10EpisodesList.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _top10EpisodesList.length) %
        _top10EpisodesList.length;
    playEpisodeFromTop10Section(_top10EpisodesList[_currentIndex]);
  }

  void setSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  void pause() {
    _audioPlayer.pause();
    notifyListeners();
  }

  void resume() {
    _audioPlayer.play();
    notifyListeners();
  }
}
