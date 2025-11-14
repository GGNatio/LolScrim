import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/storage_service.dart';
import 'players_provider.dart';

/// Provider pour la gestion des équipes
class TeamsProvider extends ChangeNotifier {
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _error;

  /// Liste des équipes
  List<Team> get teams => List.unmodifiable(_teams);

  /// Indique si les données sont en cours de chargement
  bool get isLoading => _isLoading;

  /// Message d'erreur s'il y en a une
  String? get error => _error;

  /// Charge toutes les équipes depuis la base de données
  Future<void> loadTeams() async {
    _setLoading(true);
    try {
      _teams = await StorageService.getTeams();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des équipes: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute une nouvelle équipe
  Future<void> addTeam(Team team) async {
    try {
      await StorageService.insertTeam(team);
      _teams.add(team);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout de l\'équipe: $e';
      debugPrint(_error);
    }
  }

  /// Met à jour une équipe existante
  Future<void> updateTeam(Team team) async {
    try {
      await StorageService.updateTeam(team);
      final index = _teams.indexWhere((t) => t.id == team.id);
      if (index != -1) {
        _teams[index] = team;
        notifyListeners();
      }
      _error = null;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour de l\'équipe: $e';
      debugPrint(_error);
    }
  }

  /// Supprime une équipe
  Future<void> deleteTeam(String teamId) async {
    try {
      await StorageService.deleteTeam(teamId);
      _teams.removeWhere((t) => t.id == teamId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression de l\'équipe: $e';
      debugPrint(_error);
    }
  }

  /// Trouve une équipe par son ID
  Team? getTeamById(String id) {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ajoute un joueur à une équipe
  Future<void> addPlayerToTeam(String teamId, String playerId) async {
    final team = getTeamById(teamId);
    if (team == null) {
      _error = 'Équipe introuvable';
      notifyListeners();
      return;
    }

    if (!team.canAddPlayer) {
      _error = 'L\'équipe est déjà complète (5 joueurs maximum)';
      notifyListeners();
      return;
    }

    if (team.playerIds.contains(playerId)) {
      _error = 'Le joueur est déjà dans cette équipe';
      notifyListeners();
      return;
    }

    try {
      final updatedTeam = team.addPlayer(playerId);
      await updateTeam(updatedTeam);
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du joueur à l\'équipe: $e';
      debugPrint(_error);
    }
  }

  /// Retire un joueur d'une équipe
  Future<void> removePlayerFromTeam(String teamId, String playerId) async {
    final team = getTeamById(teamId);
    if (team == null) {
      _error = 'Équipe introuvable';
      notifyListeners();
      return;
    }

    if (!team.playerIds.contains(playerId)) {
      _error = 'Le joueur n\'est pas dans cette équipe';
      notifyListeners();
      return;
    }

    try {
      final updatedTeam = team.removePlayer(playerId);
      await updateTeam(updatedTeam);
    } catch (e) {
      _error = 'Erreur lors du retrait du joueur de l\'équipe: $e';
      debugPrint(_error);
    }
  }

  /// Recherche des équipes par nom
  List<Team> searchTeams(String query) {
    if (query.isEmpty) return teams;
    
    final lowerQuery = query.toLowerCase();
    return _teams.where((t) => 
      t.name.toLowerCase().contains(lowerQuery) ||
      (t.description?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Vérifie si un nom d'équipe est disponible
  bool isTeamNameAvailable(String name, {String? excludeTeamId}) {
    return !_teams.any((t) => 
      t.name.toLowerCase() == name.toLowerCase() && 
      t.id != excludeTeamId
    );
  }

  /// Récupère les équipes avec des rosters complets
  List<Team> get completeTeams => 
      _teams.where((t) => t.hasFullRoster).toList();

  /// Récupère les équipes qui peuvent accepter de nouveaux joueurs
  List<Team> get availableTeams => 
      _teams.where((t) => t.canAddPlayer).toList();

  /// Récupère les joueurs d'une équipe avec leurs informations complètes
  Future<List<Player>> getTeamPlayers(String teamId, PlayersProvider playersProvider) async {
    final team = getTeamById(teamId);
    if (team == null) return [];

    final players = <Player>[];
    for (final playerId in team.playerIds) {
      final player = playersProvider.getPlayerById(playerId);
      if (player != null) {
        players.add(player);
      }
    }

    return players;
  }

  /// Vérifie si un joueur peut être ajouté à une équipe (pas de conflit de rôle)
  bool canAddPlayerToTeam(String teamId, String playerId, PlayersProvider playersProvider) {
    final team = getTeamById(teamId);
    final player = playersProvider.getPlayerById(playerId);
    
    if (team == null || player == null) return false;
    
    if (!team.canAddPlayer || team.playerIds.contains(playerId)) {
      return false;
    }

    // Vérifier s'il n'y a pas déjà un joueur du même rôle
    final existingRoles = <String>[];
    for (final existingPlayerId in team.playerIds) {
      final existingPlayer = playersProvider.getPlayerById(existingPlayerId);
      if (existingPlayer != null) {
        existingRoles.add(existingPlayer.role);
      }
    }

    return !existingRoles.contains(player.role);
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
    await loadTeams();
  }
}