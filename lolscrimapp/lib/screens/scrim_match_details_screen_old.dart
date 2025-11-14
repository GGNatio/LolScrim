import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/champion.dart';
import '../models/game_data.dart';
import '../services/scrims_provider.dart';

/// Données temporaires pour un joueur en cours de saisie
class MatchPlayerData {
  String? playerId;
  Champion? champion;
  List<SummonerSpell> summonerSpells = [SummonerSpell.none, SummonerSpell.none];
  List<Item> items = List.filled(6, Item.none);
  int? kills;
  int? deaths;
  int? assists;
  int? cs;
  int? gold;
  int? damage;
  
  MatchPlayerData();
  
  bool get isComplete => 
    playerId != null && 
    champion != null && 
    kills != null && 
    deaths != null && 
    assists != null &&
    cs != null &&
    gold != null &&
    damage != null;
}

/// Écran de saisie des détails des matchs d'un scrim avec interface LoL
class ScrimMatchDetailsScreen extends StatefulWidget {
  final Scrim scrim;
  final Team team;

  const ScrimMatchDetailsScreen({
    super.key,
    required this.scrim,
    required this.team,
  });

  @override
  State<ScrimMatchDetailsScreen> createState() => _ScrimMatchDetailsScreenState();
}

class _ScrimMatchDetailsScreenState extends State<ScrimMatchDetailsScreen> {
  late PageController _pageController;
  late Scrim _currentScrim;
  int _currentMatchIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentScrim = widget.scrim;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentScrim.name} - Match ${_currentMatchIndex + 1}/${_currentScrim.totalMatches}'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          if (_currentMatchIndex > 0)
            IconButton(
              onPressed: _previousMatch,
              icon: const Icon(Icons.arrow_back_ios),
              tooltip: 'Match précédent',
            ),
          if (_currentMatchIndex < _currentScrim.totalMatches - 1)
            IconButton(
              onPressed: _nextMatch,
              icon: const Icon(Icons.arrow_forward_ios),
              tooltip: 'Match suivant',
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: _currentScrim.totalMatches,
        onPageChanged: (index) {
          setState(() {
            _currentMatchIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildMatchForm(index + 1);
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indicateur de progression
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progression: ${_getCompletedMatches()}/${_currentScrim.totalMatches} matchs',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _getCompletedMatches() / _currentScrim.totalMatches,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Boutons
            if (_currentMatchIndex > 0)
              OutlinedButton(
                onPressed: _previousMatch,
                child: const Text('Précédent'),
              ),
            
            if (_currentMatchIndex > 0) ...[
              const SizedBox(width: 8),
            ],
            
            ElevatedButton(
              onPressed: _isLoading ? null : (_currentMatchIndex < _currentScrim.totalMatches - 1 ? _nextMatch : _finishScrim),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(_currentMatchIndex < _currentScrim.totalMatches - 1 ? 'Suivant' : 'Terminer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchForm(int matchNumber) {
    final existingMatch = _currentScrim.getMatch(matchNumber);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du match
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.sports_esports, color: Colors.blue.shade700, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match $matchNumber',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          '${widget.team.name} vs ${_currentScrim.enemyTeamName}',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (existingMatch != null)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Placeholder pour le formulaire du match
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.construction,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Formulaire de détails du match',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ici sera implémenté le formulaire de saisie des détails\\npour chaque joueur (champion, KDA, CS, dégâts, etc.)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _markMatchAsComplete(matchNumber),
                  child: const Text('Marquer comme terminé (temporaire)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _markMatchAsComplete(int matchNumber) {
    // Temporaire: marquer le match comme terminé avec des données factices
    final match = ScrimMatch(
      matchNumber: matchNumber,
      myTeamPlayers: const [],
      enemyPlayers: const [],
      isVictory: true, // Temporaire
      matchDuration: const Duration(minutes: 30),
    );
    
    setState(() {
      _currentScrim = _currentScrim.addMatch(match);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Match $matchNumber marqué comme terminé'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _previousMatch() {
    if (_currentMatchIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextMatch() {
    if (_currentMatchIndex < _currentScrim.totalMatches - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishScrim() async {
    setState(() => _isLoading = true);
    
    try {
      // Sauvegarder le scrim final
      final scrimsProvider = Provider.of<ScrimsProvider>(context, listen: false);
      await scrimsProvider.updateScrim(_currentScrim);
      
      if (mounted) {
        // Retourner aux détails de l'équipe avec un message de succès
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Scrim "${_currentScrim.name}" terminé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int _getCompletedMatches() {
    return _currentScrim.matches.length;
  }
}