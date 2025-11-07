import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'game/rhythm_game.dart';
import 'models/osz_package.dart';
import 'utils/osz_parser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'osu! Rhythm Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late RhythmGame game;
  bool gameStarted = false;
  String? loadedBeatmap;
  OszPackage? currentPackage;
  int selectedDifficultyIndex = 0;
  Uint8List? currentAudioData;

  @override
  void initState() {
    super.initState();
    game = RhythmGame();
  }

  Future<void> loadOszFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['osz'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      final package = OszParser.parseOszFile(bytes);

      if (package != null) {
        setState(() {
          currentPackage = package;
          selectedDifficultyIndex = 0;
          loadedBeatmap = package.name;
          currentAudioData = package.audioData;
        });

        final difficulty = package.difficulties[selectedDifficultyIndex];
        await game.loadBeatmap(difficulty.content, '');

        if (package.backgroundData != null) {
          game.setBackground(package.backgroundData!);
        }
      }
    }
  }

  Future<void> selectDifficulty(int index) async {
    if (currentPackage != null && index < currentPackage!.difficulties.length) {
      setState(() {
        selectedDifficultyIndex = index;
      });

      final difficulty = currentPackage!.difficulties[index];
      await game.loadBeatmap(difficulty.content, '');
    }
  }

  Future<void> loadBeatmapFromFile() async {
    const sampleBeatmap = '''
osu file format v14

[General]
AudioFilename: audio.mp3
AudioLeadIn: 0
PreviewTime: -1
Mode: 3

[Metadata]
Title:Sample Song
Artist:Test Artist
Creator:Test Creator
Version:Normal

[TimingPoints]
0,500,4,2,0,100,1,0

[HitObjects]
64,192,1000,1,0
192,192,1500,1,0
320,192,2000,1,0
448,192,2500,1,0
64,192,3000,1,0
192,192,3500,1,0
320,192,4000,1,0
448,192,4500,1,0
64,192,5000,128,0,5500:0:0:0:0:
192,192,6000,1,0
320,192,6500,1,0
448,192,7000,1,0
''';

    await game.loadBeatmap(sampleBeatmap, '');
    setState(() {
      loadedBeatmap = 'Sample Beatmap';
    });
  }

  void startGame() {
    if (loadedBeatmap != null) {
      if (currentAudioData != null) {
        game.setAudioData(currentAudioData!);
      }
      game.startGame();
      setState(() {
        gameStarted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!gameStarted) ...[
              const Text(
                'osu! Rhythm Game',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: loadOszFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                    ),
                    child: const Text('Load OSZ File'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: loadBeatmapFromFile,
                    child: const Text('Load Sample'),
                  ),
                ],
              ),
              if (currentPackage != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Select Difficulty:',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: currentPackage!.difficulties.asMap().entries.map((entry) {
                    final index = entry.key;
                    final difficulty = entry.value;
                    return ChoiceChip(
                      label: Text(difficulty.version),
                      selected: selectedDifficultyIndex == index,
                      onSelected: (selected) {
                        if (selected) selectDifficulty(index);
                      },
                      selectedColor: Colors.blue,
                      backgroundColor: Colors.grey.shade800,
                    );
                  }).toList(),
                ),
              ],
              if (loadedBeatmap != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Loaded: $loadedBeatmap',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Start Game'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Controls:\nKeyboard: D, F, J, K\nMouse/Touch: Tap lanes',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ] else ...[
              SizedBox(
                width: 400,
                height: 600,
                child: GameWidget(game: game),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    gameStarted = false;
                    game = RhythmGame();
                  });
                },
                child: const Text('Back to Menu'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
