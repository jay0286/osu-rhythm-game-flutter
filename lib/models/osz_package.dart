import 'dart:typed_data';
import '../models/osu_beatmap.dart';

class OszPackage {
  final String name;
  final List<OszDifficulty> difficulties;
  final Uint8List? audioData;
  final String? audioFilename;
  final Uint8List? backgroundData;
  final String? backgroundFilename;

  OszPackage({
    required this.name,
    required this.difficulties,
    this.audioData,
    this.audioFilename,
    this.backgroundData,
    this.backgroundFilename,
  });
}

class OszDifficulty {
  final String name;
  final String version;
  final OsuBeatmap beatmap;
  final String content;

  OszDifficulty({
    required this.name,
    required this.version,
    required this.beatmap,
    required this.content,
  });
}