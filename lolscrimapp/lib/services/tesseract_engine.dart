import 'dart:io';

/// 🔍 MOTEUR TESSERACT ULTRA-PRÉCIS POUR LOL
class TesseractEngine {
  static const String _tesseractPath = r'C:\Program Files\Tesseract-OCR\tesseract.exe';
  
  /// 🚀 ANALYSE OCR PRINCIPALE
  static Future<List<String>> extractTextFromImage(String imagePath, {
    String language = 'eng',
    Map<String, String>? ocrConfig,
  }) async {
    print('🔍 === TESSERACT OCR ULTRA-PRECIS ===');
    print('📁 Image: $imagePath');
    
    try {
      // Créer fichier temporaire pour la sortie
      final tempDir = Directory.systemTemp;
      final outputFile = '${tempDir.path}\\ocr_output_${DateTime.now().millisecondsSinceEpoch}';
      
      // Construire commande Tesseract optimisée
      final config = _buildTesseractConfig(ocrConfig);
      final args = [
        imagePath,
        outputFile,
        '-l', language,
        ...config,
      ];
      
      print('🎯 Exécution: $_tesseractPath ${args.join(' ')}');
      
      // Exécuter Tesseract
      final result = await Process.run(_tesseractPath, args);
      
      if (result.exitCode != 0) {
        print('❌ Erreur Tesseract: ${result.stderr}');
        return [];
      }
      
      // Lire résultat
      final outputTextFile = File('$outputFile.txt');
      if (!await outputTextFile.exists()) {
        print('❌ Fichier de sortie non trouvé');
        return [];
      }
      
      final content = await outputTextFile.readAsString();
      await outputTextFile.delete(); // Nettoyage
      
      final lines = content.split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      
      print('✅ Texte extrait: ${lines.length} lignes');
      for (var line in lines) {
        print('  📄 "$line"');
      }
      
      return lines;
      
    } catch (e) {
      print('❌ ERREUR OCR: $e');
      return [];
    }
  }
  
  /// ⚙️ CONFIGURATION TESSERACT OPTIMISÉE POUR LOL
  static List<String> _buildTesseractConfig(Map<String, String>? customConfig) {
    final args = <String>[];
    
    // Configuration par défaut pour LoL (texte blanc sur fond sombre)
    args.addAll(['--psm', '7']); // Single text line (meilleur pour noms de joueurs et stats)
    args.addAll(['--oem', '3']); // Default OCR Engine Mode
    
    // Whitelist de caractères pour réduire les erreurs
    args.addAll(['-c', 'tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 /-']);
    
    // Configuration personnalisée (override)
    if (customConfig != null) {
      customConfig.forEach((key, value) {
        if (key == '-c') {
          // Remplacer la whitelist
          final idx = args.indexOf('-c');
          if (idx != -1 && idx + 1 < args.length) {
            args[idx + 1] = value;
          }
        } else {
          args.addAll([key, value]);
        }
      });
    }
    
    return args;
  }
  
  /// 🧪 TEST RAPIDE OCR
  static Future<bool> testTesseract() async {
    try {
      final result = await Process.run(_tesseractPath, ['--version']);
      print('✅ Tesseract disponible: ${result.stdout.split('\n').first}');
      return result.exitCode == 0;
    } catch (e) {
      print('❌ Tesseract non disponible: $e');
      return false;
    }
  }
}
