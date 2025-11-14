import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';

/// Service de stockage en mémoire pour le web
class InMemoryStorageService {
  // Collections en mémoire
  static final Map<String, Player> _players = {};
  static final Map<String, Team> _teams = {};
  static final Map<String, Scrim> _scrims = {};
  static final Map<String, PlayerStats> _playerStats = {};

  /// Joueurs
  static Future<List<Player>> getPlayers() async {
    return _players.values.toList();
  }

  static Future<void> insertPlayer(Player player) async {
    _players[player.id] = player;
  }

  static Future<void> updatePlayer(Player player) async {
    _players[player.id] = player;
  }

  static Future<void> deletePlayer(String id) async {
    _players.remove(id);
  }

  /// Équipes
  static Future<List<Team>> getTeams() async {
    return _teams.values.toList();
  }

  static Future<void> insertTeam(Team team) async {
    _teams[team.id] = team;
  }

  static Future<void> updateTeam(Team team) async {
    _teams[team.id] = team;
  }

  static Future<void> deleteTeam(String id) async {
    _teams.remove(id);
  }

  /// Scrims
  static Future<List<Scrim>> getScrims() async {
    return _scrims.values.toList();
  }

  static Future<void> insertScrim(Scrim scrim) async {
    _scrims[scrim.id] = scrim;
  }

  static Future<void> updateScrim(Scrim scrim) async {
    _scrims[scrim.id] = scrim;
  }

  static Future<void> deleteScrim(String id) async {
    _scrims.remove(id);
  }

  /// Player Stats (utilisé par scrim ID + player ID comme clé composite)
  static Future<List<PlayerStats>> getPlayerStats({String? scrimId, String? playerId}) async {
    final allStats = _playerStats.values.toList();
    
    if (playerId != null) {
      return allStats.where((stats) => stats.playerId == playerId).toList();
    }
    
    return allStats;
  }

  static Future<void> insertPlayerStats(String scrimId, PlayerStats playerStats) async {
    final key = '${scrimId}_${playerStats.playerId}';
    _playerStats[key] = playerStats;
  }

  static Future<void> updatePlayerStats(String scrimId, PlayerStats playerStats) async {
    final key = '${scrimId}_${playerStats.playerId}';
    _playerStats[key] = playerStats;
  }

  static Future<void> deletePlayerStats(String scrimId, String playerId) async {
    final key = '${scrimId}_$playerId';
    _playerStats.remove(key);
  }

  /// Méthode pour vider toutes les données (utile pour les tests)
  static void clearAll() {
    _players.clear();
    _teams.clear();
    _scrims.clear();
    _playerStats.clear();
  }

  /// Méthode pour initialiser avec des données de test
  static void initializeWithSampleData() {
    if (kDebugMode) {
      // Ajout de quelques données de test
      final testPlayer = Player(
        id: 'test-player-1',
        pseudo: 'Faker',
        inGameId: 'Hide on bush',
        game: Game.leagueOfLegends,
        role: 'Mid',
        realName: 'Lee Sang-hyeok',
        region: 'KR',
        rank: 'Challenger',
        createdAt: DateTime.now(),
      );

      final testTeam = Team(
        id: 'test-team-1',
        name: 'T1',
        description: 'Équipe légendaire de League of Legends',
        game: Game.leagueOfLegends,
        playerIds: [testPlayer.id],
        createdAt: DateTime.now(),
      );

      _players[testPlayer.id] = testPlayer;
      _teams[testTeam.id] = testTeam;
    }
  }
}