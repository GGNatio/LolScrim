/// Énumération des jeux supportés
enum Game {
  leagueOfLegends('League of Legends'),
  valorant('Valorant'),
  teamfightTactics('Teamfight Tactics'),
  wildRift('Wild Rift'),
  legendsOfRuneterra('Legends of Runeterra');

  const Game(this.displayName);
  final String displayName;
}

/// Modèle représentant une équipe esport
class Team {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final Game game;
  final List<String> playerIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Team({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    required this.game,
    required this.playerIds,
    required this.createdAt,
    this.updatedAt,
  });

  /// Crée une instance Team à partir d'une Map (pour la base de données)
  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      logoUrl: map['logo_url'] as String?,
      game: Game.values.firstWhere((g) => g.name == map['game']),
      playerIds: (map['player_ids'] as String?)?.split(',').where((id) => id.isNotEmpty).toList() ?? [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  /// Convertit l'instance Team en Map (pour la base de données)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'game': game.name,
      'player_ids': playerIds.where((id) => id.isNotEmpty).join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crée une copie de l'équipe avec des modifications optionnelles
  Team copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    Game? game,
    List<String>? playerIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      game: game ?? this.game,
      playerIds: playerIds ?? this.playerIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Vérifie si l'équipe a un roster complet (5 joueurs)
  bool get hasFullRoster => playerIds.length == 5;

  /// Vérifie si l'équipe peut ajouter un nouveau joueur
  bool get canAddPlayer => playerIds.length < 5;

  /// Ajoute un joueur à l'équipe
  Team addPlayer(String playerId) {
    if (canAddPlayer && !playerIds.contains(playerId)) {
      return copyWith(
        playerIds: [...playerIds, playerId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Retire un joueur de l'équipe
  Team removePlayer(String playerId) {
    if (playerIds.contains(playerId)) {
      return copyWith(
        playerIds: playerIds.where((id) => id != playerId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name, players: ${playerIds.length}/5)';
}