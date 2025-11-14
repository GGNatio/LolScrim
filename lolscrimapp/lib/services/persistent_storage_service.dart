import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// Import conditionnel pour le web
import 'dart:html' as html show window;
import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';

/// Service de stockage persistant utilisant SharedPreferences (web) et fichiers JSON (native)
class PersistentStorageService {
  static const String _playersKey = 'lol_scrim_players';
  static const String _teamsKey = 'lol_scrim_teams';
  static const String _scrimsKey = 'lol_scrim_scrims';
  static const String _playerStatsKey = 'lol_scrim_player_stats';

  // Collections en mémoire pour les performances
  static final Map<String, Player> _players = {};
  static final Map<String, Team> _teams = {};
  static final Map<String, Scrim> _scrims = {};
  static final Map<String, PlayerStats> _playerStats = {};

  static bool _isInitialized = false;

  /// Initialise le service et charge les données sauvegardées
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadAllData();
      _isInitialized = true;
      
      // Si aucune donnée n'existe, créer des données de test
      if (_teams.isEmpty && _players.isEmpty) {
        await _createSampleData();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du stockage: $e');
      // En cas d'erreur, créer des données de test
      await _createSampleData();
      _isInitialized = true;
    }
  }

  /// Charge toutes les données depuis le stockage persistant
  static Future<void> _loadAllData() async {
    debugPrint('🚀 Début du chargement des données...');
    await Future.wait([
      _loadPlayers(),
      _loadTeams(),
      _loadScrims(),
      _loadPlayerStats(),
    ]);
    debugPrint('📊 Chargement terminé: ${_players.length} joueurs, ${_teams.length} équipes, ${_scrims.length} scrims');
  }

  /// Sauvegarde toutes les données
  static Future<void> _saveAllData() async {
    await Future.wait([
      _savePlayers(),
      _saveTeams(),
      _saveScrims(),
      _savePlayerStats(),
    ]);
  }

  // ============ GESTION DES JOUEURS ============

  static Future<List<Player>> getPlayers() async {
    await initialize();
    return _players.values.toList();
  }

  static Future<void> insertPlayer(Player player) async {
    await initialize();
    _players[player.id] = player;
    await _savePlayers();
  }

  static Future<void> updatePlayer(Player player) async {
    await initialize();
    _players[player.id] = player;
    await _savePlayers();
  }

  static Future<void> deletePlayer(String id) async {
    await initialize();
    _players.remove(id);
    await _savePlayers();
  }

  static Future<void> _loadPlayers() async {
    try {
      final data = await _loadData(_playersKey);
      if (data != null) {
        final List<dynamic> playersList = jsonDecode(data);
        _players.clear();
        for (final playerJson in playersList) {
          final player = Player.fromMap(playerJson);
          _players[player.id] = player;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des joueurs: $e');
    }
  }

  static Future<void> _savePlayers() async {
    try {
      final playersList = _players.values.map((player) => player.toMap()).toList();
      final jsonData = jsonEncode(playersList);
      await _saveData(_playersKey, jsonData);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des joueurs: $e');
    }
  }

  // ============ GESTION DES ÉQUIPES ============

  static Future<List<Team>> getTeams() async {
    await initialize();
    return _teams.values.toList();
  }

  static Future<void> insertTeam(Team team) async {
    await initialize();
    _teams[team.id] = team;
    await _saveTeams();
  }

  static Future<void> updateTeam(Team team) async {
    await initialize();
    _teams[team.id] = team;
    await _saveTeams();
  }

  static Future<void> deleteTeam(String id) async {
    await initialize();
    _teams.remove(id);
    await _saveTeams();
  }

  static Future<void> _loadTeams() async {
    try {
      final data = await _loadData(_teamsKey);
      if (data != null) {
        debugPrint('📝 Données équipes trouvées: ${data.substring(0, data.length > 100 ? 100 : data.length)}...');
        final List<dynamic> teamsList = jsonDecode(data);
        _teams.clear();
        for (final teamJson in teamsList) {
          final team = Team.fromMap(teamJson);
          _teams[team.id] = team;
        }
        debugPrint('✅ ${_teams.length} équipes chargées avec succès');
      } else {
        debugPrint('❌ Aucune donnée d\'équipe trouvée');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement des équipes: $e');
    }
  }

  static Future<void> _saveTeams() async {
    try {
      final teamsList = _teams.values.map((team) => team.toMap()).toList();
      final jsonData = jsonEncode(teamsList);
      await _saveData(_teamsKey, jsonData);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des équipes: $e');
    }
  }

  // ============ GESTION DES SCRIMS ============

  static Future<List<Scrim>> getScrims() async {
    await initialize();
    return _scrims.values.toList();
  }

  static Future<void> insertScrim(Scrim scrim) async {
    await initialize();
    _scrims[scrim.id] = scrim;
    await _saveScrims();
  }

  static Future<void> updateScrim(Scrim scrim) async {
    await initialize();
    _scrims[scrim.id] = scrim;
    await _saveScrims();
  }

  static Future<void> deleteScrim(String id) async {
    await initialize();
    _scrims.remove(id);
    await _saveScrims();
  }

  static Future<void> _loadScrims() async {
    try {
      final data = await _loadData(_scrimsKey);
      if (data != null) {
        final List<dynamic> scrimsList = jsonDecode(data);
        _scrims.clear();
        for (final scrimJson in scrimsList) {
          final scrim = Scrim.fromMap(scrimJson);
          _scrims[scrim.id] = scrim;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des scrims: $e');
    }
  }

  static Future<void> _saveScrims() async {
    try {
      final scrimsList = _scrims.values.map((scrim) => scrim.toMap()).toList();
      final jsonData = jsonEncode(scrimsList);
      await _saveData(_scrimsKey, jsonData);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des scrims: $e');
    }
  }

  // ============ GESTION DES STATS JOUEURS ============

  static Future<List<PlayerStats>> getPlayerStats({String? scrimId, String? playerId}) async {
    await initialize();
    final allStats = _playerStats.values.toList();
    
    if (playerId != null) {
      return allStats.where((stats) => stats.playerId == playerId).toList();
    }
    
    return allStats;
  }

  static Future<void> insertPlayerStats(String scrimId, PlayerStats playerStats) async {
    await initialize();
    final key = '${scrimId}_${playerStats.playerId}';
    _playerStats[key] = playerStats;
    await _savePlayerStats();
  }

  static Future<void> updatePlayerStats(String scrimId, PlayerStats playerStats) async {
    await initialize();
    final key = '${scrimId}_${playerStats.playerId}';
    _playerStats[key] = playerStats;
    await _savePlayerStats();
  }

  static Future<void> deletePlayerStats(String scrimId, String playerId) async {
    await initialize();
    final key = '${scrimId}_$playerId';
    _playerStats.remove(key);
    await _savePlayerStats();
  }

  static Future<void> _loadPlayerStats() async {
    try {
      final data = await _loadData(_playerStatsKey);
      if (data != null) {
        final Map<String, dynamic> statsMap = jsonDecode(data);
        _playerStats.clear();
        statsMap.forEach((key, value) {
          final playerStats = PlayerStats.fromMap(value);
          _playerStats[key] = playerStats;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
    }
  }

  static Future<void> _savePlayerStats() async {
    try {
      final statsMap = <String, dynamic>{};
      _playerStats.forEach((key, stats) {
        statsMap[key] = stats.toMap();
      });
      final jsonData = jsonEncode(statsMap);
      await _saveData(_playerStatsKey, jsonData);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des statistiques: $e');
    }
  }

  // ============ MÉTHODES DE STOCKAGE PLATFORM-SPECIFIC ============

  /// Charge une donnée par sa clé
  static Future<String?> _loadData(String key) async {
    if (kIsWeb) {
      // Web: utiliser localStorage avec préfixe pour éviter les conflits de ports Flutter
      try {
        // Diagnostic complet au premier chargement
        if (key == _teamsKey) {
          debugPrint('🔍 === DIAGNOSTIC COMPLET localStorage ===');
          final allKeys = html.window.localStorage.keys.toList();
          debugPrint('📋 Toutes les clés localStorage (${allKeys.length}):');
          for (final k in allKeys) {
            if (k.contains('lolscrim')) {
              final value = html.window.localStorage[k];
              debugPrint('  🔑 $k: ${value?.length ?? 0} chars');
            }
          }
          debugPrint('🔍 === FIN DIAGNOSTIC ===');
        }
        
        // Ajouter un préfixe unique pour survivre aux changements de ports
        final prefixedKey = 'lolscrimapp_stable_$key';
        final data = html.window.localStorage[prefixedKey];
        debugPrint('🔍 localStorage stable [$key]: ${data != null ? '${data.length} chars' : 'vide'}');
        debugPrint('  Clé complète recherchée: $prefixedKey');
        
        if (data != null && data.isNotEmpty) {
          debugPrint('📝 Données trouvées: ${data.substring(0, data.length > 100 ? 100 : data.length)}...');
        }
        return data;
      } catch (e) {
        debugPrint('❌ Erreur localStorage [$key]: $e');
        return null;
      }
    } else {
      // Native: utiliser fichier JSON
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File(path.join(directory.path, '$key.json'));
        
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (e) {
        debugPrint('Erreur lors de la lecture du fichier $key: $e');
      }
      return null;
    }
  }

  /// Sauvegarde une donnée avec sa clé
  static Future<void> _saveData(String key, String data) async {
    if (kIsWeb) {
      // Web: localStorage avec préfixe stable pour survivre aux redémarrages Flutter
      try {
        // Utiliser le même préfixe que pour le chargement
        final prefixedKey = 'lolscrimapp_stable_$key';
        html.window.localStorage[prefixedKey] = data;
        debugPrint('💾 localStorage stable [$key]: ${data.length} chars sauvegardés');
        
        // Vérification immédiate
        final verif = html.window.localStorage[prefixedKey];
        if (verif == data) {
          debugPrint('✅ Sauvegarde stable [$key]: SUCCÈS');
        } else {
          debugPrint('❌ Sauvegarde stable [$key]: ÉCHEC');
        }
        
      } catch (e) {
        debugPrint('❌ Erreur sauvegarde stable [$key]: $e');
      }
    } else {
      // Native: utiliser fichier JSON
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File(path.join(directory.path, '$key.json'));
        await file.writeAsString(data);
      } catch (e) {
        debugPrint('Erreur lors de l\'écriture du fichier $key: $e');
      }
    }
  }

  /// Crée des données de test si aucune donnée n'existe (désactivé par défaut)
  static Future<void> _createSampleData() async {
    // Désactivé - ne plus créer de données de test automatiquement
    // Les utilisateurs créeront leurs propres données via l'interface
    debugPrint('Aucune donnée de test créée - interface vide prête pour l\'utilisateur');
  }

  /// Vide toutes les données (pour les tests)
  static Future<void> clearAll() async {
    _players.clear();
    _teams.clear();
    _scrims.clear();
    _playerStats.clear();
    await _saveAllData();
  }

  /// Force une sauvegarde complète
  static Future<void> forceSave() async {
    await _saveAllData();
  }

  /// Affiche un rapport de debug sur le stockage
  static Future<void> debugStorageReport() async {
    debugPrint('📋 === RAPPORT STOCKAGE STABLE ===');
    debugPrint('🎮 En mémoire: ${_players.length} joueurs, ${_teams.length} équipes, ${_scrims.length} scrims');
    
    if (kIsWeb) {
      try {
        final localStorage = html.window.localStorage;
        final stableKeys = localStorage.keys.where((key) => key.startsWith('lolscrimapp_stable_'));
        debugPrint('🌐 localStorage stable: ${stableKeys.length} clés trouvées');
        for (final key in stableKeys) {
          final data = localStorage[key];
          final cleanKey = key.replaceFirst('lolscrimapp_stable_', '');
          debugPrint('  [$cleanKey]: ${data?.length ?? 0} caractères');
          if (data != null && data.isNotEmpty) {
            debugPrint('    Contenu: ${data.substring(0, data.length > 50 ? 50 : data.length)}...');
          }
        }
      } catch (e) {
        debugPrint('❌ Erreur accès localStorage stable: $e');
      }
    } else {
      debugPrint('💻 Mode native: fichiers JSON dans documents/');
    }
    debugPrint('📋 === FIN RAPPORT ===');
  }
}