import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/player_stats.dart';

/// Service de base de données pour l'application LoL Scrim
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'lol_scrim.db';
  static const int _databaseVersion = 1;

  /// Obtient l'instance de la base de données (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initializeDatabase();
    return _database!;
  }

  /// Initialise la base de données et crée les tables
  static Future<Database> _initializeDatabase() async {
    // Initialiser la factory pour le web
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }
    
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    print('🗄️  Création base SQLite: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Crée toutes les tables nécessaires
  static Future<void> _createTables(Database db, int version) async {
    // Table des joueurs
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        pseudo TEXT NOT NULL,
        role TEXT NOT NULL,
        real_name TEXT,
        region TEXT,
        rank TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // Table des équipes
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        logo_url TEXT,
        game TEXT NOT NULL,
        player_ids TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    // Table des scrims
    await db.execute('''
      CREATE TABLE scrims (
        id TEXT PRIMARY KEY,
        my_team_id TEXT NOT NULL,
        enemy_team_name TEXT,
        enemy_champions TEXT NOT NULL,
        my_team_score INTEGER NOT NULL,
        enemy_team_score INTEGER NOT NULL,
        is_victory INTEGER NOT NULL,
        match_date TEXT NOT NULL,
        patch TEXT,
        match_duration INTEGER,
        notes TEXT,
        FOREIGN KEY (my_team_id) REFERENCES teams (id)
      )
    ''');

    // Table des statistiques des joueurs par scrim
    await db.execute('''
      CREATE TABLE player_stats (
        id TEXT PRIMARY KEY,
        scrim_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        champion TEXT NOT NULL,
        kills INTEGER NOT NULL,
        deaths INTEGER NOT NULL,
        assists INTEGER NOT NULL,
        creep_score INTEGER,
        damage INTEGER,
        vision_score INTEGER,
        gold INTEGER,
        FOREIGN KEY (scrim_id) REFERENCES scrims (id),
        FOREIGN KEY (player_id) REFERENCES players (id)
      )
    ''');

    // Index pour améliorer les performances des requêtes
    await db.execute('CREATE INDEX idx_scrims_team ON scrims (my_team_id)');
    await db.execute('CREATE INDEX idx_scrims_date ON scrims (match_date)');
    await db.execute('CREATE INDEX idx_player_stats_scrim ON player_stats (scrim_id)');
    await db.execute('CREATE INDEX idx_player_stats_player ON player_stats (player_id)');
    await db.execute('CREATE INDEX idx_player_stats_champion ON player_stats (champion)');
  }

  /// Gère la mise à jour de la base de données
  static Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations de schéma si nécessaire
    if (oldVersion < 2) {
      // Exemple de migration pour une future version
      // await db.execute('ALTER TABLE players ADD COLUMN new_field TEXT');
    }
  }

  /// Ferme la base de données
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Supprime la base de données (utile pour les tests)
  static Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Méthodes CRUD pour les joueurs

  /// Insert ou update un joueur
  static Future<void> insertPlayer(Player player) async {
    final db = await database;
    await db.insert(
      'players',
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère tous les joueurs
  static Future<List<Player>> getAllPlayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    return maps.map((map) => Player.fromMap(map)).toList();
  }

  /// Récupère un joueur par son ID
  static Future<Player?> getPlayerById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Player.fromMap(maps.first) : null;
  }

  /// Met à jour un joueur
  static Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  /// Supprime un joueur
  static Future<void> deletePlayer(String id) async {
    final db = await database;
    await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes CRUD pour les équipes

  /// Insert ou update une équipe
  static Future<void> insertTeam(Team team) async {
    final db = await database;
    await db.insert(
      'teams',
      team.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les équipes
  static Future<List<Team>> getAllTeams() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('teams');
    return maps.map((map) => Team.fromMap(map)).toList();
  }

  /// Récupère une équipe par son ID
  static Future<Team?> getTeamById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'teams',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Team.fromMap(maps.first) : null;
  }

  /// Met à jour une équipe
  static Future<void> updateTeam(Team team) async {
    final db = await database;
    await db.update(
      'teams',
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  /// Supprime une équipe
  static Future<void> deleteTeam(String id) async {
    final db = await database;
    
    // Supprimer d'abord les scrims associés
    await db.delete(
      'scrims',
      where: 'my_team_id = ?',
      whereArgs: [id],
    );
    
    // Puis supprimer l'équipe
    await db.delete(
      'teams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Méthodes CRUD pour les scrims

  /// Insert ou update un scrim avec ses statistiques
  static Future<void> insertScrim(Scrim scrim) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Insérer le scrim
      await txn.insert(
        'scrims',
        scrim.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // Supprimer les anciennes stats si elles existent
      await txn.delete(
        'player_stats',
        where: 'scrim_id = ?',
        whereArgs: [scrim.id],
      );
      
      // Insérer les nouvelles stats
      for (final stats in scrim.myTeamStats) {
        await txn.insert(
          'player_stats',
          {
            'id': '${scrim.id}_${stats.playerId}',
            'scrim_id': scrim.id,
            ...stats.toMap(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Récupère tous les scrims avec leurs statistiques
  static Future<List<Scrim>> getAllScrims() async {
    final db = await database;
    
    // Récupérer tous les scrims
    final List<Map<String, dynamic>> scrimMaps = await db.query(
      'scrims',
      orderBy: 'match_date DESC',
    );
    
    final scrims = <Scrim>[];
    
    for (final scrimMap in scrimMaps) {
      // Récupérer les stats pour ce scrim
      final List<Map<String, dynamic>> statsMaps = await db.query(
        'player_stats',
        where: 'scrim_id = ?',
        whereArgs: [scrimMap['id']],
      );
      
      final playerStats = statsMaps.map((map) => PlayerStats.fromMap(map)).toList();
      
      scrims.add(Scrim.fromMap(scrimMap).copyWith(myTeamStats: playerStats));
    }
    
    return scrims;
  }

  /// Récupère les scrims d'une équipe spécifique
  static Future<List<Scrim>> getScrimsByTeamId(String teamId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> scrimMaps = await db.query(
      'scrims',
      where: 'my_team_id = ?',
      whereArgs: [teamId],
      orderBy: 'match_date DESC',
    );
    
    final scrims = <Scrim>[];
    
    for (final scrimMap in scrimMaps) {
      final List<Map<String, dynamic>> statsMaps = await db.query(
        'player_stats',
        where: 'scrim_id = ?',
        whereArgs: [scrimMap['id']],
      );
      
      final playerStats = statsMaps.map((map) => PlayerStats.fromMap(map)).toList();
      
      scrims.add(Scrim.fromMap(scrimMap).copyWith(myTeamStats: playerStats));
    }
    
    return scrims;
  }

  /// Récupère un scrim par son ID
  static Future<Scrim?> getScrimById(String id) async {
    final db = await database;
    
    final List<Map<String, dynamic>> scrimMaps = await db.query(
      'scrims',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (scrimMaps.isEmpty) return null;
    
    final List<Map<String, dynamic>> statsMaps = await db.query(
      'player_stats',
      where: 'scrim_id = ?',
      whereArgs: [id],
    );
    
    final playerStats = statsMaps.map((map) => PlayerStats.fromMap(map)).toList();
    
    return Scrim.fromMap(scrimMaps.first).copyWith(myTeamStats: playerStats);
  }

  /// Supprime un scrim
  static Future<void> deleteScrim(String id) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Supprimer les stats associées
      await txn.delete(
        'player_stats',
        where: 'scrim_id = ?',
        whereArgs: [id],
      );
      
      // Supprimer le scrim
      await txn.delete(
        'scrims',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Récupère les statistiques d'un joueur spécifique
  static Future<List<PlayerStats>> getPlayerStatsForPlayer(String playerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'player_stats',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
    return maps.map((map) => PlayerStats.fromMap(map)).toList();
  }
}