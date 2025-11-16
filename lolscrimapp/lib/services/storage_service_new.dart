import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';

/// Service de stockage JSON local - crée et gère des fichiers JSON sur Windows
class JsonStorageService {
  // Noms des fichiers JSON
  static const String _playersFile = 'players.json';
  static const String _teamsFile = 'teams.json';
  static const String _scrimsFile = 'scrims.json';
  static const String _playerStatsFile = 'player_stats.json';

  // Collections en mémoire pour performance
  static final Map<String, Player> _players = {};
  static final Map<String, Team> _teams = {};
  static final Map<String, Scrim> _scrims = {};
  static final Map<String, List<PlayerStats>> _playerStats = {};

  static String? _appDirectory;
  static bool _isInitialized = false;

  /// Initialisation - Crée le dossier et les fichiers JSON s'ils n'existent pas
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🗄️  Initialisation du stockage JSON local...');
      
      // Obtenir le dossier Documents de l'utilisateur
      final documentsDir = await getApplicationDocumentsDirectory();
      _appDirectory = path.join(documentsDir.path, 'LolScrimManager');
      
      // Créer le dossier s'il n'existe pas
      final appDir = Directory(_appDirectory!);
      if (!await appDir.exists()) {
        await appDir.create(recursive: true);
        print('📁 Dossier créé: $_appDirectory');
      } else {
        print('📁 Dossier existant: $_appDirectory');
      }

      // Créer les fichiers JSON s'ils n'existent pas et charger les données
      await _ensureFilesExist();
      await _loadAllData();
      
      _isInitialized = true;
      print('✅ Stockage JSON initialisé avec succès');
      print('📊 Données chargées: ${_players.length} joueurs, ${_teams.length} équipes, ${_scrims.length} scrims');
      
    } catch (e) {
      print('❌ Erreur initialisation stockage JSON: $e');
      _isInitialized = true; // Continuer quand même
    }
  }

  /// S'assure que tous les fichiers JSON existent
  static Future<void> _ensureFilesExist() async {
    final files = [_playersFile, _teamsFile, _scrimsFile];
    
    for (final fileName in files) {
      final file = File(path.join(_appDirectory!, fileName));
      if (!await file.exists()) {
        await file.writeAsString('[]'); // Créer avec liste vide
        print('📄 Fichier créé: $fileName');
      } else {
        print('📄 Fichier existant: $fileName');
      }
    }
    
    // Player stats nécessite un objet, pas une liste
    final statsFile = File(path.join(_appDirectory!, _playerStatsFile));
    if (!await statsFile.exists()) {
      await statsFile.writeAsString('{}'); // Créer avec objet vide
      print('📄 Fichier créé: $_playerStatsFile');
    } else {
      print('📄 Fichier existant: $_playerStatsFile');
    }
  }

  /// Charge toutes les données depuis les fichiers JSON
  static Future<void> _loadAllData() async {
    await Future.wait([
      _loadPlayers(),
      _loadTeams(),
      _loadScrims(),
      _loadPlayerStats(),
    ]);
  }

  /// ============ GESTION DES JOUEURS ============
  
  static Future<List<Player>> getPlayers() async {
    await initialize();
    return _players.values.toList();
  }

  static Future<void> insertPlayer(Player player) async {
    await initialize();
    _players[player.id] = player;
    await _savePlayers();
    print('✅ Joueur ajouté: ${player.pseudo}');
  }

  static Future<void> updatePlayer(Player player) async {
    await initialize();
    _players[player.id] = player;
    await _savePlayers();
    print('✅ Joueur mis à jour: ${player.pseudo}');
  }

  static Future<void> deletePlayer(String id) async {
    await initialize();
    final player = _players.remove(id);
    if (player != null) {
      await _savePlayers();
      print('✅ Joueur supprimé: ${player.pseudo}');
    }
  }

  static Future<void> _loadPlayers() async {
    try {
      final file = File(path.join(_appDirectory!, _playersFile));
      final content = await file.readAsString();
      final List<dynamic> playersJson = jsonDecode(content);
      
      _players.clear();
      for (final playerMap in playersJson) {
        final player = Player.fromMap(playerMap);
        _players[player.id] = player;
      }
      print('📂 ${_players.length} joueurs chargés depuis $_playersFile');
    } catch (e) {
      print('❌ Erreur chargement joueurs: $e');
    }
  }

  static Future<void> _savePlayers() async {
    try {
      final file = File(path.join(_appDirectory!, _playersFile));
      final playersJson = _players.values.map((p) => p.toMap()).toList();
      await file.writeAsString(jsonEncode(playersJson));
    } catch (e) {
      print('❌ Erreur sauvegarde joueurs: $e');
    }
  }

  /// ============ GESTION DES ÉQUIPES ============
  
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
      final file = File(path.join(_appDirectory!, _teamsFile));
      final content = await file.readAsString();
      final List<dynamic> teamsJson = jsonDecode(content);
      
      _teams.clear();
      for (final teamMap in teamsJson) {
        final team = Team.fromMap(teamMap);
        _teams[team.id] = team;
      }
      print('📂 ${_teams.length} équipes chargées depuis $_teamsFile');
    } catch (e) {
      print('❌ Erreur chargement équipes: $e');
    }
  }

  static Future<void> _saveTeams() async {
    try {
      final file = File(path.join(_appDirectory!, _teamsFile));
      final teamsJson = _teams.values.map((t) => t.toMap()).toList();
      await file.writeAsString(jsonEncode(teamsJson));
    } catch (e) {
      print('❌ Erreur sauvegarde équipes: $e');
    }
  }

  /// ============ GESTION DES SCRIMS ============
  
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
      final file = File(path.join(_appDirectory!, _scrimsFile));
      final content = await file.readAsString();
      final List<dynamic> scrimsJson = jsonDecode(content);
      
      _scrims.clear();
      for (final scrimMap in scrimsJson) {
        final scrim = Scrim.fromMap(scrimMap);
        _scrims[scrim.id] = scrim;
      }
      print('📂 ${_scrims.length} scrims chargés depuis $_scrimsFile');
    } catch (e) {
      print('❌ Erreur chargement scrims: $e');
    }
  }

  static Future<void> _saveScrims() async {
    try {
      final file = File(path.join(_appDirectory!, _scrimsFile));
      final scrimsJson = _scrims.values.map((s) => s.toMap()).toList();
      await file.writeAsString(jsonEncode(scrimsJson));
    } catch (e) {
      print('❌ Erreur sauvegarde scrims: $e');
    }
  }

  /// ============ GESTION DES STATS JOUEURS ============
  
  static Future<List<PlayerStats>> getPlayerStats({String? scrimId, String? playerId}) async {
    await initialize();
    
    if (playerId != null) {
      return _playerStats[playerId] ?? [];
    }
    
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
      final file = File(path.join(_appDirectory!, _playerStatsFile));
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      
      _playerStats.clear();
      
      // Si c'est une liste vide au lieu d'un objet, créer un objet vide
      if (decoded is List) {
        print('📂 Fichier stats vide ou format liste, initialisation d\'un objet vide');
        return;
      }
      
      final Map<String, dynamic> statsMap = decoded as Map<String, dynamic>;
      
      for (final entry in statsMap.entries) {
        final playerId = entry.key;
        final statsList = entry.value as List<dynamic>;
        _playerStats[playerId] = statsList.map((statJson) => PlayerStats.fromMap(statJson)).toList();
      }
      
      final totalStats = _playerStats.values.fold(0, (sum, stats) => sum + stats.length);
      print('📂 $totalStats stats joueurs chargées depuis $_playerStatsFile');
    } catch (e) {
      print('❌ Erreur chargement stats: $e');
    }
  }

  static Future<void> _savePlayerStats() async {
    try {
      final file = File(path.join(_appDirectory!, _playerStatsFile));
      final statsMap = <String, dynamic>{};
      
      for (final entry in _playerStats.entries) {
        statsMap[entry.key] = entry.value.map((stat) => stat.toMap()).toList();
      }
      
      await file.writeAsString(jsonEncode(statsMap));
    } catch (e) {
      print('❌ Erreur sauvegarde stats: $e');
    }
  }

  /// ============ MÉTHODES UTILITAIRES ============
  
  /// Force une sauvegarde complète de tous les fichiers JSON
  static Future<void> forceSave() async {
    await initialize();
    await Future.wait([
      _savePlayers(),
      _saveTeams(),
      _saveScrims(),
      _savePlayerStats(),
    ]);
    print('💾 Sauvegarde forcée de tous les fichiers JSON terminée');
  }

  /// Vide toutes les données et recrée les fichiers JSON vides
  static Future<void> clearAll() async {
    await initialize();
    
    _players.clear();
    _teams.clear();
    _scrims.clear();
    _playerStats.clear();
    
    // Recréer les fichiers vides
    await _ensureFilesExist();
    await Future.wait([
      _savePlayers(),
      _saveTeams(),
      _saveScrims(),
      _savePlayerStats(),
    ]);
    
    print('🗑️  Toutes les données vidées et fichiers JSON réinitialisés');
  }

  /// Rapport de debug du stockage JSON
  static Future<void> debugReport() async {
    await initialize();
    
    print('📋 === RAPPORT STOCKAGE JSON ===');
    print('📁 Dossier: $_appDirectory');
    print('🎮 En mémoire: ${_players.length} joueurs, ${_teams.length} équipes, ${_scrims.length} scrims');
    
    // Vérifier la taille des fichiers
    try {
      final files = [_playersFile, _teamsFile, _scrimsFile, _playerStatsFile];
      for (final fileName in files) {
        final file = File(path.join(_appDirectory!, fileName));
        if (await file.exists()) {
          final size = await file.length();
          print('📄 $fileName: $size octets');
        } else {
          print('❌ $fileName: fichier manquant');
        }
      }
    } catch (e) {
      print('❌ Erreur vérification fichiers: $e');
    }
    
    print('📋 === FIN RAPPORT ===');
  }
}