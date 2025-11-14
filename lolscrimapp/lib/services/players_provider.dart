import 'package:flutter/foundation.dart';
import '../models/player.dart';
import '../services/storage_service.dart';

/// Provider pour la gestion des joueurs
class PlayersProvider extends ChangeNotifier {
  List<Player> _players = [];
  bool _isLoading = false;
  String? _error;

  /// Liste des joueurs
  List<Player> get players => List.unmodifiable(_players);

  /// Indique si les données sont en cours de chargement
  bool get isLoading => _isLoading;

  /// Message d'erreur s'il y en a une
  String? get error => _error;

  /// Charge tous les joueurs depuis la base de données
  Future<void> loadPlayers() async {
    _setLoading(true);
    try {
      _players = await StorageService.getPlayers();
      _error = null;
    } catch (e) {
      _error = 'Erreur lors du chargement des joueurs: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Ajoute un nouveau joueur
  Future<void> addPlayer(Player player) async {
    try {
      await StorageService.insertPlayer(player);
      _players.add(player);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de l\'ajout du joueur: $e';
      debugPrint(_error);
    }
  }

  /// Met à jour un joueur existant
  Future<void> updatePlayer(Player player) async {
    try {
      await StorageService.updatePlayer(player);
      final index = _players.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        _players[index] = player;
        notifyListeners();
      }
      _error = null;
    } catch (e) {
      _error = 'Erreur lors de la mise à jour du joueur: $e';
      debugPrint(_error);
    }
  }

  /// Supprime un joueur
  Future<void> deletePlayer(String playerId) async {
    try {
      await StorageService.deletePlayer(playerId);
      _players.removeWhere((p) => p.id == playerId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erreur lors de la suppression du joueur: $e';
      debugPrint(_error);
    }
  }

  /// Trouve un joueur par son ID
  Player? getPlayerById(String id) {
    try {
      return _players.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Filtre les joueurs par rôle
  List<Player> getPlayersByRole(String role) {
    return _players.where((p) => p.role == role).toList();
  }

  /// Recherche des joueurs par pseudo (recherche partielle)
  List<Player> searchPlayers(String query) {
    if (query.isEmpty) return players;
    
    final lowerQuery = query.toLowerCase();
    return _players.where((p) => 
      p.pseudo.toLowerCase().contains(lowerQuery) ||
      (p.realName?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Vérifie si un pseudo est disponible
  bool isPseudoAvailable(String pseudo, {String? excludePlayerId}) {
    return !_players.any((p) => 
      p.pseudo.toLowerCase() == pseudo.toLowerCase() && 
      p.id != excludePlayerId
    );
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
    await loadPlayers();
  }
}