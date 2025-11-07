import '../models/osu_beatmap.dart';

class OsuParser {
  static OsuBeatmap parse(String content) {
    final lines = content.split('\n');

    String? audioFilename;
    int audioLeadIn = 0;
    int previewTime = -1;
    int mode = 0;
    String title = '';
    String artist = '';
    String creator = '';
    String version = '';
    List<TimingPoint> timingPoints = [];
    List<HitObject> hitObjects = [];

    String currentSection = '';

    for (var line in lines) {
      line = line.trim();

      if (line.isEmpty || line.startsWith('//')) continue;

      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1);
        continue;
      }

      switch (currentSection) {
        case 'General':
          if (line.startsWith('AudioFilename:')) {
            audioFilename = line.substring('AudioFilename:'.length).trim();
          } else if (line.startsWith('AudioLeadIn:')) {
            audioLeadIn = int.tryParse(line.substring('AudioLeadIn:'.length).trim()) ?? 0;
          } else if (line.startsWith('PreviewTime:')) {
            previewTime = int.tryParse(line.substring('PreviewTime:'.length).trim()) ?? -1;
          } else if (line.startsWith('Mode:')) {
            mode = int.tryParse(line.substring('Mode:'.length).trim()) ?? 0;
          }
          break;

        case 'Metadata':
          if (line.startsWith('Title:')) {
            title = line.substring('Title:'.length).trim();
          } else if (line.startsWith('Artist:')) {
            artist = line.substring('Artist:'.length).trim();
          } else if (line.startsWith('Creator:')) {
            creator = line.substring('Creator:'.length).trim();
          } else if (line.startsWith('Version:')) {
            version = line.substring('Version:'.length).trim();
          }
          break;

        case 'TimingPoints':
          final parts = line.split(',');
          if (parts.length >= 8) {
            timingPoints.add(TimingPoint(
              time: int.tryParse(parts[0]) ?? 0,
              beatLength: double.tryParse(parts[1]) ?? 1000.0,
              meter: int.tryParse(parts[2]) ?? 4,
              sampleSet: int.tryParse(parts[3]) ?? 0,
              sampleIndex: int.tryParse(parts[4]) ?? 0,
              volume: int.tryParse(parts[5]) ?? 100,
              uninherited: (int.tryParse(parts[6]) ?? 1) == 1,
              effects: int.tryParse(parts[7]) ?? 0,
            ));
          }
          break;

        case 'HitObjects':
          final parts = line.split(',');
          if (parts.length >= 5) {
            final type = int.tryParse(parts[3]) ?? 0;
            int? endTime;

            if ((type & 128) != 0 && parts.length > 5) {
              final endTimeStr = parts[5].split(':')[0];
              endTime = int.tryParse(endTimeStr);
            }

            hitObjects.add(HitObject(
              x: int.tryParse(parts[0]) ?? 0,
              y: int.tryParse(parts[1]) ?? 0,
              time: int.tryParse(parts[2]) ?? 0,
              type: type,
              hitSound: int.tryParse(parts[4]) ?? 0,
              endTime: endTime,
            ));
          }
          break;
      }
    }

    return OsuBeatmap(
      audioFilename: audioFilename ?? '',
      audioLeadIn: audioLeadIn,
      previewTime: previewTime,
      mode: mode,
      title: title,
      artist: artist,
      creator: creator,
      version: version,
      timingPoints: timingPoints,
      hitObjects: hitObjects,
    );
  }
}