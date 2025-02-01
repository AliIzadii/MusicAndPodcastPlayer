import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/playlist/playlistProvider.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum PlayMode { normal, shuffle, repeat, single }

class FavoriteProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<SongModel> _songs = [];
  final List<AudioSource> _songsList = [];
  SongModel? _currentSong;
  Duration _currentPosition = Duration.zero;
  Map<int, Uint8List?> artworkCache = {};

  List<SongModel> get songs => _songs;
  SongModel? get currentSong => _currentSong;
  List<AudioSource> get songsList => _songsList;
  AudioPlayer get audioPlayer => _audioPlayer;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  Duration get currentPosition => _currentPosition;
  PlayMode playMode = PlayMode.normal;

  FavoriteProvider() {
    _audioPlayer.setLoopMode(LoopMode.all);
  }

  Future<void> onSongCompletion() async {
    if (playMode == PlayMode.repeat) {
      audioPlayer.seek(Duration.zero);
      audioPlayer.play();
    } else if (playMode == PlayMode.single) {
      audioPlayer.stop();
      audioPlayer.seek(Duration.zero);
    } else if (playMode == PlayMode.normal) {
      playNextSongFromFavorite();
    }
    notifyListeners();
  }

  Future<void> switchPlayMode() async {
    if (playMode == PlayMode.normal) {
      playMode = PlayMode.repeat;
      await _audioPlayer.setShuffleModeEnabled(false);
    } else if (playMode == PlayMode.repeat) {
      playMode = PlayMode.shuffle;
      await _audioPlayer.setShuffleModeEnabled(true);
    } else if (playMode == PlayMode.shuffle) {
      await _audioPlayer.setShuffleModeEnabled(false);
      playMode = PlayMode.single;
    } else {
      playMode = PlayMode.normal;
      await _audioPlayer.setShuffleModeEnabled(false);
    }
    notifyListeners();
  }

  void playSongFromFavorite(SongModel song) async {
    try {
      final podcastProvider =
          Provider.of<PodcastProvider>(Get.context!, listen: false);
      final musicProvider =
          Provider.of<MusicProvider>(Get.context!, listen: false);
      final playlistProvider =
          Provider.of<PlaylistProvider>(Get.context!, listen: false);
      podcastProvider.clearCurrentPodcast();
      musicProvider.clearCurrentSong();
      playlistProvider.clearCurrentPlaylist();

      await _audioPlayer.stop();
      setupAudioPlayerListener();
      notifyListeners();

      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(
          children: songsList,
        ),
        initialIndex: songs.indexOf(song),
      );
      _audioPlayer.play();

      _audioPlayer.positionStream.listen((position) async {
        _currentPosition = position;
        notifyListeners();
        if (position == _audioPlayer.duration) {
          await onSongCompletion();
        }
      });
    } catch (e) {}
  }

  void setupAudioPlayerListener() {
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _songs.length) {
        _currentSong = _songs[index];
        notifyListeners();
      }
    });
  }

  Future<void> playNextSongFromFavorite() async {
    if (playMode == PlayMode.shuffle) {
      final randomIndex = Random().nextInt(_songs.length);
      playSongFromFavorite(_songs[randomIndex]);
    } else {
      final currentIndex = _songs.indexOf(_currentSong!);
      final nextIndex = (currentIndex + 1) % _songs.length;
      playSongFromFavorite(_songs[nextIndex]);
    }
  }

  Future<void> playPreviousSongFromFavorite() async {
    if (playMode == PlayMode.shuffle) {
      final randomIndex = Random().nextInt(_songs.length);
      playSongFromFavorite(_songs[randomIndex]);
    } else {
      final currentIndex = _songs.indexOf(_currentSong!);
      final previousIndex = (currentIndex - 1 + _songs.length) % _songs.length;
      playSongFromFavorite(_songs[previousIndex]);
    }
  }

  void clearCurrentFavorite() {
    _currentSong = null;
    _audioPlayer.stop();
    notifyListeners();
  }

  Future<void> load() async {
    songsList.clear();
    for (var element in _songs) {
      songsList.add(
        AudioSource.uri(
          Uri.parse(element.uri!),
          tag: MediaItem(
              id: '${element.id}',
              album: element.album,
              title: element.title,
              artist: element.artist,
              artUri: await getArtwork(element.id, returnUri: true)),
        ),
      );
    }
  }

  Future<void> addSongToFavorite(SongModel song) async {
    if (_songs.any((s) => s.id == song.id)) {
      Get.snackbar(
          'Music Existed', '${song.title} is already exist in favorite list');
      return;
    }

    _songs.insert(0, song);
    songsList.clear();
    for (var element in _songs) {
      songsList.add(
        AudioSource.uri(
          Uri.parse(element.uri!),
          tag: MediaItem(
              id: '${element.id}',
              album: element.album,
              title: element.title,
              artist: element.artist,
              artUri: await getArtwork(element.id, returnUri: true)),
        ),
      );
    }
    _saveFavoriteSongs();

    notifyListeners();
  }

  Future<void> removeSongFromFavorite(SongModel song) async {
    _songs.remove(song);
    songsList.clear();
    for (var element in _songs) {
      songsList.add(
        AudioSource.uri(
          Uri.parse(element.uri!),
          tag: MediaItem(
              id: '${element.id}',
              album: element.album,
              title: element.title,
              artist: element.artist,
              artUri: await getArtwork(element.id, returnUri: true)),
        ),
      );
    }
    _saveFavoriteSongs();
    notifyListeners();
  }

  Future<void> _saveFavoriteSongs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteSongIds =
        _songs.map((song) => song.id.toString()).toList();
    await prefs.setStringList('favoriteSongs', favoriteSongIds);
  }

  void setAllSongs(List<SongModel> allSongs) {
    _songs = allSongs;
    notifyListeners();
  }

  Future<void> loadFavoriteSongs(List<SongModel> songs) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteSongIds = prefs.getStringList('favoriteSongs') ?? [];
    _songs = favoriteSongIds
        .map((id) => songs.firstWhere((song) => song.id.toString() == id))
        .toList();

    notifyListeners();
  }

  Future<dynamic> getArtwork(int songId, {bool returnUri = false}) async {
    if (artworkCache.containsKey(songId) && !returnUri) {
      return artworkCache[songId];
    }

    final artwork =
        await OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO);

    if (!returnUri) {
      artworkCache[songId] = artwork;
      return artwork;
    } else {
      if (artwork != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/artwork_$songId.jpg');
        await file.writeAsBytes(artwork);
        return Uri.file(file.path);
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/default_artwork.jpg');

        ByteData data = await rootBundle.load('assets/song.png');
        List<int> bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes);

        return Uri.file(file.path);
      }
    }
  }

  void pause() {
    _audioPlayer.pause();
    notifyListeners();
  }

  void resume() {
    _audioPlayer.play();
    notifyListeners();
  }

  void setSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }
}
