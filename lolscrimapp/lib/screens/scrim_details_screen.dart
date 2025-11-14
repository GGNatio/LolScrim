import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/scrim.dart';
import '../models/team.dart';
import '../services/scrims_provider.dart';
import '../services/teams_provider.dart';
import 'create_scrim_screen.dart';
import 'scrim_match_details_screen.dart';

/// Écran de détails d'un scrim avec options de gestion
class ScrimDetailsScreen extends StatefulWidget {
  final Scrim scrim;

  const ScrimDetailsScreen({
    super.key,
    required this.scrim,
  });

  @override
  State<ScrimDetailsScreen> createState() => _ScrimDetailsScreenState();
}

class _ScrimDetailsScreenState extends State<ScrimDetailsScreen> {
  late Scrim _currentScrim;
  Team? _team;

  @override
  void initState() {
    super.initState();
    _currentScrim = widget.scrim;
    _loadTeam();
  }

  void _loadTeam() {
    final teamsProvider = context.read<TeamsProvider>();
_team = teamsProvider.teams.where(
      (team) => team.id == _currentScrim.myTeamId,
    ).isNotEmpty ? teamsProvider.teams.firstWhere(
      (team) => team.id == _currentScrim.myTeamId,
    ) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentScrim.name),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'continue',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text('Continuer les matchs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du scrim
            _buildScrimHeader(),
            
            const SizedBox(height: 24),
            
            // Statistiques générales
            _buildStatsSection(),
            
            const SizedBox(height: 24),
            
            // Liste des matchs
            _buildMatchesSection(),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildScrimHeader() {
    final isComplete = _currentScrim.matches.length == _currentScrim.totalMatches;
    final winRate = _currentScrim.totalMatches > 0 
        ? (_currentScrim.myTeamWins / _currentScrim.totalMatches * 100).round()
        : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.sports_esports,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentScrim.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_team?.name ?? 'Équipe inconnue'} vs ${_currentScrim.enemyTeamName ?? 'Adversaire inconnu'}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_currentScrim.myTeamWins} - ${_currentScrim.enemyTeamWins}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _currentScrim.myTeamWins > _currentScrim.enemyTeamWins 
                            ? Colors.green.shade700 
                            : _currentScrim.myTeamWins < _currentScrim.enemyTeamWins
                                ? Colors.red.shade700
                                : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '$winRate% de victoire',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations supplémentaires
            Row(
              children: [
                _buildInfoChip(
                  Icons.calendar_today, 
                  '${_currentScrim.createdAt.day}/${_currentScrim.createdAt.month}/${_currentScrim.createdAt.year}',
                ),
                const SizedBox(width: 8),
                if (_currentScrim.patch != null)
                  _buildInfoChip(Icons.update, 'Patch ${_currentScrim.patch}'),
                const Spacer(),
                _buildInfoChip(
                  isComplete ? Icons.check_circle : Icons.pending,
                  isComplete ? 'Terminé' : 'En cours',
                  color: isComplete ? Colors.green : Colors.orange,
                ),
              ],
            ),
            
            // Barre de progression
            if (!isComplete) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progression: ${_currentScrim.matches.length}/${_currentScrim.totalMatches} matchs',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _currentScrim.matches.length / _currentScrim.totalMatches,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (color ?? Colors.grey).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (color ?? Colors.grey).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Victoires', '${_currentScrim.myTeamWins}', Colors.green),
                ),
                Expanded(
                  child: _buildStatItem('Défaites', '${_currentScrim.enemyTeamWins}', Colors.red),
                ),
                Expanded(
                  child: _buildStatItem('Matchs totaux', '${_currentScrim.totalMatches}', Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Matchs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_currentScrim.matches.length < _currentScrim.totalMatches)
                  TextButton.icon(
                    onPressed: _continueMatches,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter match'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_currentScrim.matches.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_esports_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aucun match enregistré',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentScrim.matches.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final match = _currentScrim.matches[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (match.isVictory ?? false) ? Colors.green.shade100 : Colors.red.shade100,
                      child: Icon(
                        (match.isVictory ?? false) ? Icons.check : Icons.close,
                        color: (match.isVictory ?? false) ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                    title: Text('Match ${match.matchNumber}'),
                    subtitle: Text(
                      (match.isVictory ?? false) ? 'Victoire' : 'Défaite',
                    ),
                    trailing: match.matchDuration != null
                        ? Text(
                            '${match.matchDuration!.inMinutes}min',
                            style: TextStyle(color: Colors.grey.shade600),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final canContinue = _currentScrim.matches.length < _currentScrim.totalMatches;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canContinue ? _continueMatches : null,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(canContinue ? 'Continuer' : 'Scrim terminé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _editScrim,
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Supprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editScrim();
        break;
      case 'continue':
        _continueMatches();
        break;
      case 'delete':
        _confirmDelete();
        break;
    }
  }

  void _editScrim() {
    if (_team == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateScrimScreen(
          team: _team!,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Le scrim a été modifié, recharger les données
        Navigator.of(context).pop(true);
      }
    });
  }

  void _continueMatches() {
    if (_team == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScrimMatchDetailsScreen(
          scrim: _currentScrim,
          team: _team!,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Les matchs ont été mis à jour
        Navigator.of(context).pop(true);
      }
    });
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le scrim'),
        content: Text(
          'Voulez-vous vraiment supprimer le scrim "${_currentScrim.name}" ?\n\n'
          'Cette action est irréversible et supprimera tous les matchs associés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: _deleteScrim,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _deleteScrim() async {
    try {
      await context.read<ScrimsProvider>().deleteScrim(_currentScrim.id);
      
      if (mounted) {
        Navigator.of(context).pop(); // Ferme le dialogue
        Navigator.of(context).pop(true); // Retourne à l'écran précédent avec résultat
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Scrim "${_currentScrim.name}" supprimé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Ferme le dialogue
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}