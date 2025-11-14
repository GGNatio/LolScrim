import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/players_provider.dart';
import '../services/teams_provider.dart';
import '../widgets/add_player_to_team_modal.dart';

/// Écran détaillé d'une équipe avec sidebar des joueurs
class TeamDetailScreen extends StatefulWidget {
  final Team team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  late Team currentTeam;

  @override
  void initState() {
    super.initState();
    currentTeam = widget.team;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        // Récupérer la version la plus récente de l'équipe
        final updatedTeam = teamsProvider.getTeamById(widget.team.id) ?? widget.team;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(updatedTeam.name),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value),
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
          body: Row(
            children: [
              // Sidebar gauche avec les joueurs
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    right: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: _PlayersSidebar(team: updatedTeam),
              ),
              
              // Contenu principal
              Expanded(
                child: _MainContent(team: updatedTeam),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
    final updatedTeam = teamsProvider.getTeamById(widget.team.id) ?? widget.team;
    
    switch (action) {
      case 'edit':
        _showEditTeamDialog(context, updatedTeam);
        break;
      case 'delete':
        _showDeleteConfirmDialog(context, updatedTeam);
        break;
    }
  }

  void _showEditTeamDialog(BuildContext context, Team team) {
    // TODO: Implémenter l'édition d'équipe
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Édition de ${team.name} - À implémenter')),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'équipe'),
        content: Text('Êtes-vous sûr de vouloir supprimer l\'équipe "${team.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<TeamsProvider>().deleteTeam(team.id);
                if (mounted) {
                  Navigator.of(context).pop(); // Fermer le dialog
                  Navigator.of(context).pop(); // Retour à la liste des équipes
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Équipe supprimée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression : $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

/// Sidebar des joueurs de l'équipe
class _PlayersSidebar extends StatelessWidget {
  final Team team;

  const _PlayersSidebar({required this.team});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En-tête de la sidebar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joueurs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${team.playerIds.length}/5 joueurs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),

        // Liste des joueurs
        Expanded(
          child: Consumer<PlayersProvider>(
            builder: (context, playersProvider, child) {
              if (playersProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final teamPlayers = playersProvider.players
                  .where((player) => team.playerIds.contains(player.id))
                  .toList();

              if (teamPlayers.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_disabled, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun joueur dans cette équipe',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: teamPlayers.length,
                itemBuilder: (context, index) {
                  final player = teamPlayers[index];
                  return _PlayerCard(player: player);
                },
              );
            },
          ),
        ),

        // Boutons d'action en bas
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPlayerDialog(context),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Ajouter un joueur'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showTeamScrims(context),
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('Voir les scrims'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showTeamSettings(context),
                  icon: const Icon(Icons.settings),
                  label: const Text('Paramètres'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddPlayerDialog(BuildContext context) async {
    if (!team.canAddPlayer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ L\'équipe est déjà complète (5/5 joueurs)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<Player>(
      context: context,
      builder: (context) => AddPlayerToTeamModal(team: team),
    );
    
    if (result != null) {
      // Le modal gère déjà l'ajout, on peut juste rafraîchir l'état si nécessaire
      // L'interface se mettra à jour automatiquement grâce au Consumer
    }
  }

  void _showTeamScrims(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.sports_esports, color: Colors.green),
            const SizedBox(width: 8),
            Text('Scrims de ${team.name}'),
          ],
        ),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Column(
            children: [
              Icon(
                Icons.sports_esports,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun scrim disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Les scrims de cette équipe apparaîtront ici une fois le système implémenté',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚀 Fonctionnalité de création de scrim à venir !'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Créer un scrim'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTeamSettings(BuildContext context) {
    // TODO: Implémenter les paramètres d'équipe
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres d\'équipe - À implémenter')),
    );
  }
}

/// Carte d'un joueur dans la sidebar
class _PlayerCard extends StatelessWidget {
  final Player player;

  const _PlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar du joueur
            CircleAvatar(
              radius: 20,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                player.pseudo[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Informations du joueur
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.pseudo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    player.role,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getRoleColor(player.role),
                    ),
                  ),
                ],
              ),
            ),
            
            // Indicateur de rang
            if (player.rank != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  player.rank!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'top':
      case 'baron lane':
        return Colors.blue;
      case 'jungle':
        return Colors.green;
      case 'mid':
      case 'mid lane':
        return Colors.orange;
      case 'adc':
      case 'dragon lane (adc)':
      case 'duelist':
        return Colors.red;
      case 'support':
      case 'controller':
      case 'sentinel':
        return Colors.purple;
      case 'initiator':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

/// Contenu principal de la page équipe
class _MainContent extends StatelessWidget {
  final Team team;

  const _MainContent({required this.team});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec logo et infos
          Row(
            children: [
              // Logo de l'équipe
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: team.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          team.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.groups,
                            color: Theme.of(context).colorScheme.primary,
                            size: 40,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.groups,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
              ),
              
              const SizedBox(width: 20),
              
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.videogame_asset,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          team.game.displayName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    Text(
                      'Créée le ${_formatDate(team.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (team.description != null && team.description!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                team.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],

          const SizedBox(height: 32),
          
          // Statistiques rapides
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _StatCard(
                icon: Icons.people,
                label: 'Joueurs',
                value: '${team.playerIds.length}/5',
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.sports_esports,
                label: 'Scrims',
                value: '0', // TODO: Calculer depuis les données
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.emoji_events,
                label: 'Victoires',
                value: '0%', // TODO: Calculer depuis les données
                color: Colors.orange,
              ),
            ],
          ),

          const Spacer(),
          
          // Actions rapides
          const Center(
            child: Text(
              'Plus de fonctionnalités à venir...',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

/// Widget pour afficher une statistique
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}