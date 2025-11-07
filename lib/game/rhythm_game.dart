import 'dart:async';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/events.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../components/note.dart';
import '../components/judge_line.dart';
import '../components/lane.dart';
import '../models/osu_beatmap.dart';
import '../utils/osu_parser.dart';

class RhythmGame extends FlameGame with TapCallbacks, KeyboardEvents {
  static const int laneCount = 4;
  static const double laneWidth = 80;
  static const double noteHeight = 20;
  static const double judgeLineY = 500;
  static const double noteSpeed = 300;
  static const double perfectTiming = 50;
  static const double greatTiming = 100;
  static const double goodTiming = 150;

  late OsuBeatmap beatmap;
  late AudioPlayer audioPlayer;
  final List<Lane> lanes = [];
  late JudgeLine judgeLine;
  final List<Note> notes = [];
  int currentNoteIndex = 0;
  double elapsedTime = 0;
  bool isPlaying = false;
  int score = 0;
  int combo = 0;
  late TextComponent scoreText;
  late TextComponent comboText;
  late TextComponent audioStatusText;
  Uint8List? audioData;
  Uint8List? backgroundData;
  SpriteComponent? backgroundSprite;
  bool audioStarted = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    camera.viewfinder.visibleGameSize = Vector2(400, 600);


    for (int i = 0; i < laneCount; i++) {
      final lane = Lane(
        laneIndex: i,
        position: Vector2(i * laneWidth, 0),
        size: Vector2(laneWidth, 600),
      );
      lanes.add(lane);
      add(lane);
    }

    judgeLine = JudgeLine(
      position: Vector2(0, judgeLineY),
      size: Vector2(laneWidth * laneCount, 5),
    );
    add(judgeLine);

    scoreText = TextComponent(
      text: 'Score: 0',
      position: Vector2(10, 10),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
    );
    add(scoreText);

    comboText = TextComponent(
      text: 'Combo: 0',
      position: Vector2(10, 40),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      ),
    );
    add(comboText);

    audioStatusText = TextComponent(
      text: 'Audio: Not loaded',
      position: Vector2(10, 70),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.orange,
          fontSize: 16,
        ),
      ),
    );
    add(audioStatusText);

    audioPlayer = AudioPlayer();
  }

  Future<void> loadBeatmap(String beatmapContent, String audioPath) async {
    beatmap = OsuParser.parse(beatmapContent);

    for (final hitObject in beatmap.hitObjects) {
      final lane = (hitObject.x * laneCount ~/ 512).clamp(0, laneCount - 1);
      final noteTime = hitObject.time / 1000.0;

      final note = Note(
        lane: lane,
        hitTime: hitObject.time,
        endTime: hitObject.endTime,
        speed: noteSpeed,
        position: Vector2(
          lane * laneWidth + (laneWidth - 60) / 2,
          -noteTime * noteSpeed + judgeLineY,
        ),
        size: Vector2(60, noteHeight),
      );
      notes.add(note);
    }

    notes.sort((a, b) => a.hitTime.compareTo(b.hitTime));
  }

  void setAudioData(Uint8List data) {
    audioData = data;
    audioStatusText.text = 'Audio: Loaded (${(data.length / 1024).round()}KB)';
  }

  void setBackground(Uint8List data) async {
    backgroundData = data;

    if (backgroundData != null && isMounted) {
      try {
        final image = await decodeImageFromList(backgroundData!);
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint();

        canvas.drawImage(image, Offset.zero, paint);
        final picture = recorder.endRecording();
        final img = await picture.toImage(image.width, image.height);

        backgroundSprite = SpriteComponent(
          sprite: Sprite(img),
          size: Vector2(400, 600),
          position: Vector2.zero(),
          priority: -1,
        );
        add(backgroundSprite!);
      } catch (e) {
        // Failed to load background
      }
    }
  }

  void startGame() async {
    isPlaying = true;
    elapsedTime = 0;
    currentNoteIndex = 0;
    audioStarted = false;

    try {
      if (audioData != null) {
        audioStatusText.text = 'Audio: Starting...';
        await audioPlayer.play(BytesSource(audioData!));
        audioStarted = true;
        audioStatusText.text = 'Audio: Playing ♪';
      } else {
        audioStatusText.text = 'Audio: No audio data';
      }
    } catch (e) {
      // 오디오 재생 실패, 게임은 계속 진행
      audioStarted = false;
      audioStatusText.text = 'Audio: Failed to play';
    }

    for (final note in notes) {
      add(note);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!isPlaying) return;

    elapsedTime += dt * 1000;

    while (currentNoteIndex < notes.length) {
      final note = notes[currentNoteIndex];
      if (note.hitTime - elapsedTime > 2000) break;

      if (!note.isMounted && !note.isHit && !note.isMissed) {
        add(note);
      }
      currentNoteIndex++;
    }

    for (final note in notes) {
      if (note.isMounted && !note.isHit && !note.isMissed) {
        if (note.position.y > judgeLineY + goodTiming && !note.isHit) {
          note.isMissed = true;
          combo = 0;
          updateUI();
          note.removeFromParent();
        }
      }
    }
  }

  void handleTap(int lane) {
    if (!isPlaying) return;

    for (final note in notes) {
      if (note.lane == lane && !note.isHit && !note.isMissed && note.isMounted) {
        final timeDiff = (elapsedTime - note.hitTime).abs();

        if (timeDiff <= perfectTiming) {
          score += 300;
          combo++;
        } else if (timeDiff <= greatTiming) {
          score += 200;
          combo++;
        } else if (timeDiff <= goodTiming) {
          score += 100;
          combo++;
        } else {
          continue;
        }

        note.isHit = true;
        note.removeFromParent();
        judgeLine.showHitEffect();
        updateUI();
        break;
      }
    }
  }

  void updateUI() {
    scoreText.text = 'Score: $score';
    comboText.text = 'Combo: $combo';
  }

  @override
  void onTapDown(TapDownEvent event) {
    final tapX = event.localPosition.x;
    final lane = (tapX / laneWidth).floor().clamp(0, laneCount - 1);
    handleTap(lane);
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent) {
      if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
        handleTap(0);
      } else if (keysPressed.contains(LogicalKeyboardKey.keyF)) {
        handleTap(1);
      } else if (keysPressed.contains(LogicalKeyboardKey.keyJ)) {
        handleTap(2);
      } else if (keysPressed.contains(LogicalKeyboardKey.keyK)) {
        handleTap(3);
      }
    }
    return KeyEventResult.handled;
  }
}