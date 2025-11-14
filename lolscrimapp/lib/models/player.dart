import 'team.dart';

/// Modèle représentant un joueur esport multi-jeux
class Player {
  final String id;
  final String pseudo;
  final String inGameId; // ID dans le jeu (Summoner name, Riot ID, etc.)
  final Game game; // Jeu principal du joueur
  final String role; // Rôle adaptatif selon le jeu
  final String? rank; // Rang adaptatif selon le jeu
  final String? description; // Description du joueur
  final String? realName;
  final String? region;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.pseudo,
    required this.inGameId,
    required this.game,
    required this.role,
    this.rank,
    this.description,
    this.realName,
    this.region,
    required this.createdAt,
  });

  /// Crée une instance Player à partir d'une Map (pour la base de données)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      pseudo: map['pseudo'] as String,
      inGameId: map['in_game_id'] as String,
      game: Game.values.firstWhere((g) => g.name == map['game']),
      role: map['role'] as String,
      rank: map['rank'] as String?,
      description: map['description'] as String?,
      realName: map['real_name'] as String?,
      region: map['region'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Convertit l'instance Player en Map (pour la base de données)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pseudo': pseudo,
      'in_game_id': inGameId,
      'game': game.name,
      'role': role,
      'rank': rank,
      'description': description,
      'real_name': realName,
      'region': region,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crée une copie du joueur avec des modifications optionnelles
  Player copyWith({
    String? id,
    String? pseudo,
    String? inGameId,
    Game? game,
    String? role,
    String? rank,
    String? description,
    String? realName,
    String? region,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      pseudo: pseudo ?? this.pseudo,
      inGameId: inGameId ?? this.inGameId,
      game: game ?? this.game,
      role: role ?? this.role,
      rank: rank ?? this.rank,
      description: description ?? this.description,
      realName: realName ?? this.realName,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Player(id: $id, pseudo: $pseudo, game: ${game.displayName}, role: $role)';
}

/// Rôles par jeu
class GameRoles {
  static const Map<Game, List<String>> roles = {
    Game.leagueOfLegends: ['Top', 'Jungle', 'Mid', 'ADC', 'Support'],
    Game.valorant: ['Duelist', 'Initiator', 'Controller', 'Sentinel'],
    Game.teamfightTactics: ['Flex'],
    Game.wildRift: ['Baron Lane', 'Jungle', 'Mid Lane', 'Dragon Lane (ADC)', 'Support'],
    Game.legendsOfRuneterra: ['Aggro', 'Midrange', 'Control'],
  };
  
  static List<String> getRolesForGame(Game game) {
    return roles[game] ?? ['Flex'];
  }
}

/// Rangs par jeu
class GameRanks {
  static const Map<Game, List<String>> ranks = {
    Game.leagueOfLegends: [
      'Iron IV', 'Iron III', 'Iron II', 'Iron I',
      'Bronze IV', 'Bronze III', 'Bronze II', 'Bronze I',
      'Silver IV', 'Silver III', 'Silver II', 'Silver I',
      'Gold IV', 'Gold III', 'Gold II', 'Gold I',
      'Platinum IV', 'Platinum III', 'Platinum II', 'Platinum I',
      'Emerald IV', 'Emerald III', 'Emerald II', 'Emerald I',
      'Diamond IV', 'Diamond III', 'Diamond II', 'Diamond I',
      'Master', 'Grandmaster', 'Challenger'
    ],
    Game.valorant: [
      'Iron 1', 'Iron 2', 'Iron 3',
      'Bronze 1', 'Bronze 2', 'Bronze 3',
      'Silver 1', 'Silver 2', 'Silver 3',
      'Gold 1', 'Gold 2', 'Gold 3',
      'Platinum 1', 'Platinum 2', 'Platinum 3',
      'Diamond 1', 'Diamond 2', 'Diamond 3',
      'Ascendant 1', 'Ascendant 2', 'Ascendant 3',
      'Immortal 1', 'Immortal 2', 'Immortal 3',
      'Radiant'
    ],
    Game.teamfightTactics: [
      'Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master', 'Grandmaster', 'Challenger'
    ],
    Game.wildRift: [
      'Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Emerald', 'Diamond', 'Master', 'Grandmaster', 'Challenger'
    ],
    Game.legendsOfRuneterra: [
      'Iron', 'Bronze', 'Silver', 'Gold', 'Platinum', 'Diamond', 'Master'
    ],
  };
  
  static List<String> getRanksForGame(Game game) {
    return ranks[game] ?? ['Non classé'];
  }
}