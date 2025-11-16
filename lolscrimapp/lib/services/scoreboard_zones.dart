/// 🎯 ZONES ULTRA-PRÉCISES SCOREBOARD LOL POST-MATCH
class ScoreboardZones {
  
  /// 📏 COORDONNÉES EXACTES BASÉES SUR VOTRE IMAGE (1280x720 résolution)
  static Map<String, Map<String, double>> getPlayerZones() {
    final zones = <String, Map<String, double>>{};
    
    // ===== ÉQUIPE 1 (5 joueurs du haut) =====
    final team1StartY = 0.095; // Position Y du premier joueur équipe 1
    final lineHeight = 0.058;  // Hauteur entre chaque ligne
    
    for (int i = 0; i < 5; i++) {
      // Zone complète pour chaque joueur (nom + stats)
      zones['team1_player_${i + 1}'] = {
        'x': 0.025,  // Début après les icônes de niveau/champion
        'y': team1StartY + (i * lineHeight),
        'w': 0.95,   // Toute la largeur jusqu'aux stats gold
        'h': 0.045,  // Hauteur d'une ligne de joueur
      };
      
      // Zone spécifique nom de joueur (après champion, avant items)
      zones['team1_name_${i + 1}'] = {
        'x': 0.13,   // Après icône champion
        'y': team1StartY + (i * lineHeight) + 0.01,
        'w': 0.12,   // Largeur zone nom
        'h': 0.025,  // Hauteur texte nom
      };
      
      // Zone spécifique KDA (entre items et CS)
      zones['team1_kda_${i + 1}'] = {
        'x': 0.58,   // Position colonne KDA
        'y': team1StartY + (i * lineHeight) + 0.01,
        'w': 0.08,   // Largeur KDA (ex: 1/3/8)
        'h': 0.025,  // Hauteur texte KDA
      };
      
      // Zone spécifique CS (entre KDA et Gold)
      zones['team1_cs_${i + 1}'] = {
        'x': 0.67,   // Position colonne CS
        'y': team1StartY + (i * lineHeight) + 0.01,
        'w': 0.05,   // Largeur CS
        'h': 0.025,  // Hauteur texte CS
      };
      
      // Zone spécifique Gold (colonne droite)
      zones['team1_gold_${i + 1}'] = {
        'x': 0.73,   // Position colonne Gold
        'y': team1StartY + (i * lineHeight) + 0.01,
        'w': 0.06,   // Largeur Gold
        'h': 0.025,  // Hauteur texte Gold
      };
    }
    
    // ===== ÉQUIPE 2 (5 joueurs du bas) =====
    final team2StartY = 0.42; // Position Y du premier joueur équipe 2 (après séparateur)
    
    for (int i = 0; i < 5; i++) {
      // Zone complète pour chaque joueur
      zones['team2_player_${i + 1}'] = {
        'x': 0.025,
        'y': team2StartY + (i * lineHeight),
        'w': 0.95,
        'h': 0.045,
      };
      
      // Zone spécifique nom de joueur
      zones['team2_name_${i + 1}'] = {
        'x': 0.13,
        'y': team2StartY + (i * lineHeight) + 0.01,
        'w': 0.12,
        'h': 0.025,
      };
      
      // Zone spécifique KDA
      zones['team2_kda_${i + 1}'] = {
        'x': 0.58,
        'y': team2StartY + (i * lineHeight) + 0.01,
        'w': 0.08,
        'h': 0.025,
      };
      
      // Zone spécifique CS
      zones['team2_cs_${i + 1}'] = {
        'x': 0.67,
        'y': team2StartY + (i * lineHeight) + 0.01,
        'w': 0.05,
        'h': 0.025,
      };
      
      // Zone spécifique Gold
      zones['team2_gold_${i + 1}'] = {
        'x': 0.73,
        'y': team2StartY + (i * lineHeight) + 0.01,
        'w': 0.06,
        'h': 0.025,
      };
    }
    
    return zones;
  }
  
  /// 🎮 ZONES OBJECTIFS (bannissements + objectifs à droite)
  static Map<String, Map<String, double>> getObjectiveZones() {
    return {
      'team1_objectives': {
        'x': 0.82, 'y': 0.14, 'w': 0.15, 'h': 0.25,
      },
      'team2_objectives': {
        'x': 0.82, 'y': 0.45, 'w': 0.15, 'h': 0.25,
      },
    };
  }
  
  /// 📊 OBTENIR ZONES PAR TYPE
  static Map<String, Map<String, double>> getZonesByType(String type) {
    switch (type) {
      case 'players':
        return getPlayerZones();
      case 'objectives':
        return getObjectiveZones();
      default:
        return {...getPlayerZones(), ...getObjectiveZones()};
    }
  }
}