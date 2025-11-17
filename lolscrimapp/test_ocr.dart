import 'dart:io';
import 'package:lolscrimapp/services/tesseract_engine.dart';
import 'package:lolscrimapp/services/ocr_orchestrator.dart';

/// 🧪 SCRIPT DE TEST OCR
/// 
/// Utilisation :
/// 1. Placer une image de scoreboard LoL dans le dossier du projet
/// 2. Lancer : dart run test_ocr.dart chemin/vers/image.png

void main(List<String> args) async {
  print('🧪 === TEST OCR TESSERACT ===\n');
  
  // Vérifier Tesseract
  print('1️⃣ Vérification de Tesseract...');
  final tesseractOk = await TesseractEngine.testTesseract();
  
  if (!tesseractOk) {
    print('❌ Tesseract n\'est pas disponible !');
    print('📝 Installez Tesseract OCR : https://github.com/UB-Mannheim/tesseract/wiki');
    print('   Puis ajoutez-le au PATH : C:\\Program Files\\Tesseract-OCR');
    exit(1);
  }
  
  print('✅ Tesseract est disponible\n');
  
  // Vérifier argument
  if (args.isEmpty) {
    print('❌ Usage: dart run test_ocr.dart <chemin_image>');
    print('📝 Exemple: dart run test_ocr.dart screenshot.png');
    exit(1);
  }
  
  final imagePath = args[0];
  final imageFile = File(imagePath);
  
  if (!await imageFile.exists()) {
    print('❌ Image non trouvée : $imagePath');
    exit(1);
  }
  
  print('2️⃣ Analyse de l\'image: $imagePath\n');
  
  try {
    // Lancer l'analyse OCR
    final result = await OCROrchestrator.analyzeLoLScreenshot(imagePath);
    
    print('\n✅ === RÉSULTATS ===\n');
    
    final players = result['players'] as List<dynamic>?;
    if (players != null && players.isNotEmpty) {
      print('👥 Joueurs détectés: ${players.length}\n');
      
      // Équipe 1
      print('🔵 ÉQUIPE 1:');
      for (int i = 0; i < 5 && i < players.length; i++) {
        final p = players[i] as Map<String, dynamic>;
        final name = p['name'] ?? 'Unknown';
        final kda = '${p['kills']}/${p['deaths']}/${p['assists']}';
        final cs = p['cs'] ?? 0;
        final gold = p['gold'] ?? 0;
        final conf = ((p['confidence'] ?? 0.0) * 100).toStringAsFixed(0);
        print('  $name - KDA: $kda | CS: $cs | Gold: $gold | Conf: $conf%');
      }
      
      print('\n🔴 ÉQUIPE 2:');
      for (int i = 5; i < players.length; i++) {
        final p = players[i] as Map<String, dynamic>;
        final name = p['name'] ?? 'Unknown';
        final kda = '${p['kills']}/${p['deaths']}/${p['assists']}';
        final cs = p['cs'] ?? 0;
        final gold = p['gold'] ?? 0;
        final conf = ((p['confidence'] ?? 0.0) * 100).toStringAsFixed(0);
        print('  $name - KDA: $kda | CS: $cs | Gold: $gold | Conf: $conf%');
      }
    } else {
      print('⚠️ Aucun joueur détecté');
    }
    
    // Métadonnées
    final metadata = result['metadata'] as Map<String, dynamic>?;
    if (metadata != null) {
      print('\n📊 Métadonnées:');
      print('  Méthode: ${metadata['ocrMethod']}');
      print('  Version: ${metadata['version']}');
      print('  Zones: ${metadata['zonesProcessed']}');
    }
    
    print('\n✅ Test terminé avec succès !');
    
  } catch (e, stackTrace) {
    print('\n❌ ERREUR: $e');
    print('\n📋 Stack trace:');
    print(stackTrace);
    exit(1);
  }
}
