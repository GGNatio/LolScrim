import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';

// Import conditionnel pour le stockage web
import 'dart:html' as html show window;
import 'dart:convert';

/// Service de stockage local intelligent qui utilise la meilleure solution par plateforme
class LocalStorageService {
  static const String _playersKey = 'lol_scrim_players';
  static const String _teamsKey = 'lol_scrim_teams';
  static const String _scrimsKey = 'lol_scrim_scrims';
  static const String _playerStatsKey = 'lol_scrim_player_stats';

  // Collections en mémoire pour les performances
  static final Map<String, Player> _players = {};
  static final Map<String, Team> _teams = {};
  static final Map<String, Scrim> _scrims = {};
  static final Map<String, List<PlayerStats>> _playerStats = {};

  static bool _isInitialized = false;

  /// Initialise le service de stockage local
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🗄️  Initialisation du stockage local...');
      
      if (kIsWeb) {
        print('🌐 Mode Web: Utilisation d\'IndexedDB/localStorage amélioré');
      } else {
        print('💻 Mode Desktop: Utilisation de fichiers JSON locaux');
      }

      await _loadAllData();
      _isInitialized = true;
      
      print('✅ Stockage local initialisé avec succès');
      await _printStats();
      
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du stockage: $e');
      _isInitialized = true; // Continuer même en cas d'erreur
    }
  }

  /// Charge toutes les données
  static Future<void> _loadAllData() async {
    print('🔄 Chargement des données locales...');
    await Future.wait([
      _loadPlayers(),
      _loadTeams(),
      _loadScrims(),
      _loadPlayerStats(),
    ]);
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

  /// Affiche les statistiques
  static Future<void> _printStats() async {
    print('📊 Données chargées: ${_players.length} joueurs, ${_teams.length} équipes, ${_scrims.length} scrims');
  }

  // ============ MÉTHODES DE STOCKAGE PLATEFORME-SPÉCIFIQUES ============

  /// Charge des données avec une clé
  static Future<String?> _loadData(String key) async {
    if (kIsWeb) {
      // Web: utiliser localStorage avec préfixe pour éviter les conflits
      try {
        final fullKey = 'lolscrimapp_$key';
        final data = html.window.localStorage[fullKey];
        print('📂 Web [$key]: ${data != null ? '${data.length} caractères' : 'vide'}');
        return data;
      } catch (e) {
        print('❌ Erreur web [$key]: $e');
        return null;
      }
    } else {
      // Desktop: fichiers JSON dans le dossier Documents/LolScrimApp
      try {
        // TODO: Implémenter le stockage fichier pour desktop
        print('💻 Desktop [$key]: pas encore implémenté');
        return null;
      } catch (e) {
        print('❌ Erreur desktop [$key]: $e');
        return null;
      }
    }
  }

  /// Sauvegarde des données avec une clé
  static Future<void> _saveData(String key, String data) async {
    if (kIsWeb) {
      // Web: localStorage avec préfixe
      try {
        final fullKey = 'lolscrimapp_$key';
        html.window.localStorage[fullKey] = data;
        print('💾 Web [$key]: ${data.length} caractères sauvegardés');
        
        // Vérification
        final verification = html.window.localStorage[fullKey];
        if (verification == data) {
          print('✅ Web [$key]: sauvegarde confirmée');
        } else {
          print('❌ Web [$key]: échec de sauvegarde');
        }
      } catch (e) {
        print('❌ Erreur sauvegarde web [$key]: $e');
      }
    } else {
      // Desktop: fichier JSON
      try {
        // TODO: Implémenter la sauvegarde fichier pour desktop
        print('💻 Desktop [$key]: ${data.length} caractères (fichier à implémenter)');
      } catch (e) {
        print('❌ Erreur sauvegarde desktop [$key]: $e');
      }
    }
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
    print('✅ Joueur ajouté: ${player.name}');
  }

  static Future<void> updatePlayer(Player player) async {
    await initialize();
    _players[player.id] = player;
    await _savePlayers();
    print('✅ Joueur mis à jour: ${player.name}');
  }

  static Future<void> deletePlayer(String id) async {
    await initialize();
    final player = _players.remove(id);
    if (player != null) {
      await _savePlayers();
      print('✅ Joueur supprimé: ${player.name}');
    }
  }

  static Future<void> _loadPlayers() async {
    try {
      final data = await _loadData(_playersKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> playersList = jsonDecode(data);
        _players.clear();
        for (final playerJson in playersList) {
          final player = Player.fromMap(playerJson);
          _players[player.id] = player;
        }
        print('✅ ${_players.length} joueurs chargés');
      }
    } catch (e) {
      print('❌ Erreur chargement joueurs: $e');
    }
  }

  static Future<void> _savePlayers() async {
    try {
      final playersList = _players.values.map((player) => player.toMap()).toList();
      final jsonData = jsonEncode(playersList);
      await _saveData(_playersKey, jsonData);
    } catch (e) {
      print('❌ Erreur sauvegarde joueurs: $e');
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
    print('✅ Équipe ajoutée: ${team.name}');
  }

  static Future<void> updateTeam(Team team) async {
    await initialize();
    _teams[team.id] = team;
    await _saveTeams();
    print('✅ Équipe mise à jour: ${team.name}');
  }

  static Future<void> deleteTeam(String id) async {
    await initialize();
    final team = _teams.remove(id);
    if (team != null) {
      await _saveTeams();
      print('✅ Équipe supprimée: ${team.name}');
    }
  }

  static Future<void> _loadTeams() async {
    try {
      final data = await _loadData(_teamsKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> teamsList = jsonDecode(data);
        _teams.clear();
        for (final teamJson in teamsList) {
          final team = Team.fromMap(teamJson);
          _teams[team.id] = team;
        }
        print('✅ ${_teams.length} équipes chargées');
      }
    } catch (e) {
      print('❌ Erreur chargement équipes: $e');
    }
  }

  static Future<void> _saveTeams() async {
    try {
      final teamsList = _teams.values.map((team) => team.toMap()).toList();
      final jsonData = jsonEncode(teamsList);
      await _saveData(_teamsKey, jsonData);
    } catch (e) {
      print('❌ Erreur sauvegarde équipes: $e');
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
    print('✅ Scrim ajouté: ${scrim.id}');
  }

  static Future<void> updateScrim(Scrim scrim) async {
    await initialize();
    _scrims[scrim.id] = scrim;
    await _saveScrims();
    print('✅ Scrim mis à jour: ${scrim.id}');
  }

  static Future<void> deleteScrim(String id) async {
    await initialize();
    final scrim = _scrims.remove(id);
    if (scrim != null) {
      await _saveScrims();
      print('✅ Scrim supprimé: $id');
    }
  }

  static Future<void> _loadScrims() async {
    try {
      final data = await _loadData(_scrimsKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> scrimsList = jsonDecode(data);
        _scrims.clear();
        for (final scrimJson in scrimsList) {
          final scrim = Scrim.fromMap(scrimJson);
          _scrims[scrim.id] = scrim;
        }
        print('✅ ${_scrims.length} scrims chargés');
      }
    } catch (e) {
      print('❌ Erreur chargement scrims: $e');
    }
  }

  static Future<void> _saveScrims() async {
    try {
      final scrimsList = _scrims.values.map((scrim) => scrim.toMap()).toList();
      final jsonData = jsonEncode(scrimsList);
      await _saveData(_scrimsKey, jsonData);
    } catch (e) {
      print('❌ Erreur sauvegarde scrims: $e');
    }
  }

  // ============ GESTION DES STATS JOUEURS ============

  static Future<List<PlayerStats>> getPlayerStats({String? scrimId, String? playerId}) async {
    await initialize();
    
    if (playerId != null) {
      return _playerStats[playerId] ?? [];
    }
    
    // Retourner toutes les stats ou filtrer par scrim
    final allStats = _playerStats.values.expand((stats) => stats).toList();
    if (scrimId != null) {
      return allStats.where((stat) => stat.scrimId == scrimId).toList();
    }
    
    return allStats;
  }

  static Future<void> insertPlayerStats(String scrimId, List<PlayerStats> playerStats) async {
    await initialize();
    for (final stat in playerStats) {
      final playerId = stat.playerId;
      if (!_playerStats.containsKey(playerId)) {
        _playerStats[playerId] = [];
      }
      _playerStats[playerId]!.add(stat);
    }
    await _savePlayerStats();
    print('✅ Stats joueurs ajoutées pour scrim: $scrimId');
  }

  static Future<void> _loadPlayerStats() async {
    try {
      final data = await _loadData(_playerStatsKey);
      if (data != null && data.isNotEmpty) {
        final Map<String, dynamic> statsMap = jsonDecode(data);
        _playerStats.clear();
        for (final entry in statsMap.entries) {
          final playerId = entry.key;
          final statsList = entry.value as List<dynamic>;
          _playerStats[playerId] = statsList.map((statJson) => PlayerStats.fromMap(statJson)).toList();
        }
        final totalStats = _playerStats.values.fold(0, (sum, stats) => sum + stats.length);
        print('✅ $totalStats stats joueurs chargées');
      }
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
    }
  }

  static Future<void> _savePlayerStats() async {
    try {
      final statsMap = <String, dynamic>{};
      for (final entry in _playerStats.entries) {
        statsMap[entry.key] = entry.value.map((stat) => stat.toMap()).toList();
      }
      final jsonData = jsonEncode(statsMap);
      await _saveData(_playerStatsKey, jsonData);
    } catch (e) {
      print('❌ Erreur sauvegarde stats: $e');
    }
  }

  // ============ MÉTHODES UTILITAIRES ============

  /// Vide toutes les données
  static Future<void> clearAll() async {
    _players.clear();
    _teams.clear();
    _scrims.clear();
    _playerStats.clear();
    await _saveAllData();
    print('🗑️  Toutes les données ont été vidées');
  }

  /// Force une sauvegarde complète
  static Future<void> forceSave() async {
    await _saveAllData();
    print('💾 Sauvegarde forcée terminée');
  }

  /// Rapport de debug
  static Future<void> debugReport() async {
    print('📋 === RAPPORT STOCKAGE LOCAL ===');
    await _printStats();
    
    if (kIsWeb) {
      print('🌐 Mode: Web (localStorage avec préfixe lolscrimapp_)');
      try {
        final keys = html.window.localStorage.keys.where((k) => k.startsWith('lolscrimapp_'));
        print('🔑 Clés stockées: ${keys.length}');
        for (final key in keys) {
          final data = html.window.localStorage[key];
          print('  ${key.replaceFirst('lolscrimapp_', '')}: ${data?.length ?? 0} caractères');
        }
      } catch (e) {
        print('❌ Erreur rapport web: $e');
      }
    } else {
      print('💻 Mode: Desktop (fichiers JSON)');
    }
    
    print('📋 === FIN RAPPORT ===');
  }
}