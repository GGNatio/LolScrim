/// 🧠 PARSER ULTRA-SPÉCIALISÉ SCOREBOARD LOL POST-MATCH
class ScoreboardParser {
  
  /// 🔍 PATTERNS SPÉCIFIQUES VOTRE FORMAT
  static final RegExp _kdaPattern = RegExp(r'(\d+)\s*/\s*(\d+)\s*/\s*(\d+)');
  static final RegExp _playerNameClean = RegExp(r'[A-Za-z0-9][A-Za-z0-9 _-]*[A-Za-z0-9]');
  
  /// 🎯 PARSER PRINCIPAL PAR ZONES
  static Map<String, dynamic> parseScoreboardZones(Map<String, List<String>> zoneTexts) {
    print('🧠 === PARSING SCOREBOARD SPÉCIALISÉ ===');
    
    final players = <Map<String, dynamic>>[];
    final team1Players = <Map<String, dynamic>>[];
    final team2Players = <Map<String, dynamic>>[];
    
    // ===== PARSER ÉQUIPE 1 =====
    for (int i = 1; i <= 5; i++) {
      final playerData = _parsePlayerFromZones(zoneTexts, 'team1', i);
      if (playerData != null) {
        team1Players.add(playerData);
        players.add(playerData);
        print('👑 Team 1 Player $i: ${playerData['name']} ${playerData['kills']}/${playerData['deaths']}/${playerData['assists']}');
      }
    }
    
    // ===== PARSER ÉQUIPE 2 =====
    for (int i = 1; i <= 5; i++) {
      final playerData = _parsePlayerFromZones(zoneTexts, 'team2', i);
      if (playerData != null) {
        team2Players.add(playerData);
        players.add(playerData);
        print('⚔️ Team 2 Player $i: ${playerData['name']} ${playerData['kills']}/${playerData['deaths']}/${playerData['assists']}');
      }
    }
    
    print('✅ Parsing terminé: ${team1Players.length} + ${team2Players.length} = ${players.length} joueurs');
    
    return {
      'players': players,
      'team1': team1Players,
      'team2': team2Players,
      'objectives': _parseObjectives(zoneTexts),
    };
  }
  
  /// 👤 PARSER UN JOUEUR À PARTIR DE SES ZONES SPÉCIFIQUES
  static Map<String, dynamic>? _parsePlayerFromZones(Map<String, List<String>> zoneTexts, String team, int playerIndex) {
    // Récupérer les textes de chaque zone pour ce joueur
    final nameZone = '${team}_name_$playerIndex';
    final kdaZone = '${team}_kda_$playerIndex';
    final csZone = '${team}_cs_$playerIndex';
    final goldZone = '${team}_gold_$playerIndex';
    final fullZone = '${team}_player_$playerIndex';
    
    final nameTexts = zoneTexts[nameZone] ?? [];
    final kdaTexts = zoneTexts[kdaZone] ?? [];
    final csTexts = zoneTexts[csZone] ?? [];
    final goldTexts = zoneTexts[goldZone] ?? [];
    final fullTexts = zoneTexts[fullZone] ?? [];
    
    // Extraire nom de joueur
    String? playerName = _extractPlayerName(nameTexts, fullTexts);
    if (playerName == null || playerName.length < 2) {
      print('⚠️ Nom joueur non trouvé pour $team player $playerIndex');
      return null;
    }
    
    // Extraire KDA
    final kda = _extractKDA(kdaTexts, fullTexts);
    
    // Extraire CS
    final cs = _extractCS(csTexts, fullTexts);
    
    // Extraire Gold
    final gold = _extractGold(goldTexts, fullTexts);
    
    return {
      'name': playerName,
      'kills': kda['kills'] ?? 0,
      'deaths': kda['deaths'] ?? 0,
      'assists': kda['assists'] ?? 0,
      'cs': cs,
      'gold': gold,
      'level': 1,
      'confidence': _calculateConfidence(playerName, kda, cs, gold),
      'recognized': false,
      'team': team == 'team1' ? 1 : 2,
    };
  }
  
  /// 📝 EXTRAIRE NOM JOUEUR
  static String? _extractPlayerName(List<String> nameTexts, List<String> fullTexts) {
    // D'abord essayer zone nom spécifique
    for (final text in nameTexts) {
      final cleaned = _cleanPlayerName(text);
      if (cleaned.isNotEmpty && cleaned.length >= 2 && cleaned.length <= 16) {
        return cleaned;
      }
    }
    
    // Puis essayer dans texte complet
    for (final text in fullTexts) {
      final matches = _playerNameClean.allMatches(text);
      for (final match in matches) {
        final name = match.group(0);
        if (name != null && name.length >= 2 && name.length <= 16) {
          // Vérifier que ce n'est pas un nombre ou des stats
          if (!RegExp(r'^\d+$').hasMatch(name) && 
              !name.contains('/') && 
              !name.toLowerCase().contains('cs')) {
            return _cleanPlayerName(name);
          }
        }
      }
    }
    
    // En dernier recours, prendre le premier texte nettoyé
    if (nameTexts.isNotEmpty) {
      final cleaned = _cleanPlayerName(nameTexts.first);
      if (cleaned.length >= 2 && cleaned.length <= 16) {
        return cleaned;
      }
    }
    
    return null;
  }
  
  /// 🔢 EXTRAIRE KDA
  static Map<String, int> _extractKDA(List<String> kdaTexts, List<String> fullTexts) {
    final allTexts = [...kdaTexts, ...fullTexts];
    
    for (final text in allTexts) {
      final match = _kdaPattern.firstMatch(text);
      if (match != null) {
        return {
          'kills': int.tryParse(match.group(1)!) ?? 0,
          'deaths': int.tryParse(match.group(2)!) ?? 0,
          'assists': int.tryParse(match.group(3)!) ?? 0,
        };
      }
    }
    
    return {'kills': 0, 'deaths': 0, 'assists': 0};
  }
  
  /// 🌾 EXTRAIRE CS
  static int _extractCS(List<String> csTexts, List<String> fullTexts) {
    final allTexts = [...csTexts, ...fullTexts];
    
    for (final text in allTexts) {
      // Chercher nombre isolé qui pourrait être CS (50-400 range)
      final numbers = RegExp(r'\b(\d+)\b').allMatches(text);
      for (final match in numbers) {
        final num = int.tryParse(match.group(1)!);
        if (num != null && num >= 30 && num <= 500) {
          return num;
        }
      }
    }
    
    return 0;
  }
  
  /// 💰 EXTRAIRE GOLD
  static int _extractGold(List<String> goldTexts, List<String> fullTexts) {
    final allTexts = [...goldTexts, ...fullTexts];
    
    for (final text in allTexts) {
      // Chercher nombre qui pourrait être gold (format: 8626, 11692, etc.)
      final numbers = RegExp(r'\b(\d{4,5})\b').allMatches(text);
      for (final match in numbers) {
        final num = int.tryParse(match.group(1)!);
        if (num != null && num >= 5000 && num <= 25000) {
          return num;
        }
      }
    }
    
    return 0;
  }
  
  /// 🧹 NETTOYER NOM JOUEUR
  static String _cleanPlayerName(String text) {
    // Supprimer caractères parasites OCR
    String cleaned = text
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Ne pas faire de corrections automatiques qui pourraient altérer les noms réels
    // Les joueurs peuvent avoir des 0, 1, 5 dans leurs noms
    
    return cleaned;
  }
  
  /// 📊 CALCULER CONFIANCE
  static double _calculateConfidence(String name, Map<String, int> kda, int cs, int gold) {
    double confidence = 0.3; // Base
    
    // Bonus nom valide
    if (name.length >= 3 && name.length <= 16) confidence += 0.3;
    
    // Bonus stats cohérentes
    if (kda['kills']! + kda['deaths']! + kda['assists']! > 0) confidence += 0.2;
    
    // Bonus CS réaliste
    if (cs > 30 && cs < 500) confidence += 0.1;
    
    // Bonus Gold réaliste
    if (gold > 5000 && gold < 25000) confidence += 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// 🏆 PARSER OBJECTIFS
  static Map<String, dynamic> _parseObjectives(Map<String, List<String>> zoneTexts) {
    // TODO: Parser les objectifs si nécessaire
    return {
      'team1': {'towers': 0, 'dragons': 0, 'baron': 0, 'inhibitors': 0, 'heralds': 0, 'grubs': 0},
      'team2': {'towers': 0, 'dragons': 0, 'baron': 0, 'inhibitors': 0, 'heralds': 0, 'grubs': 0},
    };
  }
  
  /// ✅ VALIDATION DONNÉES JOUEUR
  static bool validatePlayerData(Map<String, dynamic> player) {
    final name = player['name'] as String?;
    final kills = player['kills'] as int? ?? 0;
    final deaths = player['deaths'] as int? ?? 0;
    final assists = player['assists'] as int? ?? 0;
    
    return name != null && 
           name.length >= 2 && 
           name.length <= 16 &&
           kills >= 0 && kills <= 50 &&
           deaths >= 0 && deaths <= 30 &&
           assists >= 0 && assists <= 50;
  }
}