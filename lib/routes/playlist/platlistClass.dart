import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';

Map<int, Uint8List?> artworkCache = {};

class Playlist {
  String name;
  List<SongModel> songs;
  List<AudioSource> songslist;

  Playlist({
    required this.name,
    required this.songs,
    required this.songslist,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'songIds': songs.map((song) => song.id.toString()).toList(),
    };
  }

  static Future<Playlist> fromJson(
      Map<String, dynamic> json, List<SongModel> allSongs) async {
    List<SongModel> playlistSongs = [];
    List<AudioSource> playlistSongslist = [];
    List<String> songIds =
        json['songIds'] != null ? List<String>.from(json['songIds']) : [];

    for (var id in songIds) {
      final SongModel? song = allSongs.firstWhereOrNull((song) {
        return song.id.toString() == id;
      });
      if (song != null) {
        playlistSongs.add(song);
        playlistSongslist.clear();
        for (var element in playlistSongs) {
          playlistSongslist.add(
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
      }
    }
    return Playlist(
        name: json['name'], songs: playlistSongs, songslist: playlistSongslist);
  }

  static Future<dynamic> getArtwork(int songId, {bool returnUri = false}) async {
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
}
