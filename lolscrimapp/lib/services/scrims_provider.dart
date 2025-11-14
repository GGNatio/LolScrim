import 'package:flutter/foundation.dart';
import '../models/scrim.dart';
import '../services/storage_service.dart';

/// Provider pour la gestion des scrims
class ScrimsProvider extends ChangeNotifier {
  List<Scrim> _scrims = [];
  bool _isLoading = false;
  String? _error;

  /// Liste des scrims
  List<Scrim> get scrims => List.unmodifiable(_scrims);

  /// Indique si les données sont en cours de chargement
  bool get isLoading => _isLoading;

  /// Message d'erreur s'il y en a une
  String? get error => _error;

  /// Charge tous les scrims depuis la base de données
  Future<void> loadScrims() async {
    _setLoading(true);
    try {
      _scrims = await StorageService.getScrims();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des scrims: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Charge les scrims d'une équipe spécifique
  Future<void> loadScrimsByTeam(String teamId) async {
    _setLoading(true);
    try {
      final allScrims = await StorageService.getScrims();
      _scrims = allScrims.where((s) => s.myTeamId == teamId).toList();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des scrims de l\'équipe: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute un nouveau scrim
  Future<void> addScrim(Scrim scrim) async {
    try {
      await StorageService.insertScrim(scrim);
      _scrims.insert(0, scrim); // Insérer en premier (plus récent)
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du scrim: $e';
      debugPrint(_error);
    }
  }

  /// Met à jour un scrim existant
  Future<void> updateScrim(Scrim scrim) async {
    try {
      await StorageService.updateScrim(scrim);
      final index = _scrims.indexWhere((s) => s.id == scrim.id);
      if (index != -1) {
        _scrims[index] = scrim;
        notifyListeners();
      }
      _error = null;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du scrim: $e';
      debugPrint(_error);
    }
  }

  /// Supprime un scrim
  Future<void> deleteScrim(String scrimId) async {
    try {
      await StorageService.deleteScrim(scrimId);
      _scrims.removeWhere((s) => s.id == scrimId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression du scrim: $e';
      debugPrint(_error);
    }
  }

  /// Trouve un scrim par son ID
  Scrim? getScrimById(String id) {
    try {
      return _scrims.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère les scrims d'une équipe spécifique
  List<Scrim> getScrimsByTeamId(String teamId) {
    return _scrims.where((s) => s.myTeamId == teamId).toList();
  }

  /// Récupère les scrims récents (derniers N scrims)
  List<Scrim> getRecentScrims({int limit = 10}) {
    final sortedScrims = List<Scrim>.from(_scrims);
    sortedScrims.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedScrims.take(limit).toList();
  }

  /// Récupère les scrims dans une plage de dates
  List<Scrim> getScrimsByDateRange(DateTime startDate, DateTime endDate) {
    return _scrims.where((s) => 
      s.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
      s.createdAt.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }

  /// Récupère les scrims par patch
  List<Scrim> getScrimsByPatch(String patch) {
    return _scrims.where((s) => s.patch == patch).toList();
  }

  /// Récupère les victoires d'une équipe
  List<Scrim> getVictoriesByTeam(String teamId) {
    return _scrims.where((s) => 
      s.myTeamId == teamId && s.myTeamWins > s.enemyTeamWins
    ).toList();
  }

  /// Récupère les défaites d'une équipe
  List<Scrim> getDefeatsByTeam(String teamId) {
    return _scrims.where((s) => 
      s.myTeamId == teamId && s.myTeamWins < s.enemyTeamWins
    ).toList();
  }

  /// Calcule le winrate d'une équipe
  double getTeamWinrate(String teamId) {
    final teamScrims = getScrimsByTeamId(teamId);
    if (teamScrims.isEmpty) return 0.0;
    
    final victories = teamScrims.where((s) => s.myTeamWins > s.enemyTeamWins).length;
    return victories / teamScrims.length;
  }

  /// Récupère les scrims où un joueur spécifique a joué
  List<Scrim> getScrimsByPlayer(String playerId) {
    return _scrims.where((s) => 
      s.matches.any((match) => match.myTeamPlayers.any((player) => player.playerId == playerId))
    ).toList();
  }

  /// Récupère les scrims où un champion spécifique a été joué
  List<Scrim> getScrimsByChampion(String champion) {
    return _scrims.where((s) => 
      s.matches.any((match) => 
        match.myTeamPlayers.any((player) => player.champion == champion) ||
        match.enemyPlayers.any((player) => player.champion == champion)
      )
    ).toList();
  }

  /// Récupère les scrims contre une équipe adverse spécifique
  List<Scrim> getScrimsAgainstTeam(String enemyTeamName) {
    return _scrims.where((s) => 
      s.enemyTeamName?.toLowerCase() == enemyTeamName.toLowerCase()
    ).toList();
  }

  /// Récupère les scrims complets (avec toutes les données requises)
  List<Scrim> get completeScrims => 
      _scrims.where((s) => s.matches.length == s.totalMatches).toList();

  /// Statistiques générales des scrims
  Map<String, dynamic> getGeneralStats() {
    if (_scrims.isEmpty) {
      return {
        'totalScrims': 0,
        'victories': 0,
        'defeats': 0,
        'winrate': 0.0,
        'averageGameLength': Duration.zero,
      };
    }

    final victories = _scrims.where((s) => s.myTeamWins > s.enemyTeamWins).length;
    final defeats = _scrims.length - victories;
    final winrate = victories / _scrims.length;

    // Calculer la durée moyenne basée sur les matchs individuels
    final allMatches = _scrims.expand((s) => s.matches).toList();
    final matchesWithDuration = allMatches.where((match) => match.matchDuration != null);
    final averageDuration = matchesWithDuration.isNotEmpty
        ? Duration(
            seconds: (matchesWithDuration
                    .map((match) => match.matchDuration!.inSeconds)
                    .reduce((a, b) => a + b) /
                matchesWithDuration.length)
                .round(),
          )
        : Duration.zero;

    return {
      'totalScrims': _scrims.length,
      'victories': victories,
      'defeats': defeats,
      'winrate': winrate,
      'averageGameLength': averageDuration,
    };
  }

  /// Définit l'état de chargement
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Rafraîchit les données
  Future<void> refresh() async {
    await loadScrims();
  }
}