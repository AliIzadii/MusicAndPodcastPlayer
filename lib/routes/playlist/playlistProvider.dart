import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:player/routes/favorite/favoriteProvider.dart';
import 'package:player/routes/music/musicProvider.dart';
import 'package:player/routes/playlist/platlistClass.dart';
import 'package:player/routes/podcast/podcastProvider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';

enum PlayMode { normal, shuffle, repeat, single }

class PlaylistProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  SongModel? _currentSong;
  Duration _currentPosition = Duration.zero;
  Map<int, Uint8List?> artworkCache = {};
  List<Playlist> _playlists = [];
  List<SongModel> _currentPlaylistSongs = [];
  Playlist? _currentPlaylist;

  SongModel? get currentSong => _currentSong;
  AudioPlayer get audioPlayer => _audioPlayer;
  Duration get duration => _audioPlayer.duration ?? Duration.zero;
  Duration get currentPosition => _currentPosition;
  List<Playlist> get playlists => _playlists;
  PlayMode playMode = PlayMode.normal;

  PlaylistProvider() {
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
      playNextSongFromPlaylist();
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

  Future<void> loadPlaylists(List<SongModel> songs) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> playlistData = prefs.getStringList('playlists') ?? [];

    List<Playlist> playlists = await loadPlaylistss(playlistData, songs);

    _playlists = playlists;
    notifyListeners();
  }

  Future<List<Playlist>> loadPlaylistss(
      List<String> playlistData, List<SongModel> songs) async {
    List<Playlist> loadedPlaylists =
        await Future.wait(playlistData.map((data) async {
      Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(data));
      return await Playlist.fromJson(json, songs);
    }).toList());

    return loadedPlaylists;
  }

  void playSongFromPlaylist(SongModel song, Playlist playlist) async {
    try {
      final podcastProvider =
          Provider.of<PodcastProvider>(Get.context!, listen: false);
      final musicProvider =
          Provider.of<MusicProvider>(Get.context!, listen: false);
      final favoriteProvider =
          Provider.of<FavoriteProvider>(Get.context!, listen: false);
      podcastProvider.clearCurrentPodcast();
      musicProvider.clearCurrentSong();
      favoriteProvider.clearCurrentFavorite();

      await _audioPlayer.stop();

      _currentPlaylist = playlist;
      _currentPlaylistSongs = playlist.songs;

      setupAudioPlayerListener(playlist);
      notifyListeners();

      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(
          children: playlist.songslist,
        ),
        initialIndex: playlist.songs.indexOf(song),
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

  void setupAudioPlayerListener(Playlist p) {
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < p.songs.length) {
        _currentSong = p.songs[index];
        notifyListeners();
      }
    });
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

  Future<void> playNextSongFromPlaylist() async {
    if (playMode == PlayMode.shuffle) {
      final randomIndex = Random().nextInt(_currentPlaylistSongs.length);
      playSongFromPlaylist(
          _currentPlaylistSongs[randomIndex], _currentPlaylist!);
    } else {
      if (_currentPlaylistSongs.isNotEmpty && _currentSong != null) {
        final currentIndex = _currentPlaylistSongs.indexOf(_currentSong!);
        final nextIndex = (currentIndex + 1) % _currentPlaylistSongs.length;
        playSongFromPlaylist(
            _currentPlaylistSongs[nextIndex], _currentPlaylist!);
      }
    }
  }

  Future<void> playPreviousSongFromPlaylist() async {
    if (playMode == PlayMode.shuffle) {
      final randomIndex = Random().nextInt(_currentPlaylistSongs.length);
      playSongFromPlaylist(
          _currentPlaylistSongs[randomIndex], _currentPlaylist!);
    } else {
      if (_currentPlaylistSongs.isNotEmpty && _currentSong != null) {
        final currentIndex = _currentPlaylistSongs.indexOf(_currentSong!);
        final previousIndex =
            (currentIndex - 1 + _currentPlaylistSongs.length) %
                _currentPlaylistSongs.length;
        playSongFromPlaylist(
            _currentPlaylistSongs[previousIndex], _currentPlaylist!);
      }
    }
  }

  void clearCurrentPlaylist() {
    _currentPlaylist = null;
    _currentPlaylistSongs = [];
    _currentSong = null;
    _audioPlayer.stop();
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> playlistData = _playlists.map((playlist) {
      return jsonEncode(playlist.toJson());
    }).toList();
    await prefs.setStringList('playlists', playlistData);
  }

  bool createPlaylist(String name) {
    bool isNameDuplicate = _playlists.any((playlist) => playlist.name == name);
    if (isNameDuplicate) {
      Get.snackbar(
          'Duplicate Name', 'A playlist with this name already exists.');
      return false;
    }

    Playlist newPlaylist = Playlist(name: name, songs: [], songslist: []);
    _playlists.insert(0, newPlaylist);
    _savePlaylists();
    notifyListeners();
    return true;
  }

  Future<void> addSongToPlaylist(SongModel song, Playlist playlist) async {
    if (playlist.songs.any((s) => s.id == song.id)) {
      Get.snackbar('Music Existed',
          'Music that you want to add to ${playlist.name} playlist is already exist');
      return;
    }

    playlist.songs.insert(0, song);
    playlist.songslist.clear();
    for (var element in playlist.songs) {
      playlist.songslist.add(
        AudioSource.uri(
          Uri.parse(element.uri!),
          tag: MediaItem(
            id: '${element.id}',
            album: element.album,
            title: element.title,
            artist: element.artist,
            artUri: await getArtwork(element.id, returnUri: true),
          ),
        ),
      );
    }
    _savePlaylists();
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(SongModel song, Playlist playlist) async {
    playlist.songs.remove(song);
    playlist.songslist.clear();
    for (var element in playlist.songs) {
      playlist.songslist.add(
        AudioSource.uri(
          Uri.parse(element.uri!),
          tag: MediaItem(
            id: '${element.id}',
            album: element.album,
            title: element.title,
            artist: element.artist,
            artUri: await getArtwork(element.id, returnUri: true),
          ),
        ),
      );
    }
    _savePlaylists();
    notifyListeners();
  }

  void deletePlaylist(Playlist playlist) {
    _playlists.remove(playlist);
    _savePlaylists();
    notifyListeners();
  }

  void editPlaylistName(Playlist playlist, String newName) {
    bool isNameDuplicate =
        _playlists.any((p) => p.name == newName && p != playlist);

    if (isNameDuplicate) {
      Get.snackbar(
          'Duplicate Name', 'A playlist with this name already exists.');
      return;
    }
    playlist.name = newName;
    _savePlaylists();
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

  void setSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }
}
