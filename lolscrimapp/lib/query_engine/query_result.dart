/// Classe représentant un résultat de requête statistique
class QueryResult {
  final String id;
  final String title;
  final dynamic value;
  final String formattedValue;
  final Map<String, dynamic> metadata;
  final DateTime calculatedAt;

  const QueryResult({
    required this.id,
    required this.title,
    required this.value,
    required this.formattedValue,
    this.metadata = const {},
    required this.calculatedAt,
  });

  /// Crée un résultat pour un winrate
  factory QueryResult.winrate({
    required String id,
    required String title,
    required double winrate,
    required int totalGames,
    required int wins,
  }) {
    return QueryResult(
      id: id,
      title: title,
      value: winrate,
      formattedValue: '${(winrate * 100).toStringAsFixed(1)}% ($wins/$totalGames)',
      metadata: {
        'winrate': winrate,
        'totalGames': totalGames,
        'wins': wins,
        'losses': totalGames - wins,
      },
      calculatedAt: DateTime.now(),
    );
  }

  /// Crée un résultat pour une KDA moyenne
  factory QueryResult.averageKDA({
    required String id,
    required String title,
    required double averageKDA,
    required int totalGames,
    required double totalKills,
    required double totalDeaths,
    required double totalAssists,
  }) {
    return QueryResult(
      id: id,
      title: title,
      value: averageKDA,
      formattedValue: '${averageKDA.toStringAsFixed(2)} KDA sur $totalGames games',
      metadata: {
        'averageKDA': averageKDA,
        'totalGames': totalGames,
        'averageKills': totalKills / totalGames,
        'averageDeaths': totalDeaths / totalGames,
        'averageAssists': totalAssists / totalGames,
      },
      calculatedAt: DateTime.now(),
    );
  }

  /// Crée un résultat pour une statistique générale
  factory QueryResult.statistic({
    required String id,
    required String title,
    required dynamic value,
    required String unit,
    Map<String, dynamic> additionalMetadata = const {},
  }) {
    return QueryResult(
      id: id,
      title: title,
      value: value,
      formattedValue: '$value $unit',
      metadata: additionalMetadata,
      calculatedAt: DateTime.now(),
    );
  }

  /// Crée un résultat vide (aucune donnée trouvée)
  factory QueryResult.empty({
    required String id,
    required String title,
  }) {
    return QueryResult(
      id: id,
      title: title,
      value: null,
      formattedValue: 'Aucune donnée disponible',
      metadata: {'isEmpty': true},
      calculatedAt: DateTime.now(),
    );
  }

  /// Vérifie si le résultat contient des données
  bool get isEmpty => metadata['isEmpty'] == true || value == null;

  /// Récupère une métadonnée spécifique
  T? getMetadata<T>(String key) {
    return metadata[key] as T?;
  }

  @override
  String toString() => '$title: $formattedValue';
}

/// Classe contenant plusieurs résultats de requête
class QueryResultSet {
  final String queryId;
  final String title;
  final List<QueryResult> results;
  final Map<String, dynamic> summary;
  final DateTime executedAt;
  final Duration executionTime;

  const QueryResultSet({
    required this.queryId,
    required this.title,
    required this.results,
    this.summary = const {},
    required this.executedAt,
    required this.executionTime,
  });

  /// Vérifie si l'ensemble de résultats est vide
  bool get isEmpty => results.isEmpty || results.every((r) => r.isEmpty);

  /// Nombre total de résultats
  int get totalResults => results.length;

  /// Résultats non vides uniquement
  List<QueryResult> get nonEmptyResults => 
      results.where((r) => !r.isEmpty).toList();

  /// Résultat le mieux classé (premier de la liste)
  QueryResult? get topResult => nonEmptyResults.isNotEmpty 
      ? nonEmptyResults.first 
      : null;

  /// Filtre les résultats par un critère
  List<QueryResult> filterResults(bool Function(QueryResult) predicate) {
    return results.where(predicate).toList();
  }

  /// Trie les résultats par une fonction de comparaison
  List<QueryResult> sortResults(int Function(QueryResult, QueryResult) compare) {
    final sortedList = List<QueryResult>.from(results);
    sortedList.sort(compare);
    return sortedList;
  }

  /// Crée une copie avec des résultats modifiés
  QueryResultSet copyWith({
    String? queryId,
    String? title,
    List<QueryResult>? results,
    Map<String, dynamic>? summary,
    DateTime? executedAt,
    Duration? executionTime,
  }) {
    return QueryResultSet(
      queryId: queryId ?? this.queryId,
      title: title ?? this.title,
      results: results ?? this.results,
      summary: summary ?? this.summary,
      executedAt: executedAt ?? this.executedAt,
      executionTime: executionTime ?? this.executionTime,
    );
  }

  @override
  String toString() {
    return 'QueryResultSet(title: $title, results: ${results.length}, '
           'execution: ${executionTime.inMilliseconds}ms)';
  }
}