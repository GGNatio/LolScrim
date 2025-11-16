/// Types de données pour les écrans de screenshot
class SimpleMatchPlayerData {
  final String name;
  final int kills;
  final int deaths;
  final int assists;
  final int cs;
  final int gold;
  final bool recognized;
  final double confidence;

  SimpleMatchPlayerData({
    required this.name,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.cs,
    required this.gold,
    this.recognized = false,
    this.confidence = 0.0,
  });

  factory SimpleMatchPlayerData.fromMap(Map<String, dynamic> map) {
    return SimpleMatchPlayerData(
      name: map['name'] as String,
      kills: map['kills'] as int,
      deaths: map['deaths'] as int,
      assists: map['assists'] as int,
      cs: map['cs'] as int,
      gold: map['gold'] as int,
      recognized: map['recognized'] as bool? ?? false,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExtractedPlayerData {
  final String name;
  final int kills;
  final int deaths;
  final int assists;
  final int cs;
  final int gold;
  final bool recognized;
  final double confidence;

  ExtractedPlayerData({
    required this.name,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.cs,
    required this.gold,
    this.recognized = false,
    this.confidence = 0.0,
  });

  SimpleMatchPlayerData toSimpleMatchPlayerData() {
    return SimpleMatchPlayerData(
      name: name,
      kills: kills,
      deaths: deaths,
      assists: assists,
      cs: cs,
      gold: gold,
      recognized: recognized,
      confidence: confidence,
    );
  }
}

class MatchAnalysisResult {
  final List<ExtractedPlayerData> myTeamPlayers;
  final List<ExtractedPlayerData> enemyPlayers;
  final Map<String, dynamic> objectives;
  final double confidence;

  MatchAnalysisResult({
    required this.myTeamPlayers,
    required this.enemyPlayers,
    required this.objectives,
    this.confidence = 0.0,
  });

  factory MatchAnalysisResult.fromScreenshotData(Map<String, dynamic> data) {
    final players = (data['players'] as List<dynamic>?) ?? [];
    final myTeam = <ExtractedPlayerData>[];
    final enemyTeam = <ExtractedPlayerData>[];

    // Séparer en deux équipes
    for (int i = 0; i < players.length; i++) {
      final playerMap = players[i] as Map<String, dynamic>;
      final player = ExtractedPlayerData(
        name: playerMap['name'] as String? ?? 'Unknown',
        kills: playerMap['kills'] as int? ?? 0,
        deaths: playerMap['deaths'] as int? ?? 0,
        assists: playerMap['assists'] as int? ?? 0,
        cs: playerMap['cs'] as int? ?? 0,
        gold: playerMap['gold'] as int? ?? 0,
        recognized: playerMap['recognized'] as bool? ?? false,
        confidence: (playerMap['confidence'] as num?)?.toDouble() ?? 0.0,
      );

      if (i < 5) {
        myTeam.add(player);
      } else {
        enemyTeam.add(player);
      }
    }

    return MatchAnalysisResult(
      myTeamPlayers: myTeam,
      enemyPlayers: enemyTeam,
      objectives: data['objectives'] as Map<String, dynamic>? ?? {},
      confidence: 0.85,
    );
  }
}

// Extensions pour faciliter la conversion
extension MapToPlayerData on Map<String, dynamic> {
  ExtractedPlayerData toExtractedPlayerData() {
    return ExtractedPlayerData(
      name: this['name'] as String? ?? 'Unknown',
      kills: this['kills'] as int? ?? 0,
      deaths: this['deaths'] as int? ?? 0,
      assists: this['assists'] as int? ?? 0,
      cs: this['cs'] as int? ?? 0,
      gold: this['gold'] as int? ?? 0,
      recognized: this['recognized'] as bool? ?? false,
      confidence: (this['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  SimpleMatchPlayerData toSimpleMatchPlayerData() {
    return SimpleMatchPlayerData(
      name: this['name'] as String? ?? 'Unknown',
      kills: this['kills'] as int? ?? 0,
      deaths: this['deaths'] as int? ?? 0,
      assists: this['assists'] as int? ?? 0,
      cs: this['cs'] as int? ?? 0,
      gold: this['gold'] as int? ?? 0,
      recognized: this['recognized'] as bool? ?? false,
      confidence: (this['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}