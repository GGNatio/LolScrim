import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:html' as html;
// IndexedDB non disponible dans ce contexte - utiliser alternative
// import 'dart:indexed_db';
import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';

/// Service de stockage persistant utilisant IndexedDB pour une vraie persistance web
class IndexedDbStorageService {
  static const String _dbName = 'LolScrimManagerDB';
  static const String _dbVersion = '1';
  static const int _version = 1;
  
  static const String _teamsStore = 'teams';
  static const String _playersStore = 'players';
  static const String _scrimsStore = 'scrims';
  static const String _statsStore = 'player_stats';

  static Database? _db;
  static bool _isInitialized = false;

  /// Initialise IndexedDB
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (!kIsWeb) {
      print('⚠️  IndexedDB n\'est disponible que sur le web');
      _isInitialized = true;
      return;
    }

    try {
      print('🗄️  Initialisation IndexedDB: $_dbName');
      
      _db = await html.window.indexedDB!.open(_dbName, version: _version, onUpgradeNeeded: (event) {
        final db = event.target.result as Database;
        print('🔨 Création des stores IndexedDB...');
        
        // Créer les object stores
        if (!db.objectStoreNames!.contains(_teamsStore)) {
          db.createObjectStore(_teamsStore, keyPath: 'id');
        }
        if (!db.objectStoreNames!.contains(_playersStore)) {
          db.createObjectStore(_playersStore, keyPath: 'id');
        }
        if (!db.objectStoreNames!.contains(_scrimsStore)) {
          db.createObjectStore(_scrimsStore, keyPath: 'id');
        }
        if (!db.objectStoreNames!.contains(_statsStore)) {
          db.createObjectStore(_statsStore, keyPath: 'id');
        }
        
        print('✅ Stores IndexedDB créés');
      });
      
      _isInitialized = true;
      print('✅ IndexedDB initialisé avec succès');
      
      // Afficher les stats
      await _printStats();
      
    } catch (e) {
      print('❌ Erreur initialisation IndexedDB: $e');
      _isInitialized = true; // Continuer quand même
    }
  }

  /// Affiche les statistiques
  static Future<void> _printStats() async {
    try {
      final teams = await getTeams();
      final players = await getPlayers();
      final scrims = await getScrims();
      print('📊 IndexedDB: ${players.length} joueurs, ${teams.length} équipes, ${scrims.length} scrims');
    } catch (e) {
      print('❌ Erreur stats IndexedDB: $e');
    }
  }

  // ============ GESTION DES ÉQUIPES ============

  static Future<List<Team>> getTeams() async {
    await initialize();
    if (_db == null) return [];

    try {
      final transaction = _db!.transaction(_teamsStore, 'readonly');
      final store = transaction.objectStore(_teamsStore);
      final request = store.getAll();
      
      final result = await request.future;
      final teams = <Team>[];
      
      for (final item in result) {
        try {
          final team = Team.fromMap(Map<String, dynamic>.from(item));
          teams.add(team);
        } catch (e) {
          print('❌ Erreur parsing équipe: $e');
        }
      }
      
      return teams;
    } catch (e) {
      print('❌ Erreur chargement équipes IndexedDB: $e');
      return [];
    }
  }

  static Future<void> insertTeam(Team team) async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_teamsStore, 'readwrite');
      final store = transaction.objectStore(_teamsStore);
      
      await store.put(team.toMap());
      await transaction.completed;
      
      print('✅ Équipe sauvegardée dans IndexedDB: ${team.name}');
    } catch (e) {
      print('❌ Erreur sauvegarde équipe IndexedDB: $e');
      rethrow;
    }
  }

  static Future<void> updateTeam(Team team) async {
    return insertTeam(team); // IndexedDB put() fait update ou insert
  }

  static Future<void> deleteTeam(String id) async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_teamsStore, 'readwrite');
      final store = transaction.objectStore(_teamsStore);
      
      await store.delete(id);
      await transaction.completed;
      
      print('✅ Équipe supprimée d\'IndexedDB: $id');
    } catch (e) {
      print('❌ Erreur suppression équipe IndexedDB: $e');
    }
  }

  // ============ GESTION DES JOUEURS ============

  static Future<List<Player>> getPlayers() async {
    await initialize();
    if (_db == null) return [];

    try {
      final transaction = _db!.transaction(_playersStore, 'readonly');
      final store = transaction.objectStore(_playersStore);
      final request = store.getAll();
      
      final result = await request.future;
      final players = <Player>[];
      
      for (final item in result) {
        try {
          final player = Player.fromMap(Map<String, dynamic>.from(item));
          players.add(player);
        } catch (e) {
          print('❌ Erreur parsing joueur: $e');
        }
      }
      
      return players;
    } catch (e) {
      print('❌ Erreur chargement joueurs IndexedDB: $e');
      return [];
    }
  }

  static Future<void> insertPlayer(Player player) async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_playersStore, 'readwrite');
      final store = transaction.objectStore(_playersStore);
      
      await store.put(player.toMap());
      await transaction.completed;
      
      print('✅ Joueur sauvegardé dans IndexedDB: ${player.name}');
    } catch (e) {
      print('❌ Erreur sauvegarde joueur IndexedDB: $e');
      rethrow;
    }
  }

  static Future<void> updatePlayer(Player player) async {
    return insertPlayer(player);
  }

  static Future<void> deletePlayer(String id) async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_playersStore, 'readwrite');
      final store = transaction.objectStore(_playersStore);
      
      await store.delete(id);
      await transaction.completed;
      
      print('✅ Joueur supprimé d\'IndexedDB: $id');
    } catch (e) {
      print('❌ Erreur suppression joueur IndexedDB: $e');
    }
  }

  // ============ GESTION DES SCRIMS ============

  static Future<List<Scrim>> getScrims() async {
    await initialize();
    if (_db == null) return [];

    try {
      final transaction = _db!.transaction(_scrimsStore, 'readonly');
      final store = transaction.objectStore(_scrimsStore);
      final request = store.getAll();
      
      final result = await request.future;
      final scrims = <Scrim>[];
      
      for (final item in result) {
        try {
          final scrim = Scrim.fromMap(Map<String, dynamic>.from(item));
          scrims.add(scrim);
        } catch (e) {
          print('❌ Erreur parsing scrim: $e');
        }
      }
      
      return scrims;
    } catch (e) {
      print('❌ Erreur chargement scrims IndexedDB: $e');
      return [];
    }
  }

  static Future<void> insertScrim(Scrim scrim) async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_scrimsStore, 'readwrite');
      final store = transaction.objectStore(_scrimsStore);
      
      await store.put(scrim.toMap());
      await transaction.completed;
      
      print('✅ Scrim sauvegardé dans IndexedDB: ${scrim.id}');
    } catch (e) {
      print('❌ Erreur sauvegarde scrim IndexedDB: $e');
      rethrow;
    }
  }

  static Future<void> updateScrim(Scrim scrim) async {
    return insertScrim(scrim);
  }

  static Future<void> deleteScrim(String id) async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction(_scrimsStore, 'readwrite');
      final store = transaction.objectStore(_scrimsStore);
      
      await store.delete(id);
      await transaction.completed;
      
      print('✅ Scrim supprimé d\'IndexedDB: $id');
    } catch (e) {
      print('❌ Erreur suppression scrim IndexedDB: $e');
    }
  }

  // ============ GESTION DES STATS ============

  static Future<List<PlayerStats>> getPlayerStats({String? scrimId, String? playerId}) async {
    await initialize();
    if (_db == null) return [];

    // Pour l'instant, retourner liste vide (à implémenter plus tard)
    return [];
  }

  static Future<void> insertPlayerStats(String scrimId, List<PlayerStats> playerStats) async {
    // À implémenter plus tard
    print('⚠️  insertPlayerStats IndexedDB: pas encore implémenté');
  }

  // ============ MÉTHODES UTILITAIRES ============

  static Future<void> clearAll() async {
    await initialize();
    if (_db == null) return;

    try {
      final transaction = _db!.transaction([_teamsStore, _playersStore, _scrimsStore], 'readwrite');
      
      await transaction.objectStore(_teamsStore).clear();
      await transaction.objectStore(_playersStore).clear();
      await transaction.objectStore(_scrimsStore).clear();
      
      await transaction.completed;
      print('🗑️  IndexedDB vidé');
    } catch (e) {
      print('❌ Erreur vidage IndexedDB: $e');
    }
  }

  static Future<void> debugReport() async {
    print('📋 === RAPPORT INDEXEDDB ===');
    await _printStats();
    print('🗄️  Base: $_dbName v$_version');
    print('📋 === FIN RAPPORT ===');
  }
}