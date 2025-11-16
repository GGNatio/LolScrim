import 'dart:io';
import 'package:image/image.dart' as img;

/// 🖼️ PRÉPROCESSEUR D'IMAGES SPÉCIALISÉ LOL
class ImagePreprocessor {
  
  /// 🎯 ZONES SPÉCIFIQUES SCOREBOARD LOL (basé sur votre vraie image)
  static const Map<String, Map<String, double>> lolScoreboardZones = {
    // Tableau des joueurs avec noms + stats (zone centrale principale)
    'main_scoreboard': {
      'x': 0.08, 'y': 0.12, 'w': 0.84, 'h': 0.76,  // Tout le tableau central
    },
    // Ligne par ligne des joueurs (5 équipe bleue + 5 équipe rouge)
    'player_row_1': {
      'x': 0.08, 'y': 0.16, 'w': 0.84, 'h': 0.06,  // Première ligne joueur
    },
    'player_row_2': {
      'x': 0.08, 'y': 0.22, 'w': 0.84, 'h': 0.06,  // Deuxième ligne joueur
    },
    'player_row_3': {
      'x': 0.08, 'y': 0.28, 'w': 0.84, 'h': 0.06,  // Troisième ligne joueur
    },
    'player_row_4': {
      'x': 0.08, 'y': 0.34, 'w': 0.84, 'h': 0.06,  // Quatrième ligne joueur
    },
    'player_row_5': {
      'x': 0.08, 'y': 0.40, 'w': 0.84, 'h': 0.06,  // Cinquième ligne joueur
    },
    'player_row_6': {
      'x': 0.08, 'y': 0.50, 'w': 0.84, 'h': 0.06,  // Sixième ligne joueur (équipe 2)
    },
    'player_row_7': {
      'x': 0.08, 'y': 0.56, 'w': 0.84, 'h': 0.06,  // Septième ligne joueur
    },
    'player_row_8': {
      'x': 0.08, 'y': 0.62, 'w': 0.84, 'h': 0.06,  // Huitième ligne joueur
    },
    'player_row_9': {
      'x': 0.08, 'y': 0.68, 'w': 0.84, 'h': 0.06,  // Neuvième ligne joueur
    },
    'player_row_10': {
      'x': 0.08, 'y': 0.74, 'w': 0.84, 'h': 0.06, // Dixième ligne joueur
    },
  };
  
  /// 🚀 PRÉPARATION IMAGE PRINCIPALE
  static Future<String> prepareImageForOCR(String imagePath) async {
    print('🖼️ === PRÉPARATION IMAGE OCR ===');
    print('📁 Image source: $imagePath');
    
    try {
      // Charger image
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }
      
      print('📐 Dimensions originales: ${image.width}x${image.height}');
      
      // Redimensionner à 1920x1080 si nécessaire
      img.Image processedImage = image;
      if (image.width != 1920 || image.height != 1080) {
        processedImage = img.copyResize(image, width: 1920, height: 1080);
        print('🔄 Redimensionné vers: 1920x1080');
      }
      
      // Améliorer contraste et netteté
      processedImage = _enhanceForLOL(processedImage);
      
      // Sauvegarder image préparée
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}\\lol_prepared_${DateTime.now().millisecondsSinceEpoch}.png';
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(img.encodePng(processedImage));
      
      print('✅ Image préparée: $outputPath');
      return outputPath;
      
    } catch (e) {
      print('❌ Erreur préparation: $e');
      rethrow;
    }
  }
  
  /// ✂️ EXTRACTION ZONES SPÉCIFIQUES
  static Future<List<String>> extractZones(String imagePath) async {
    print('✂️ === EXTRACTION ZONES LOL ===');
    
    try {
      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Impossible de décoder l\'image');
      }
      
      final zonePaths = <String>[];
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      for (final entry in lolScoreboardZones.entries) {
        final zoneName = entry.key;
        final zone = entry.value;
        
        // Calculer coordonnées pixels
        final x = (zone['x']! * image.width).round();
        final y = (zone['y']! * image.height).round();
        final w = (zone['w']! * image.width).round();
        final h = (zone['h']! * image.height).round();
        
        print('📍 Zone $zoneName: $x,$y ${w}x$h');
        
        // Extraire zone
        final croppedImage = img.copyCrop(image, x: x, y: y, width: w, height: h);
        
        // Améliorer pour OCR
        final enhancedImage = _enhanceForOCR(croppedImage);
        
        // Sauvegarder
        final zonePath = '${tempDir.path}\\lol_zone_${zoneName}_$timestamp.png';
        final zoneFile = File(zonePath);
        await zoneFile.writeAsBytes(img.encodePng(enhancedImage));
        
        zonePaths.add(zonePath);
        print('✅ Zone $zoneName extraite: $zonePath');
      }
      
      return zonePaths;
      
    } catch (e) {
      print('❌ Erreur extraction zones: $e');
      return [];
    }
  }
  
  /// 🎨 AMÉLIORATION SPÉCIFIQUE LOL
  static img.Image _enhanceForLOL(img.Image image) {
    // Augmenter contraste pour texte blanc/LoL
    img.Image enhanced = img.contrast(image, contrast: 150);
    
    // Augmenter netteté
    enhanced = img.convolution(enhanced, filter: [
      0, -1, 0,
      -1, 5, -1,
      0, -1, 0
    ]);
    
    // Ajuster gamma pour LoL UI
    enhanced = img.gamma(enhanced, gamma: 1.2);
    
    return enhanced;
  }
  
  /// 🔍 AMÉLIORATION SPÉCIFIQUE OCR
  static img.Image _enhanceForOCR(img.Image image) {
    // Augmenter taille pour meilleur OCR
    img.Image enhanced = img.copyResize(image, width: image.width * 2, height: image.height * 2);
    
    // Contraste maximal pour texte
    enhanced = img.contrast(enhanced, contrast: 200);
    
    // Netteté aggressive
    enhanced = img.convolution(enhanced, filter: [
      -1, -1, -1,
      -1, 9, -1,
      -1, -1, -1
    ]);
    
    return enhanced;
  }
  
  /// 👤 AMÉLIORATION SPÉCIALISÉE LIGNES JOUEURS
  static img.Image _enhanceForPlayerLine(img.Image image) {
    // Agrandir encore plus pour ligne de texte fine
    img.Image enhanced = img.copyResize(image, width: image.width * 3, height: image.height * 4);
    
    // Contraste extrême pour texte blanc sur fond sombre LoL
    enhanced = img.contrast(enhanced, contrast: 250);
    
    // Luminosité pour faire ressortir le texte blanc
    enhanced = img.brightness(enhanced, brightness: 30);
    
    // Netteté ultra pour texte fin
    enhanced = img.convolution(enhanced, filter: [
      0, -2, 0,
      -2, 11, -2,
      0, -2, 0
    ]);
    
    return enhanced;
  }
  
  /// 🧹 NETTOYAGE FICHIERS TEMPORAIRES
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = Directory.systemTemp;
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file.path.contains('lol_prepared_') || 
            file.path.contains('lol_zone_') ||
            file.path.contains('lol_line_')) {
          await file.delete();
        }
      }
      
      print('🧹 Fichiers temporaires nettoyés');
    } catch (e) {
      print('⚠️ Erreur nettoyage: $e');
    }
  }
}
