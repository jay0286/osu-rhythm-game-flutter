import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/osz_package.dart';
import 'osu_parser.dart';

class OszParser {
  static OszPackage? parseOszFile(Uint8List bytes) {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);

      final List<OszDifficulty> difficulties = [];
      Uint8List? audioData;
      String? audioFilename;
      Uint8List? backgroundData;
      String? backgroundFilename;
      String packageName = 'Unknown';

      for (final file in archive) {
        final filename = file.name.toLowerCase();

        if (filename.endsWith('.osu')) {
          final content = String.fromCharCodes(file.content);
          final beatmap = OsuParser.parse(content);

          if (packageName == 'Unknown' && beatmap.title.isNotEmpty) {
            packageName = '${beatmap.artist} - ${beatmap.title}';
          }

          difficulties.add(OszDifficulty(
            name: filename,
            version: beatmap.version,
            beatmap: beatmap,
            content: content,
          ));

          if (audioFilename == null && beatmap.audioFilename.isNotEmpty) {
            audioFilename = beatmap.audioFilename;
          }
        } else if (filename.endsWith('.mp3') || filename.endsWith('.ogg') || filename.endsWith('.wav')) {
          if (audioData == null) {
            audioData = file.content;
            audioFilename = file.name;
          }
        } else if (filename.endsWith('.jpg') || filename.endsWith('.jpeg') || filename.endsWith('.png')) {
          if (backgroundData == null && !filename.contains('thumb')) {
            backgroundData = file.content;
            backgroundFilename = file.name;
          }
        }
      }

      if (difficulties.isEmpty) {
        return null;
      }

      difficulties.sort((a, b) {
        final orderMap = {
          'easy': 0,
          'normal': 1,
          'hard': 2,
          'insane': 3,
          'expert': 4,
          'extra': 5,
        };

        final aOrder = orderMap.entries
            .where((e) => a.version.toLowerCase().contains(e.key))
            .map((e) => e.value)
            .firstOrNull ?? 99;
        final bOrder = orderMap.entries
            .where((e) => b.version.toLowerCase().contains(e.key))
            .map((e) => e.value)
            .firstOrNull ?? 99;

        return aOrder.compareTo(bOrder);
      });

      return OszPackage(
        name: packageName,
        difficulties: difficulties,
        audioData: audioData,
        audioFilename: audioFilename,
        backgroundData: backgroundData,
        backgroundFilename: backgroundFilename,
      );
    } catch (e) {
      // Error parsing OSZ file: $e
      return null;
    }
  }
}