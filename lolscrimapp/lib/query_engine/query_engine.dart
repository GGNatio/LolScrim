import '../models/scrim.dart';
import '../models/player.dart';
import 'query_types.dart';
import 'query_result.dart';

/// Moteur de requêtes statistiques pour les données esport
class QueryEngine {
  /// Exécute une requête avec les paramètres donnés
  static Future<QueryResultSet> executeQuery(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    final stopwatch = Stopwatch()..start();
    final queryId = DateTime.now().millisecondsSinceEpoch.toString();
    
    try {
      List<QueryResult> results;
      
      switch (parameters.queryType) {
        case QueryType.winrateVsChampion:
          results = await _calculateWinrateVsChampion(parameters, scrims, players);
          break;
        case QueryType.averageStatsOnChampion:
          results = await _calculateAverageStatsOnChampion(parameters, scrims, players);
          break;
        case QueryType.performanceVsTeam:
          results = await _calculatePerformanceVsTeam(parameters, scrims, players);
          break;
        case QueryType.championPerformance:
          results = await _calculateChampionPerformance(parameters, scrims, players);
          break;
        case QueryType.roleAnalysis:
          results = await _calculateRoleAnalysis(parameters, scrims, players);
          break;
        case QueryType.patchAnalysis:
          results = await _calculatePatchAnalysis(parameters, scrims, players);
          break;
        case QueryType.recentPerformance:
          results = await _calculateRecentPerformance(parameters, scrims, players);
          break;
      }

      // Application des filtres
      final filteredResults = _applyFilters(results, parameters.filters);
      
      // Tri et limitation
      final finalResults = _applySortingAndLimits(filteredResults, parameters);
      
      stopwatch.stop();
      
      return QueryResultSet(
        queryId: queryId,
        title: _getQueryTitle(parameters),
        results: finalResults,
        summary: _generateSummary(finalResults, parameters),
        executedAt: DateTime.now(),
        executionTime: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return QueryResultSet(
        queryId: queryId,
        title: 'Erreur de requête',
        results: [
          QueryResult.empty(
            id: 'error',
            title: 'Erreur: ${e.toString()}',
          ),
        ],
        executedAt: DateTime.now(),
        executionTime: stopwatch.elapsed,
      );
    }
  }

  /// Calcule le winrate d'un joueur contre des champions spécifiques
  static Future<List<QueryResult>> _calculateWinrateVsChampion(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    if (parameters.playerId == null) return [];

    final playerScrims = scrims.where((scrim) => 
        scrim.myTeamStats.any((stats) => stats.playerId == parameters.playerId)
    ).toList();

    final championWinrates = <String, Map<String, int>>{};

    for (final scrim in playerScrims) {
      for (final enemyChampion in scrim.enemyChampions) {
        final championId = enemyChampion.championId;
        championWinrates.putIfAbsent(championId, () => {'wins': 0, 'total': 0});
        championWinrates[championId]!['total'] = 
            championWinrates[championId]!['total']! + 1;
        
        if (scrim.isVictory == true) {
          championWinrates[championId]!['wins'] = 
              championWinrates[championId]!['wins']! + 1;
        }
      }
    }

    final results = <QueryResult>[];
    for (final entry in championWinrates.entries) {
      final champion = entry.key;
      final stats = entry.value;
      final wins = stats['wins']!;
      final total = stats['total']!;
      final winrate = total > 0 ? wins / total : 0.0;

      results.add(QueryResult.winrate(
        id: 'winrate_vs_$champion',
        title: 'Contre $champion',
        winrate: winrate,
        totalGames: total,
        wins: wins,
      ));
    }

    // Tri par winrate décroissant
    results.sort((a, b) => (b.value as double).compareTo(a.value as double));
    return results;
  }

  /// Calcule les statistiques moyennes d'un joueur sur des champions spécifiques
  static Future<List<QueryResult>> _calculateAverageStatsOnChampion(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    if (parameters.playerId == null) return [];

    final playerStats = <String, List<TeamPlayer>>{};

    for (final scrim in scrims) {
      final stats = scrim.getPlayerStats(parameters.playerId!);
      if (stats != null) {
        playerStats.putIfAbsent(stats.championId, () => []).add(stats);
      }
    }

    final results = <QueryResult>[];
    for (final entry in playerStats.entries) {
      final champion = entry.key;
      final statsList = entry.value;
      
      if (statsList.isEmpty) continue;

      final avgKDA = statsList.map((s) => s.kdaScore).reduce((a, b) => a + b) / statsList.length;
      final totalKills = statsList.fold(0, (sum, s) => sum + (s.kills ?? 0));
      final totalDeaths = statsList.fold(0, (sum, s) => sum + (s.deaths ?? 0));
      final totalAssists = statsList.fold(0, (sum, s) => sum + (s.assists ?? 0));

      results.add(QueryResult.averageKDA(
        id: 'avg_kda_$champion',
        title: 'Stats sur $champion',
        averageKDA: avgKDA,
        totalGames: statsList.length,
        totalKills: totalKills.toDouble(),
        totalDeaths: totalDeaths.toDouble(),
        totalAssists: totalAssists.toDouble(),
      ));
    }

    // Tri par KDA décroissant
    results.sort((a, b) => (b.value as double).compareTo(a.value as double));
    return results;
  }

  /// Calcule la performance d'un joueur contre des équipes spécifiques
  static Future<List<QueryResult>> _calculatePerformanceVsTeam(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    if (parameters.playerId == null) return [];

    final teamPerformance = <String, Map<String, dynamic>>{};

    for (final scrim in scrims) {
      final stats = scrim.getPlayerStats(parameters.playerId!);
      if (stats != null && scrim.enemyTeamName != null) {
        final teamName = scrim.enemyTeamName!;
        
        teamPerformance.putIfAbsent(teamName, () => {
          'games': 0,
          'wins': 0,
          'totalKDA': 0.0,
          'champions': <String>[],
        });

        final teamStats = teamPerformance[teamName]!;
        teamStats['games'] = teamStats['games'] + 1;
        
        if (scrim.isVictory == true) {
          teamStats['wins'] = teamStats['wins'] + 1;
        }
        
        teamStats['totalKDA'] = teamStats['totalKDA'] + stats.kdaScore;
        
        if (!(teamStats['champions'] as List<String>).contains(stats.championId)) {
          (teamStats['champions'] as List<String>).add(stats.championId);
        }
      }
    }

    final results = <QueryResult>[];
    for (final entry in teamPerformance.entries) {
      final teamName = entry.key;
      final performance = entry.value;
      final games = performance['games'] as int;
      final wins = performance['wins'] as int;
      final winrate = games > 0 ? wins / games : 0.0;

      results.add(QueryResult.winrate(
        id: 'performance_vs_$teamName',
        title: 'Contre $teamName',
        winrate: winrate,
        totalGames: games,
        wins: wins,
      ));
    }

    return results;
  }

  /// Analyse la performance par champion pour une équipe
  static Future<List<QueryResult>> _calculateChampionPerformance(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    if (parameters.teamId == null) return [];

    final championStats = <String, Map<String, dynamic>>{};

    for (final scrim in scrims.where((s) => s.myTeamId == parameters.teamId)) {
      for (final stats in scrim.myTeamStats) {
        championStats.putIfAbsent(stats.championId, () => {
          'games': 0,
          'wins': 0,
          'totalKDA': 0.0,
          'players': <String>{},
        });

        final champStats = championStats[stats.championId]!;
        champStats['games'] = champStats['games'] + 1;
        
        if (scrim.isVictory == true) {
          champStats['wins'] = champStats['wins'] + 1;
        }
        
        champStats['totalKDA'] = champStats['totalKDA'] + stats.kdaScore;
        if (stats.playerId != null) {
          (champStats['players'] as Set<String>).add(stats.playerId!);
        }
      }
    }

    final results = <QueryResult>[];
    for (final entry in championStats.entries) {
      final champion = entry.key;
      final stats = entry.value;
      final games = stats['games'] as int;
      final wins = stats['wins'] as int;
      final winrate = games > 0 ? wins / games : 0.0;

      results.add(QueryResult.winrate(
        id: 'champion_performance_$champion',
        title: champion,
        winrate: winrate,
        totalGames: games,
        wins: wins,
      ));
    }

    // Tri par winrate puis par nombre de games
    results.sort((a, b) {
      final winrateComparison = (b.value as double).compareTo(a.value as double);
      if (winrateComparison != 0) return winrateComparison;
      return (b.getMetadata<int>('totalGames') ?? 0)
          .compareTo(a.getMetadata<int>('totalGames') ?? 0);
    });

    return results;
  }

  /// Analyse par rôle - méthodes restantes à implémenter...
  static Future<List<QueryResult>> _calculateRoleAnalysis(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    // TODO: Implémenter l'analyse par rôle
    return [];
  }

  static Future<List<QueryResult>> _calculatePatchAnalysis(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    // TODO: Implémenter l'analyse par patch
    return [];
  }

  static Future<List<QueryResult>> _calculateRecentPerformance(
    QueryParameters parameters,
    List<Scrim> scrims,
    List<Player> players,
  ) async {
    // TODO: Implémenter l'analyse de performance récente
    return [];
  }

  /// Applique les filtres aux résultats
  static List<QueryResult> _applyFilters(
    List<QueryResult> results,
    List<QueryFilter> filters,
  ) {
    // TODO: Implémenter l'application des filtres
    return results;
  }

  /// Applique le tri et les limitations
  static List<QueryResult> _applySortingAndLimits(
    List<QueryResult> results,
    QueryParameters parameters,
  ) {
    if (parameters.limit != null && parameters.limit! > 0) {
      return results.take(parameters.limit!).toList();
    }
    return results;
  }

  /// Génère le titre de la requête
  static String _getQueryTitle(QueryParameters parameters) {
    return parameters.queryType.displayName;
  }

  /// Génère un résumé des résultats
  static Map<String, dynamic> _generateSummary(
    List<QueryResult> results,
    QueryParameters parameters,
  ) {
    return {
      'totalResults': results.length,
      'hasData': results.any((r) => !r.isEmpty),
      'queryType': parameters.queryType.name,
    };
  }
}