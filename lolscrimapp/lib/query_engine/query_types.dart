/// Énumération des types de requêtes statistiques disponibles
enum QueryType {
  winrateVsChampion('Winrate contre un champion'),
  averageStatsOnChampion('Stats moyennes sur un champion'),
  performanceVsTeam('Performance contre une équipe'),
  championPerformance('Performance par champion'),
  roleAnalysis('Analyse par rôle'),
  patchAnalysis('Analyse par patch'),
  recentPerformance('Performance récente');

  const QueryType(this.displayName);
  final String displayName;
}

/// Énumération des métriques calculables
enum MetricType {
  winrate('Winrate'),
  averageKDA('KDA moyen'),
  averageKills('Kills moyens'),
  averageDeaths('Morts moyennes'),
  averageAssists('Assists moyens'),
  averageCS('CS moyen'),
  averageDamage('Dégâts moyens'),
  totalGames('Nombre de games'),
  bestPerformance('Meilleure performance'),
  consistency('Régularité');

  const MetricType(this.displayName);
  final String displayName;
}

/// Énumération des filtres applicables
enum FilterType {
  byChampion('Par champion'),
  byRole('Par rôle'),
  byEnemyChampion('Par champion ennemi'),
  byEnemyTeam('Par équipe adverse'),
  byPatch('Par patch'),
  byDateRange('Par période'),
  byResult('Par résultat');

  const FilterType(this.displayName);
  final String displayName;
}

/// Classe représentant un filtre de requête
class QueryFilter {
  final FilterType type;
  final dynamic value;
  final String? displayValue;

  const QueryFilter({
    required this.type,
    required this.value,
    this.displayValue,
  });

  String get formattedValue => displayValue ?? value.toString();

  @override
  String toString() => '${type.displayName}: $formattedValue';
}

/// Classe représentant les paramètres d'une requête
class QueryParameters {
  final QueryType queryType;
  final String? teamId;
  final String? playerId;
  final List<QueryFilter> filters;
  final List<MetricType> metrics;
  final int? limit; // Limitation du nombre de résultats
  final bool ascending; // Ordre de tri

  const QueryParameters({
    required this.queryType,
    this.teamId,
    this.playerId,
    this.filters = const [],
    this.metrics = const [],
    this.limit,
    this.ascending = false,
  });

  /// Ajoute un filtre aux paramètres
  QueryParameters addFilter(QueryFilter filter) {
    return QueryParameters(
      queryType: queryType,
      teamId: teamId,
      playerId: playerId,
      filters: [...filters, filter],
      metrics: metrics,
      limit: limit,
      ascending: ascending,
    );
  }

  /// Ajoute une métrique aux paramètres
  QueryParameters addMetric(MetricType metric) {
    return QueryParameters(
      queryType: queryType,
      teamId: teamId,
      playerId: playerId,
      filters: filters,
      metrics: [...metrics, metric],
      limit: limit,
      ascending: ascending,
    );
  }

  /// Crée une copie avec des modifications
  QueryParameters copyWith({
    QueryType? queryType,
    String? teamId,
    String? playerId,
    List<QueryFilter>? filters,
    List<MetricType>? metrics,
    int? limit,
    bool? ascending,
  }) {
    return QueryParameters(
      queryType: queryType ?? this.queryType,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      filters: filters ?? this.filters,
      metrics: metrics ?? this.metrics,
      limit: limit ?? this.limit,
      ascending: ascending ?? this.ascending,
    );
  }

  /// Vérifie si les paramètres sont valides pour exécution
  bool get isValid {
    switch (queryType) {
      case QueryType.winrateVsChampion:
      case QueryType.averageStatsOnChampion:
      case QueryType.performanceVsTeam:
        return playerId != null;
      case QueryType.championPerformance:
      case QueryType.roleAnalysis:
        return teamId != null;
      case QueryType.patchAnalysis:
      case QueryType.recentPerformance:
        return teamId != null || playerId != null;
    }
  }

  @override
  String toString() {
    return 'QueryParameters(type: ${queryType.displayName}, '
           'team: $teamId, player: $playerId, '
           'filters: ${filters.length}, metrics: ${metrics.length})';
  }
}