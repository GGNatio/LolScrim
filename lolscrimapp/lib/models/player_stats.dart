/// Modèle représentant les statistiques d'un joueur dans un match
class PlayerStats {
  final String playerId;
  final String scrimId; // ID du scrim associé
  final String champion;
  final int kills;
  final int deaths;
  final int assists;
  final int? creepScore; // CS - optionnel pour flexibilité
  final int? damage; // Dégâts totaux - optionnel
  final int? visionScore; // Score de vision - optionnel
  final int? gold; // Or gagné - optionnel

  const PlayerStats({
    required this.playerId,
    required this.scrimId,
    required this.champion,
    required this.kills,
    required this.deaths,
    required this.assists,
    this.creepScore,
    this.damage,
    this.visionScore,
    this.gold,
  });

  /// Calcule le KDA ratio (avec protection contre division par zéro)
  double get kdaRatio {
    if (deaths == 0) return (kills + assists).toDouble();
    return (kills + assists) / deaths;
  }

  /// Score KDA formaté pour l'affichage
  String get kdaFormatted => '$kills/$deaths/$assists';

  /// Score KDA pour les calculs (perfect KDA si pas de morts)
  double get kdaScore => deaths == 0 ? kills + assists + 1.0 : kdaRatio;

  /// Crée une instance PlayerStats à partir d'une Map
  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      playerId: map['player_id'] as String,
      scrimId: map['scrim_id'] as String,
      champion: map['champion'] as String,
      kills: map['kills'] as int,
      deaths: map['deaths'] as int,
      assists: map['assists'] as int,
      creepScore: map['creep_score'] as int?,
      damage: map['damage'] as int?,
      visionScore: map['vision_score'] as int?,
      gold: map['gold'] as int?,
    );
  }

  /// Convertit l'instance en Map
  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'scrim_id': scrimId,
      'champion': champion,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'creep_score': creepScore,
      'damage': damage,
      'vision_score': visionScore,
      'gold': gold,
    };
  }

  /// Crée une copie avec des modifications optionnelles
  PlayerStats copyWith({
    String? playerId,
    String? scrimId,
    String? champion,
    int? kills,
    int? deaths,
    int? assists,
    int? creepScore,
    int? damage,
    int? visionScore,
    int? gold,
  }) {
    return PlayerStats(
      playerId: playerId ?? this.playerId,
      scrimId: scrimId ?? this.scrimId,
      champion: champion ?? this.champion,
      kills: kills ?? this.kills,
      deaths: deaths ?? this.deaths,
      assists: assists ?? this.assists,
      creepScore: creepScore ?? this.creepScore,
      damage: damage ?? this.damage,
      visionScore: visionScore ?? this.visionScore,
      gold: gold ?? this.gold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlayerStats && 
           other.playerId == playerId && 
           other.champion == champion;
  }

  @override
  int get hashCode => Object.hash(playerId, champion);

  @override
  String toString() => 'PlayerStats(player: $playerId, champion: $champion, KDA: $kdaFormatted)';
}