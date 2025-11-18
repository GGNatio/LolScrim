import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../services/ocr_orchestrator.dart';
import 'ocr_results_editor_screen.dart';

/// 🎯 Écran de prévisualisation OCR avec zones personnalisées
/// Identique au ScreenshotPreviewScreen normal mais utilise les zones
/// personnalisées définies dans l'écran interactif
class ScreenshotPreviewScreenWithCustomZones extends StatefulWidget {
  final File screenshotFile;
  final Map<String, Map<String, int>> customZones;
  final Function(List<Map<String, dynamic>> myTeam, List<Map<String, dynamic>> enemyTeam) onConfirm;
  
  const ScreenshotPreviewScreenWithCustomZones({
    super.key,
    required this.screenshotFile,
    required this.customZones,
    required this.onConfirm,
  });

  @override 
  State<ScreenshotPreviewScreenWithCustomZones> createState() => _ScreenshotPreviewScreenWithCustomZonesState();
}

class _ScreenshotPreviewScreenWithCustomZonesState extends State<ScreenshotPreviewScreenWithCustomZones> {
  Map<String, dynamic>? _analysisResult;
  bool _isAnalyzing = true;
  double _analysisProgress = 0.0;
  String _analysisMessage = 'Demarrage...';
  List<Map<String, dynamic>> _myTeamData = [];
  List<Map<String, dynamic>> _enemyTeamData = [];

  @override
  void initState() {
    super.initState();
    _analyzeScreenshotWithCustomZones();
  }

  /// 🎯 Analyse avec zones personnalisées au lieu de l'auto-détection
  Future<void> _analyzeScreenshotWithCustomZones() async {
    setState(() {
      _isAnalyzing = true;
      _analysisProgress = 0.0;
      _analysisMessage = '🎯 Analyse avec vos zones personnalisées...';
    });
    
    try {
      // Lire l'image et vérifier sa taille
      final imageBytes = await widget.screenshotFile.readAsBytes();
      
      // NOUVEAU: Diagnostiquer l'image avant OCR
      final image = img.decodeImage(imageBytes);
      if (image != null) {
        print('🔍 DIAGNOSTIC IMAGE: ${image.width}x${image.height}');
        print('🎯 ZONES REÇUES: ${widget.customZones.length}');
        widget.customZones.forEach((key, zone) {
          print('   $key: x=${zone['x']}, y=${zone['y']}, w=${zone['width']}, h=${zone['height']}');
        });
      }
      
      setState(() {
        _analysisProgress = 0.2;
        _analysisMessage = '🔍 OCR en cours sur zones ciblées...';
      });
      
      // Utiliser l'OCROrchestrator avec les zones personnalisées
      final result = await OCROrchestrator.analyzeLoLScreenshotWithCustomZones(
        imageBytes,
        widget.customZones,
      );
      
      setState(() {
        _analysisProgress = 0.8;
        _analysisMessage = '📊 Traitement des résultats...';
      });
      
      final players = (result['players'] as List<dynamic>?) ?? [];
      
      setState(() {
        _analysisResult = result;
        // Diviser les joueurs en deux équipes (5 premiers vs 5 derniers)
        _myTeamData = players.take(5).cast<Map<String, dynamic>>().toList();
        _enemyTeamData = players.skip(5).take(5).cast<Map<String, dynamic>>().toList();
        _isAnalyzing = false;
        _analysisProgress = 1.0;
        _analysisMessage = '✅ Analyse terminée !';
      });
      
      // Petit délai pour voir le 100%
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      setState(() {
        _analysisResult = {'error': e.toString(), 'players': []};
        _isAnalyzing = false;
        _analysisMessage = '❌ Erreur d\'analyse';
      });
    }
  }

  void _confirmData() {
    widget.onConfirm(_myTeamData, _enemyTeamData);
    Navigator.of(context).pop();
  }
  
  /// 🎯 Ouvre l'éditeur rapide des résultats OCR
  void _openQuickEditor() {
    if (_analysisResult == null) return;
    
    final allPlayers = ((_analysisResult!['players'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OCRResultsEditorScreen(
          initialPlayers: allPlayers,
          onSave: (correctedPlayers) {
            setState(() {
              // Mettre à jour les données avec les corrections
              _myTeamData = correctedPlayers.take(5).toList();
              _enemyTeamData = correctedPlayers.skip(5).take(5).toList();
              
              // Mettre à jour le résultat d'analyse
              _analysisResult!['players'] = correctedPlayers;
            });
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Données mises à jour !'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Maintenir le plein écran pour éviter les décalages
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎯 Résultats OCR - PLEIN ÉCRAN STABLE'),
            Text(
              'Zones personnalisées ultra-précises',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fermer',
          ),
        ],
      ),
      body: _isAnalyzing ? _buildAnalysisProgress() : _buildResults(),
    );
  }

  Widget _buildAnalysisProgress() {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🎯 Icône et titre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_fix_high,
                  color: Colors.deepPurple,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  '🎯 OCR avec Zones Personnalisées',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analyse ultra-précise en cours...',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Barre de progression
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _analysisProgress,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                Text(
                  _analysisMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_analysisProgress * 100).toInt()}%',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
          
          // 🎯 Informations sur les zones personnalisées
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      '🎯 Utilisation de Vos Zones Personnalisées',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• ${widget.customZones.length} zones définies par vos soins\n'
                  '• Positionnement ultra-précis pour chaque élément\n'
                  '• OCR ciblé sur vos zones exactes',
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
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
              const SizedBox(height: 24),
              
              // 💡 Info OCR avec zones personnalisées
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_fix_high, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          '🎯 Résultats OCR avec Zones Personnalisées',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• OCR réalisé avec ${widget.customZones.length} zones personnalisées\n'
                      '• Positionnement ultra-précis défini par vos soins\n'
                      '• Utilisez "Corriger OCR" pour ajuster les erreurs rapidement',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 🎯 Boutons d'action
              Row(
                children: [
                  // ✏️ Bouton d'édition rapide
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openQuickEditor,
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      label: const Text('Corriger OCR', style: TextStyle(color: Colors.orange)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // ✅ Bouton de confirmation
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
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
                  ),
                ],
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
    final name = player['name'] ?? 'N/A';
    final kills = player['kills'] ?? 0;
    final deaths = player['deaths'] ?? 0;
    final assists = player['assists'] ?? 0;
    final cs = player['cs'] ?? 0;
    final gold = player['gold'] ?? 0;
    final confidence = (player['confidence'] ?? 0.0) as double;
    final recognized = confidence > 0.7;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: recognized
            ? Border.all(color: Colors.green, width: 1)
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