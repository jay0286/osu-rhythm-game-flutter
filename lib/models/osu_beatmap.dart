class OsuBeatmap {
  final String audioFilename;
  final int audioLeadIn;
  final int previewTime;
  final int mode;
  final String title;
  final String artist;
  final String creator;
  final String version;
  final List<TimingPoint> timingPoints;
  final List<HitObject> hitObjects;

  OsuBeatmap({
    required this.audioFilename,
    required this.audioLeadIn,
    required this.previewTime,
    required this.mode,
    required this.title,
    required this.artist,
    required this.creator,
    required this.version,
    required this.timingPoints,
    required this.hitObjects,
  });
}

class TimingPoint {
  final int time;
  final double beatLength;
  final int meter;
  final int sampleSet;
  final int sampleIndex;
  final int volume;
  final bool uninherited;
  final int effects;

  TimingPoint({
    required this.time,
    required this.beatLength,
    required this.meter,
    required this.sampleSet,
    required this.sampleIndex,
    required this.volume,
    required this.uninherited,
    required this.effects,
  });
}

class HitObject {
  final int x;
  final int y;
  final int time;
  final int type;
  final int hitSound;
  final int? endTime;

  HitObject({
    required this.x,
    required this.y,
    required this.time,
    required this.type,
    required this.hitSound,
    this.endTime,
  });

  bool get isCircle => (type & 1) != 0;
  bool get isSlider => (type & 2) != 0;
  bool get isSpinner => (type & 8) != 0;
  bool get isHold => (type & 128) != 0;
}