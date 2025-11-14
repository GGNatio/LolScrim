import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';
import 'storage_service_new.dart' as json_service;

/// Service de stockage qui utilise le nouveau système JSON Windows
class StorageService {
  /// Initialisation
  static Future<void> initialize() async {
    await json_service.JsonStorageService.initialize();
  }

  /// ============ GESTION DES JOUEURS ============
  
  static Future<List<Player>> getPlayers() async {
    return json_service.JsonStorageService.getPlayers();
  }

  static Future<void> insertPlayer(Player player) async {
    return json_service.JsonStorageService.insertPlayer(player);
  }

  static Future<void> updatePlayer(Player player) async {
    return json_service.JsonStorageService.updatePlayer(player);
  }

  static Future<void> deletePlayer(String id) async {
    return json_service.JsonStorageService.deletePlayer(id);
  }

  /// ============ GESTION DES ÉQUIPES ============
  
  static Future<List<Team>> getTeams() async {
    return json_service.JsonStorageService.getTeams();
  }

  static Future<void> insertTeam(Team team) async {
    return json_service.JsonStorageService.insertTeam(team);
  }

  static Future<void> updateTeam(Team team) async {
    return json_service.JsonStorageService.updateTeam(team);
  }

  static Future<void> deleteTeam(String id) async {
    return json_service.JsonStorageService.deleteTeam(id);
  }

  /// ============ GESTION DES SCRIMS ============
  
  static Future<List<Scrim>> getScrims() async {
    return json_service.JsonStorageService.getScrims();
  }

  static Future<void> insertScrim(Scrim scrim) async {
    return json_service.JsonStorageService.insertScrim(scrim);
  }

  static Future<void> updateScrim(Scrim scrim) async {
    return json_service.JsonStorageService.updateScrim(scrim);
  }

  static Future<void> deleteScrim(String id) async {
    return json_service.JsonStorageService.deleteScrim(id);
  }

  /// ============ GESTION DES STATS JOUEURS ============
  
  static Future<List<PlayerStats>> getPlayerStats({String? scrimId, String? playerId}) async {
    return json_service.JsonStorageService.getPlayerStats(scrimId: scrimId, playerId: playerId);
  }

  static Future<void> insertPlayerStats(String scrimId, List<PlayerStats> playerStats) async {
    return json_service.JsonStorageService.insertPlayerStats(scrimId, playerStats);
  }

  /// ============ MÉTHODES UTILITAIRES ============

  static Future<void> forceSave() async {
    await json_service.JsonStorageService.forceSave();
  }

  static Future<void> clearAll() async {
    await json_service.JsonStorageService.clearAll();
  }

  static Future<void> debugReport() async {
    await json_service.JsonStorageService.debugReport();
  }

  /// Exporte toutes les données en JSON pour sauvegarde
  static Future<Map<String, dynamic>> exportData() async {
    final players = await getPlayers();
    final teams = await getTeams();
    final scrims = await getScrims();
    
    return {
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'players': players.map((p) => p.toMap()).toList(),
      'teams': teams.map((t) => t.toMap()).toList(),
      'scrims': scrims.map((s) => s.toMap()).toList(),
    };
  }

  /// Importe des données depuis JSON
  static Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Vider les données existantes
      await clearAll();
      
      // Importer les joueurs
      if (data['players'] != null) {
        final playersData = data['players'] as List<dynamic>;
        for (final playerMap in playersData) {
          final player = Player.fromMap(playerMap);
          await insertPlayer(player);
        }
      }
      
      // Importer les équipes
      if (data['teams'] != null) {
        final teamsData = data['teams'] as List<dynamic>;
        for (final teamMap in teamsData) {
          final team = Team.fromMap(teamMap);
          await insertTeam(team);
        }
      }
      
      // Importer les scrims
      if (data['scrims'] != null) {
        final scrimsData = data['scrims'] as List<dynamic>;
        for (final scrimMap in scrimsData) {
          final scrim = Scrim.fromMap(scrimMap);
          await insertScrim(scrim);
        }
      }
      
      print('✅ Données importées avec succès');
    } catch (e) {
      print('❌ Erreur import données: $e');
      rethrow;
    }
  }
}