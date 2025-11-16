import 'dart:io';
import 'package:flutter/material.dart';
import '../services/screenshot_analyzer.dart';

/// Écran de prévisualisation simple
class ScreenshotPreviewScreen extends StatefulWidget {
  final File screenshotFile;
  final Function(List<Map<String, dynamic>> myTeam, List<Map<String, dynamic>> enemyTeam) onConfirm;
  
  const ScreenshotPreviewScreen({
    super.key,
    required this.screenshotFile,
    required this.onConfirm,
  });

  @override
  State<ScreenshotPreviewScreen> createState() => _ScreenshotPreviewScreenState();
}

class _ScreenshotPreviewScreenState extends State<ScreenshotPreviewScreen> {
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = true;
  List<Map<String, dynamic>> _myTeamData = [];
  List<Map<String, dynamic>> _enemyTeamData = [];

  @override
  void initState() {
    super.initState();
    _analyzeScreenshot();
  }

  Future<void> _analyzeScreenshot() async {
    setState(() => _isAnalyzing = true);
    
    try {
      final result = await ScreenshotAnalyzer.analyzeScreenshot(widget.screenshotFile);
      final players = (result['players'] as List<dynamic>?) ?? [];
      
      setState(() {
        _analysisResult = result;
        // Diviser les joueurs en deux équipes (5 premiers vs 5 derniers)
        _myTeamData = players.take(5).cast<Map<String, dynamic>>().toList();
        _enemyTeamData = players.skip(5).take(5).cast<Map<String, dynamic>>().toList();
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _analysisResult = {'error': e.toString(), 'players': []};
        _isAnalyzing = false;
      });
    }
  }

  void _confirmData() {
    widget.onConfirm(_myTeamData, _enemyTeamData);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Données extraites'),
        backgroundColor: const Color(0xFF1E1E2E),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E1E2E),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.purple),
                  SizedBox(height: 20),
                  Text(
                    'Analyse en cours...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_analysisResult?['error'] != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Erreur d\'analyse',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _analysisResult?['error'] ?? 'Erreur inconnue',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Image preview
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              widget.screenshotFile,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        
        // Teams data
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTeamSection('Mon Équipe', _myTeamData, Colors.blue),
              const SizedBox(height: 20),
              _buildTeamSection('Équipe Adverse', _enemyTeamData, Colors.red),
              const SizedBox(height: 32),
              
              // Confirm button
              ElevatedButton(
                onPressed: _confirmData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Confirmer les données',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(String title, List<Map<String, dynamic>> players, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...players.map((player) => _buildPlayerCard(player)),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final name = player['name'] as String? ?? 'Unknown';
    final kills = player['kills'] as int? ?? 0;
    final deaths = player['deaths'] as int? ?? 0;
    final assists = player['assists'] as int? ?? 0;
    final cs = player['cs'] as int? ?? 0;
    final gold = player['gold'] as int? ?? 0;
    final recognized = player['recognized'] as bool? ?? false;
    final confidence = (player['confidence'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3A),
        borderRadius: BorderRadius.circular(8),
        border: recognized
            ? Border.all(color: Colors.green, width: 2)
            : Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          // Player name and recognition status
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (recognized) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                    ],
                  ],
                ),
                Text(
                  'Confiance: ${(confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          
          // KDA
          Expanded(
            child: Text(
              '$kills/$deaths/$assists',
              style: const TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          
          // CS
          Expanded(
            child: Text(
              'CS: $cs',
              style: const TextStyle(color: Colors.yellow, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Gold
          Expanded(
            child: Text(
              '${(gold / 1000).toStringAsFixed(1)}k',
              style: const TextStyle(color: Colors.amber, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}