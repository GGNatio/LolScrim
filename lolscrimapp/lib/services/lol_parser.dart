/// 🎮 PARSER INTELLIGENT SPÉCIALISÉ LOL
class LoLParser {
  
  /// 📝 PATTERNS SPÉCIALISÉS SCOREBOARD LOL
  static final RegExp _scoreboardLinePattern = RegExp(r'(\w+(?:\s+\w+)*)\s+(\d+)/(\d+)/(\d+)\s+(\d+)\s+(\d+\.?\d*k?)');
  static final RegExp _playerNamePattern = RegExp(r'^[A-Za-z0-9 _-]{2,16}$');
  static final RegExp _kdaPattern = RegExp(r'(\d+)/(\d+)/(\d+)');
  static final RegExp _csPattern = RegExp(r'(\d+)\s*(?:CS|cs|$)');
  static final RegExp _goldPattern = RegExp(r'(\d+\.?\d*)k?');
  static final RegExp _levelPattern = RegExp(r'(?:Level|Lvl|LV)\s*(\d+)', caseSensitive: false);
  
  /// 🔧 CORRECTIONS ERREURS OCR COMMUNES
  static const Map<String, String> _ocrFixes = {
    // Chiffres
    'O': '0', 'o': '0', 'l': '1', 'I': '1', 'S': '5', 'G': '6', 'T': '7', 'B': '8',
    // Lettres communes
    '0': 'O', '1': 'l', '5': 'S', '6': 'G', '8': 'B',
    // Caractères spéciaux
    '|': 'I', '/': '/', '\\': '/', '"': '', '\'': '',
  };
  
  /// 🚀 PARSING PRINCIPAL TEXTE OCR
  static Map<String, dynamic> parseOCRText(List<String> ocrLines) {
    print('🎮 === PARSING INTELLIGENT LOL ===');
    print('📄 Lignes OCR: ${ocrLines.length}');
    
    final players = <Map<String, dynamic>>[];
    final objectives = <String, dynamic>{};
    
    // Nettoyer et corriger les lignes OCR
    final cleanedLines = ocrLines
        .map(_cleanOCRLine)
        .where((line) => line.isNotEmpty)
        .toList();
    
    print('📝 Lignes nettoyées: ${cleanedLines.length}');
    for (var line in cleanedLines) {
      print('  🔍 "$line"');
    }
    
    // Extraire joueurs
    final extractedPlayers = _extractPlayers(cleanedLines);
    players.addAll(extractedPlayers);
    
    // Extraire objectifs si possibles
    final extractedObjectives = _extractObjectives(cleanedLines);
    objectives.addAll(extractedObjectives);
    
    print('✅ Parsing terminé: ${players.length} joueurs, ${objectives.length} objectifs');
    
    return {
      'players': players,
      'objectives': objectives,
    };
  }
  
  /// 🧹 NETTOYAGE LIGNE OCR
  static String _cleanOCRLine(String line) {
    // Supprimer caractères parasites
    String cleaned = line.replaceAll(RegExp(r'[^A-Za-z0-9 /_-]'), ' ');
    
    // Corriger erreurs OCR communes
    _ocrFixes.forEach((wrong, correct) {
      cleaned = cleaned.replaceAll(wrong, correct);
    });
    
    // Normaliser espaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }
  
  /// 👥 EXTRACTION JOUEURS
  static List<Map<String, dynamic>> _extractPlayers(List<String> lines) {
    final players = <Map<String, dynamic>>[];
    
    for (final line in lines) {
      // Chercher patterns de joueur
      final playerData = _parsePlayerLine(line);
      if (playerData != null) {
        players.add(playerData);
        print('🎯 Joueur détecté: ${playerData['name']} (${playerData['kills']}/${playerData['deaths']}/${playerData['assists']})');
      }
    }
    
    return players;
  }
  
  /// 🎯 PARSING LIGNE SCOREBOARD SPÉCIALISÉ
  static Map<String, dynamic>? _parsePlayerLine(String line) {
    print('🔍 Parsing ligne: "$line"');
    
    // Nettoyer la ligne d'abord
    String cleanedLine = line.trim();
    
    // Essayer le pattern complet du scoreboard d'abord
    final scoreboardMatch = _scoreboardLinePattern.firstMatch(cleanedLine);
    if (scoreboardMatch != null) {
      final playerName = scoreboardMatch.group(1)!.trim();
      final kills = int.tryParse(scoreboardMatch.group(2)!) ?? 0;
      final deaths = int.tryParse(scoreboardMatch.group(3)!) ?? 0;
      final assists = int.tryParse(scoreboardMatch.group(4)!) ?? 0;
      final cs = int.tryParse(scoreboardMatch.group(5)!) ?? 0;
      final goldStr = scoreboardMatch.group(6)!;
      
      int gold = 0;
      if (goldStr.contains('k')) {
        gold = (double.tryParse(goldStr.replaceAll('k', ''))! * 1000).round();
      } else {
        gold = int.tryParse(goldStr) ?? 0;
      }
      
      print('✅ Scoreboard match: $playerName ($kills/$deaths/$assists) CS:$cs Gold:$gold');
      
      return {
        'name': playerName,
        'kills': kills,
        'deaths': deaths,
        'assists': assists,
        'cs': cs,
        'gold': gold,
        'level': 1,
        'confidence': 0.95, // Très haute confiance pour pattern complet
        'recognized': false,
      };
    }
    
    // Fallback: parsing manuel pour lignes cassées
    final parts = cleanedLine.split(RegExp(r'\s+'));
    if (parts.length < 3) return null;
    
    // Chercher nom en début de ligne
    String? playerName;
    int statsStartIndex = 1;
    
    // Prendre le premier mot comme nom (LoL usernames sont souvent un seul mot)
    if (parts.isNotEmpty && parts[0].length > 1) {
      playerName = parts[0];
      
      // Si le deuxième mot n'est pas un chiffre, l'inclure dans le nom
      if (parts.length > 1 && !RegExp(r'^\d').hasMatch(parts[1]) && parts[1].length > 1) {
        playerName += ' ${parts[1]}';
        statsStartIndex = 2;
      }
    }
    
    if (playerName == null || playerName.length < 2) return null;
    
    // Chercher KDA dans le reste
    final statsText = parts.skip(statsStartIndex).join(' ');
    final stats = _extractStatsFromText(statsText);
    
    if (stats.isEmpty) return null;
    
    print('📊 Fallback parse: $playerName -> ${stats.toString()}');
    
    return {
      'name': playerName,
      'kills': stats['kills'] ?? 0,
      'deaths': stats['deaths'] ?? 0,
      'assists': stats['assists'] ?? 0,
      'cs': stats['cs'] ?? 0,
      'gold': stats['gold'] ?? 0,
      'level': stats['level'] ?? 1,
      'confidence': _calculateConfidence(playerName, stats),
      'recognized': false,
    };
  }  /// 📊 EXTRACTION STATS DU TEXTE
  static Map<String, int> _extractStatsFromText(String text) {
    final stats = <String, int>{};
    
    // KDA Pattern: 12/3/8
    final kdaMatch = _kdaPattern.firstMatch(text);
    if (kdaMatch != null) {
      stats['kills'] = int.tryParse(kdaMatch.group(1)!) ?? 0;
      stats['deaths'] = int.tryParse(kdaMatch.group(2)!) ?? 0;
      stats['assists'] = int.tryParse(kdaMatch.group(3)!) ?? 0;
    }
    
    // CS Pattern: 156 CS
    final csMatch = _csPattern.firstMatch(text);
    if (csMatch != null) {
      stats['cs'] = int.tryParse(csMatch.group(1)!) ?? 0;
    }
    
    // Gold Pattern: 12.5k ou 12500
    final goldMatch = _goldPattern.firstMatch(text);
    if (goldMatch != null) {
      final goldStr = goldMatch.group(1)!;
      if (text.contains('k')) {
        stats['gold'] = (double.tryParse(goldStr)! * 1000).round();
      } else {
        stats['gold'] = int.tryParse(goldStr) ?? 0;
      }
    }
    
    // Level Pattern
    final levelMatch = _levelPattern.firstMatch(text);
    if (levelMatch != null) {
      stats['level'] = int.tryParse(levelMatch.group(1)!) ?? 1;
    }
    
    return stats;
  }
  
  /// 🏆 EXTRACTION OBJECTIFS
  static Map<String, dynamic> _extractObjectives(List<String> lines) {
    final objectives = <String, dynamic>{};
    
    for (final line in lines) {
      // Chercher mentions d'objectifs
      if (line.toLowerCase().contains('dragon')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          objectives['dragons'] = int.tryParse(match.group(1)!) ?? 0;
        }
      }
      
      if (line.toLowerCase().contains('baron')) {
        objectives['baron'] = 1;
      }
      
      if (line.toLowerCase().contains('tower')) {
        final match = RegExp(r'(\d+)').firstMatch(line);
        if (match != null) {
          objectives['towers'] = int.tryParse(match.group(1)!) ?? 0;
        }
      }
    }
    
    return objectives;
  }
  
  /// 🎯 CALCUL CONFIANCE PARSING
  static double _calculateConfidence(String name, Map<String, int> stats) {
    double confidence = 0.5; // Base
    
    // Bonus nom valide
    if (_playerNamePattern.hasMatch(name) && name.length >= 3) {
      confidence += 0.2;
    }
    
    // Bonus stats cohérentes
    final kills = stats['kills'] ?? 0;
    final deaths = stats['deaths'] ?? 0;
    final assists = stats['assists'] ?? 0;
    
    if (kills >= 0 && deaths >= 0 && assists >= 0) {
      confidence += 0.1;
    }
    
    if (kills + assists > 0) {
      confidence += 0.1;
    }
    
    // Bonus CS réaliste
    final cs = stats['cs'] ?? 0;
    if (cs > 0 && cs < 500) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// 🎮 VALIDATION DONNÉES LOL
  static bool validatePlayerData(Map<String, dynamic> playerData) {
    final name = playerData['name'] as String?;
    final kills = playerData['kills'] as int? ?? 0;
    final deaths = playerData['deaths'] as int? ?? 0;
    final assists = playerData['assists'] as int? ?? 0;
    final cs = playerData['cs'] as int? ?? 0;
    
    // Validations de base
    if (name == null || name.length < 2 || name.length > 16) {
      return false;
    }
    
    if (kills < 0 || deaths < 0 || assists < 0 || cs < 0) {
      return false;
    }
    
    if (kills > 50 || deaths > 30 || assists > 50 || cs > 500) {
      return false;
    }
    
    return true;
  }
}
