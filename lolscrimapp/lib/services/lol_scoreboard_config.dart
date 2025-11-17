/// 🎮 CONFIGURATION DES ZONES SCOREBOARD LOL
/// 
/// Ce fichier contient les coordonnées précises pour extraire les données
/// du scoreboard de fin de partie de League of Legends.
/// 
/// Les coordonnées sont en pourcentages (0.0 - 1.0) de la taille de l'image
/// pour s'adapter à différentes résolutions.

class LoLScoreboardConfig {
  
  /// 📐 Configuration des zones pour différentes résolutions
  static const Map<String, ResolutionConfig> resolutions = {
    '1920x1080': ResolutionConfig(
      team1StartY: 0.065,
      team2StartY: 0.57,
      lineHeight: 0.075,
      nameX: 0.13,
      nameWidth: 0.15,
      kdaX: 0.50,
      kdaWidth: 0.12,
      csX: 0.63,
      csWidth: 0.07,
      goldX: 0.71,
      goldWidth: 0.08,
      elementHeight: 0.035,
    ),
    '1280x720': ResolutionConfig(
      team1StartY: 0.065,
      team2StartY: 0.57,
      lineHeight: 0.075,
      nameX: 0.13,
      nameWidth: 0.15,
      kdaX: 0.50,
      kdaWidth: 0.12,
      csX: 0.63,
      csWidth: 0.07,
      goldX: 0.71,
      goldWidth: 0.08,
      elementHeight: 0.035,
    ),
  };
  
  /// 📏 Obtenir la configuration pour une résolution donnée
  static ResolutionConfig getConfigForResolution(int width, int height) {
    final key = '${width}x$height';
    
    // Essayer une correspondance exacte
    if (resolutions.containsKey(key)) {
      return resolutions[key]!;
    }
    
    // Trouver la résolution la plus proche
    if (width >= 1600) {
      return resolutions['1920x1080']!;
    } else {
      return resolutions['1280x720']!;
    }
  }
  
  /// 🎯 Générer les zones pour une image donnée
  static Map<String, ZoneCoordinates> generateZones(int imageWidth, int imageHeight) {
    final config = getConfigForResolution(imageWidth, imageHeight);
    final zones = <String, ZoneCoordinates>{};
    
    // Équipe 1 (5 joueurs)
    for (int i = 0; i < 5; i++) {
      final y = config.team1StartY + (i * config.lineHeight);
      final playerNum = i + 1;
      
      zones['team1_name_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.nameX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.nameWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
      
      zones['team1_kda_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.kdaX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.kdaWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
      
      zones['team1_cs_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.csX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.csWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
      
      zones['team1_gold_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.goldX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.goldWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
    }
    
    // Équipe 2 (5 joueurs)
    for (int i = 0; i < 5; i++) {
      final y = config.team2StartY + (i * config.lineHeight);
      final playerNum = i + 1;
      
      zones['team2_name_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.nameX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.nameWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
      
      zones['team2_kda_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.kdaX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.kdaWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
      
      zones['team2_cs_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.csX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.csWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
      
      zones['team2_gold_$playerNum'] = ZoneCoordinates(
        x: (imageWidth * config.goldX).toInt(),
        y: (imageHeight * y).toInt(),
        width: (imageWidth * config.goldWidth).toInt(),
        height: (imageHeight * config.elementHeight).toInt(),
      );
    }
    
    return zones;
  }
}

/// 📐 Configuration pour une résolution
class ResolutionConfig {
  final double team1StartY;
  final double team2StartY;
  final double lineHeight;
  final double nameX;
  final double nameWidth;
  final double kdaX;
  final double kdaWidth;
  final double csX;
  final double csWidth;
  final double goldX;
  final double goldWidth;
  final double elementHeight;
  
  const ResolutionConfig({
    required this.team1StartY,
    required this.team2StartY,
    required this.lineHeight,
    required this.nameX,
    required this.nameWidth,
    required this.kdaX,
    required this.kdaWidth,
    required this.csX,
    required this.csWidth,
    required this.goldX,
    required this.goldWidth,
    required this.elementHeight,
  });
}

/// 📍 Coordonnées d'une zone
class ZoneCoordinates {
  final int x;
  final int y;
  final int width;
  final int height;
  
  const ZoneCoordinates({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
  
  Map<String, int> toMap() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }
}
