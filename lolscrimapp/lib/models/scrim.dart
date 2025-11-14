import 'champion.dart';

/// Représente un match individuel dans un scrim
class ScrimMatch {
  final int matchNumber;
  final List<TeamPlayer> myTeamPlayers;
  final List<EnemyPlayer> enemyPlayers;
  final int? myTeamScore;
  final int? enemyTeamScore;
  final bool? isVictory;
  final Duration? matchDuration;
  final String? notes;

  const ScrimMatch({
    required this.matchNumber,
    required this.myTeamPlayers,
    required this.enemyPlayers,
    this.myTeamScore,
    this.enemyTeamScore,
    this.isVictory,
    this.matchDuration,
    this.notes,
  });

  /// Vérifie si le match est complet (5 joueurs de chaque côté)
  bool get isComplete => myTeamPlayers.length == 5 && enemyPlayers.length == 5;

  /// Calcul des KDA moyens de notre équipe pour ce match
  double get teamAverageKDA {
    final validPlayers = myTeamPlayers.where((p) => p.deaths != null).toList();
    if (validPlayers.isEmpty) return 0.0;
    return validPlayers
        .map((player) => player.kdaScore)
        .reduce((a, b) => a + b) / validPlayers.length;
  }

  /// Total des kills de notre équipe pour ce match
  int get totalKills => myTeamPlayers
      .where((p) => p.kills != null)
      .fold(0, (sum, player) => sum + player.kills!);

  /// Total des morts de notre équipe pour ce match
  int get totalDeaths => myTeamPlayers
      .where((p) => p.deaths != null)
      .fold(0, (sum, player) => sum + player.deaths!);

  /// Total des assists de notre équipe pour ce match
  int get totalAssists => myTeamPlayers
      .where((p) => p.assists != null)
      .fold(0, (sum, player) => sum + player.assists!);

  factory ScrimMatch.fromMap(Map<String, dynamic> map) {
    return ScrimMatch(
      matchNumber: map['match_number'] as int,
      myTeamPlayers: (map['my_team_players'] as List?)?.map((p) => TeamPlayer.fromMap(p)).toList() ?? [],
      enemyPlayers: (map['enemy_players'] as List?)?.map((p) => EnemyPlayer.fromMap(p)).toList() ?? [],
      myTeamScore: map['my_team_score'] as int?,
      enemyTeamScore: map['enemy_team_score'] as int?,
      isVictory: map['is_victory'] != null ? (map['is_victory'] as bool) : null,
      matchDuration: map['match_duration'] != null
          ? Duration(seconds: map['match_duration'] as int)
          : null,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'match_number': matchNumber,
      'my_team_players': myTeamPlayers.map((p) => p.toMap()).toList(),
      'enemy_players': enemyPlayers.map((p) => p.toMap()).toList(),
      'my_team_score': myTeamScore,
      'enemy_team_score': enemyTeamScore,
      'is_victory': isVictory,
      'match_duration': matchDuration?.inSeconds,
      'notes': notes,
    };
  }

  ScrimMatch copyWith({
    int? matchNumber,
    List<TeamPlayer>? myTeamPlayers,
    List<EnemyPlayer>? enemyPlayers,
    int? myTeamScore,
    int? enemyTeamScore,
    bool? isVictory,
    Duration? matchDuration,
    String? notes,
  }) {
    return ScrimMatch(
      matchNumber: matchNumber ?? this.matchNumber,
      myTeamPlayers: myTeamPlayers ?? this.myTeamPlayers,
      enemyPlayers: enemyPlayers ?? this.enemyPlayers,
      myTeamScore: myTeamScore ?? this.myTeamScore,
      enemyTeamScore: enemyTeamScore ?? this.enemyTeamScore,
      isVictory: isVictory ?? this.isVictory,
      matchDuration: matchDuration ?? this.matchDuration,
      notes: notes ?? this.notes,
    );
  }
}

/// Représente un joueur ennemi dans un scrim
class EnemyPlayer {
  final String pseudo;
  final String role;
  final String championId;
  final int? kills;
  final int? deaths;
  final int? assists;
  final int? cs;
  final int? gold;
  final int? damage;

  const EnemyPlayer({
    required this.pseudo,
    required this.role,
    required this.championId,
    this.kills,
    this.deaths,
    this.assists,
    this.cs,
    this.gold,
    this.damage,
  });

  /// Champion associé
  Champion? get champion => Champions.getById(championId);

  /// Score KDA
  double get kdaScore {
    if (deaths == 0) return (kills ?? 0) + (assists ?? 0).toDouble();
    return ((kills ?? 0) + (assists ?? 0)) / deaths!;
  }

  factory EnemyPlayer.fromMap(Map<String, dynamic> map) {
    return EnemyPlayer(
      pseudo: map['pseudo'] as String,
      role: map['role'] as String,
      championId: map['champion_id'] as String,
      kills: map['kills'] as int?,
      deaths: map['deaths'] as int?,
      assists: map['assists'] as int?,
      cs: map['cs'] as int?,
      gold: map['gold'] as int?,
      damage: map['damage'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pseudo': pseudo,
      'role': role,
      'champion_id': championId,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'cs': cs,
      'gold': gold,
      'damage': damage,
    };
  }

  EnemyPlayer copyWith({
    String? pseudo,
    String? role,
    String? championId,
    int? kills,
    int? deaths,
    int? assists,
    int? cs,
    int? gold,
    int? damage,
  }) {
    return EnemyPlayer(
      pseudo: pseudo ?? this.pseudo,
      role: role ?? this.role,
      championId: championId ?? this.championId,
      kills: kills ?? this.kills,
      deaths: deaths ?? this.deaths,
      assists: assists ?? this.assists,
      cs: cs ?? this.cs,
      gold: gold ?? this.gold,
      damage: damage ?? this.damage,
    );
  }
}

/// Représente un joueur de notre équipe dans un scrim
class TeamPlayer {
  final String? playerId; // ID du joueur dans notre base (peut être null pour "autre")
  final String pseudo;
  final String role;
  final String championId;
  final int? kills;
  final int? deaths;
  final int? assists;
  final int? cs;
  final int? gold;
  final int? damage;

  const TeamPlayer({
    this.playerId,
    required this.pseudo,
    required this.role,
    required this.championId,
    this.kills,
    this.deaths,
    this.assists,
    this.cs,
    this.gold,
    this.damage,
  });

  /// Champion associé
  Champion? get champion => Champions.getById(championId);

  /// Score KDA
  double get kdaScore {
    if (deaths == 0) return (kills ?? 0) + (assists ?? 0).toDouble();
    return ((kills ?? 0) + (assists ?? 0)) / deaths!;
  }

  /// Indique si c'est un joueur "autre" (pas dans notre base)
  bool get isOtherPlayer => playerId == null;

  factory TeamPlayer.fromMap(Map<String, dynamic> map) {
    return TeamPlayer(
      playerId: map['player_id'] as String?,
      pseudo: map['pseudo'] as String,
      role: map['role'] as String,
      championId: map['champion_id'] as String,
      kills: map['kills'] as int?,
      deaths: map['deaths'] as int?,
      assists: map['assists'] as int?,
      cs: map['cs'] as int?,
      gold: map['gold'] as int?,
      damage: map['damage'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'pseudo': pseudo,
      'role': role,
      'champion_id': championId,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'cs': cs,
      'gold': gold,
      'damage': damage,
    };
  }

  TeamPlayer copyWith({
    String? playerId,
    String? pseudo,
    String? role,
    String? championId,
    int? kills,
    int? deaths,
    int? assists,
    int? cs,
    int? gold,
    int? damage,
  }) {
    return TeamPlayer(
      playerId: playerId ?? this.playerId,
      pseudo: pseudo ?? this.pseudo,
      role: role ?? this.role,
      championId: championId ?? this.championId,
      kills: kills ?? this.kills,
      deaths: deaths ?? this.deaths,
      assists: assists ?? this.assists,
      cs: cs ?? this.cs,
      gold: gold ?? this.gold,
      damage: damage ?? this.damage,
    );
  }
}

/// Modèle représentant un scrim (session d'entraînement avec plusieurs matchs)
class Scrim {
  final String id;
  final String name; // Nom du scrim
  final String myTeamId; // ID de notre équipe
  final String? enemyTeamName; // Nom de l'équipe adverse
  final int totalMatches; // Nombre total de matchs dans ce scrim
  final List<ScrimMatch> matches; // Liste des matchs joués
  final int myTeamWins; // Nombre de victoires de notre équipe
  final int enemyTeamWins; // Nombre de victoires de l'équipe adverse
  final DateTime createdAt; // Date de création
  final DateTime? playedAt; // Date de jeu (null si pas encore joué)
  final String? patch; // Version du patch (ex: "13.24")
  final String? notes; // Notes additionnelles sur le scrim

  const Scrim({
    required this.id,
    required this.name,
    required this.myTeamId,
    this.enemyTeamName,
    required this.totalMatches,
    required this.matches,
    required this.myTeamWins,
    required this.enemyTeamWins,
    required this.createdAt,
    this.playedAt,
    this.patch,
    this.notes,
  });

  /// Vérifie si le scrim est complet (tous les matchs joués)
  bool get isComplete => matches.length == totalMatches;

  /// Vérifie si le scrim a été entièrement joué
  bool get isPlayed => playedAt != null && matches.isNotEmpty;

  /// Résultat global du scrim
  bool? get isVictory {
    if (matches.isEmpty) return null;
    return myTeamWins > enemyTeamWins;
  }

  /// Score global du scrim
  String get globalScore => '$myTeamWins-$enemyTeamWins';

  /// Calcul des KDA moyens de l'équipe sur tous les matchs
  double get overallTeamAverageKDA {
    if (matches.isEmpty) return 0.0;
    final matchKDAs = matches.map((match) => match.teamAverageKDA).where((kda) => kda > 0);
    if (matchKDAs.isEmpty) return 0.0;
    return matchKDAs.reduce((a, b) => a + b) / matchKDAs.length;
  }

  /// Total des kills de l'équipe sur tous les matchs
  int get overallTotalKills => matches.fold(0, (sum, match) => sum + match.totalKills);

  /// Total des morts de l'équipe sur tous les matchs
  int get overallTotalDeaths => matches.fold(0, (sum, match) => sum + match.totalDeaths);

  /// Total des assists de l'équipe sur tous les matchs
  int get overallTotalAssists => matches.fold(0, (sum, match) => sum + match.totalAssists);

  /// Pourcentage de victoire du scrim
  double get winRate {
    if (totalMatches == 0) return 0.0;
    return (myTeamWins / totalMatches) * 100;
  }

  /// Crée une instance Scrim à partir d'une Map
  factory Scrim.fromMap(Map<String, dynamic> map) {
    return Scrim(
      id: map['id'] as String,
      name: map['name'] as String,
      myTeamId: map['my_team_id'] as String,
      enemyTeamName: map['enemy_team_name'] as String?,
      totalMatches: map['total_matches'] as int,
      matches: (map['matches'] as List?)?.map((m) => ScrimMatch.fromMap(m)).toList() ?? [],
      myTeamWins: map['my_team_wins'] as int,
      enemyTeamWins: map['enemy_team_wins'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      playedAt: map['played_at'] != null 
          ? DateTime.parse(map['played_at'] as String) 
          : null,
      patch: map['patch'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// Convertit l'instance en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'my_team_id': myTeamId,
      'enemy_team_name': enemyTeamName,
      'total_matches': totalMatches,
      'matches': matches.map((m) => m.toMap()).toList(),
      'my_team_wins': myTeamWins,
      'enemy_team_wins': enemyTeamWins,
      'created_at': createdAt.toIso8601String(),
      'played_at': playedAt?.toIso8601String(),
      'patch': patch,
      'notes': notes,
    };
  }

  /// Crée une copie avec des modifications optionnelles
  Scrim copyWith({
    String? id,
    String? name,
    String? myTeamId,
    String? enemyTeamName,
    int? totalMatches,
    List<ScrimMatch>? matches,
    int? myTeamWins,
    int? enemyTeamWins,
    DateTime? createdAt,
    DateTime? playedAt,
    String? patch,
    String? notes,
  }) {
    return Scrim(
      id: id ?? this.id,
      name: name ?? this.name,
      myTeamId: myTeamId ?? this.myTeamId,
      enemyTeamName: enemyTeamName ?? this.enemyTeamName,
      totalMatches: totalMatches ?? this.totalMatches,
      matches: matches ?? this.matches,
      myTeamWins: myTeamWins ?? this.myTeamWins,
      enemyTeamWins: enemyTeamWins ?? this.enemyTeamWins,
      createdAt: createdAt ?? this.createdAt,
      playedAt: playedAt ?? this.playedAt,
      patch: patch ?? this.patch,
      notes: notes ?? this.notes,
    );
  }

  /// Trouve un match spécifique par son numéro
  ScrimMatch? getMatch(int matchNumber) {
    try {
      return matches.firstWhere((match) => match.matchNumber == matchNumber);
    } catch (e) {
      return null;
    }
  }

  /// Ajoute un match au scrim
  Scrim addMatch(ScrimMatch match) {
    final updatedMatches = List<ScrimMatch>.from(matches);
    
    // Remplacer si le match existe déjà, sinon ajouter
    final existingIndex = updatedMatches.indexWhere((m) => m.matchNumber == match.matchNumber);
    if (existingIndex != -1) {
      updatedMatches[existingIndex] = match;
    } else {
      updatedMatches.add(match);
    }
    
    // Recalculer les victoires
    int newMyWins = 0;
    int newEnemyWins = 0;
    for (final m in updatedMatches) {
      if (m.isVictory == true) newMyWins++;
      if (m.isVictory == false) newEnemyWins++;
    }

    return copyWith(
      matches: updatedMatches,
      myTeamWins: newMyWins,
      enemyTeamWins: newEnemyWins,
      playedAt: updatedMatches.isNotEmpty ? DateTime.now() : playedAt,
    );
  }

  /// Vérifie si ce scrim contient un champion spécifique
  bool containsChampion(String championId) {
    return matches.any((match) =>
      match.myTeamPlayers.any((player) => player.championId == championId) ||
      match.enemyPlayers.any((player) => player.championId == championId)
    );
  }

  /// Vérifie si ce scrim a été joué contre un champion ennemi spécifique
  bool playedAgainstChampion(String championId) {
    return matches.any((match) =>
      match.enemyPlayers.any((player) => player.championId == championId)
    );
  }

  /// Retourne un résumé du scrim
  String get scrimSummary {
    if (matches.isEmpty) return 'Scrim planifié ($totalMatches matchs)';
    if (isComplete) {
      final result = isVictory! ? 'Victoire' : 'Défaite';
      return '$result ($globalScore) - ${matches.length}/$totalMatches matchs';
    }
    return 'En cours ($globalScore) - ${matches.length}/$totalMatches matchs';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scrim && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Scrim(name: $name, ${scrimSummary})';
}