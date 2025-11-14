import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/players_provider.dart';
import '../services/teams_provider.dart';
import '../widgets/edit_player_modal.dart';

/// Écran de détails d'un joueur
class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({
    super.key,
    required this.player,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayersProvider>(
      builder: (context, playersProvider, child) {
        final currentPlayer = playersProvider.getPlayerById(widget.player.id) ?? widget.player;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(currentPlayer.pseudo),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _editPlayer(currentPlayer);
                      break;
                    case 'delete':
                      _deletePlayer(currentPlayer);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Modifier'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Row(
            children: [
              // Sidebar
              Container(
                width: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: Border(
                    right: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: _getGameColor(currentPlayer.game).withOpacity(0.2),
                            child: Text(
                              currentPlayer.pseudo.isNotEmpty 
                                  ? currentPlayer.pseudo[0].toUpperCase() 
                                  : '?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: _getGameColor(currentPlayer.game),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currentPlayer.pseudo,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            currentPlayer.game.displayName,
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 1),
                    
                    // Navigation
                    ListTile(
                      leading: Icon(Icons.info_outline, color: _selectedIndex == 0 ? Colors.blue : null),
                      title: Text('Informations', style: TextStyle(
                        fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        color: _selectedIndex == 0 ? Colors.blue : null,
                      )),
                      selected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    ListTile(
                      leading: Icon(Icons.groups_outlined, color: _selectedIndex == 1 ? Colors.blue : null),
                      title: Text('Équipes', style: TextStyle(
                        fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.normal,
                        color: _selectedIndex == 1 ? Colors.blue : null,
                      )),
                      selected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    ListTile(
                      leading: Icon(Icons.sports_esports, color: _selectedIndex == 2 ? Colors.blue : null),
                      title: Text('Scrims', style: TextStyle(
                        fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.normal,
                        color: _selectedIndex == 2 ? Colors.blue : null,
                      )),
                      selected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ],
                ),
              ),
              
              // Contenu principal
              Expanded(
                child: _buildMainContent(currentPlayer),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(Player player) {
    switch (_selectedIndex) {
      case 0:
        return _buildPlayerInfo(player);
      case 1:
        return _buildPlayerTeams(player);
      case 2:
        return _buildPlayerScrims(player);
      default:
        return _buildPlayerInfo(player);
    }
  }

  Widget _buildPlayerInfo(Player player) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du joueur',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Pseudo', player.pseudo, Icons.person),
                  const SizedBox(height: 16),
                  _buildInfoRow('ID dans le jeu', player.inGameId, Icons.games),
                  const SizedBox(height: 16),
                  _buildInfoRow('Jeu', player.game.displayName, Icons.sports_esports),
                  const SizedBox(height: 16),
                  _buildInfoRow('Rôle', player.role, Icons.assignment_ind),
                  if (player.rank != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Rang', player.rank!, Icons.military_tech),
                  ],
                  if (player.region != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Région', player.region!, Icons.public),
                  ],
                  if (player.realName != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Nom réel', player.realName!, Icons.badge),
                  ],
                  if (player.description != null) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow('Description', player.description!, Icons.description),
                  ],
                  const SizedBox(height: 16),
                  _buildInfoRow('Date de création', _formatDate(player.createdAt), Icons.calendar_today),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTeams(Player player) {
    return Consumer<TeamsProvider>(
      builder: (context, teamsProvider, child) {
        final playerTeams = teamsProvider.teams
            .where((team) => team.playerIds.contains(player.id))
            .toList();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Équipes (${playerTeams.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              
              if (playerTeams.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.groups_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text('Aucune équipe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          Text('Ce joueur n\'appartient à aucune équipe', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...playerTeams.map((team) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getGameColor(team.game).withOpacity(0.2),
                      child: Text(
                        team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
                        style: TextStyle(fontWeight: FontWeight.bold, color: _getGameColor(team.game)),
                      ),
                    ),
                    title: Text(team.name),
                    subtitle: Text('${team.game.displayName} • ${team.playerIds.length}/5 joueurs'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerScrims(Player player) {
    // Pour l'instant, afficher un placeholder en attendant l'implémentation des scrims
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scrims récents',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.sports_esports, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun scrim disponible', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600)
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les scrims de ${player.pseudo} apparaîtront ici une fois qu\'ils seront implémentés', 
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ),
        Expanded(
          flex: 3,
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getGameColor(Game game) {
    switch (game) {
      case Game.leagueOfLegends:
        return Colors.blue;
      case Game.valorant:
        return Colors.red;
      case Game.teamfightTactics:
        return Colors.purple;
      case Game.wildRift:
        return Colors.teal;
      case Game.legendsOfRuneterra:
        return Colors.orange;
    }
  }

  void _editPlayer(Player player) async {
    final result = await showDialog<Player>(
      context: context,
      builder: (context) => EditPlayerModal(player: player), // Utiliser le modal d'édition avec préremplissage
    );
    
    if (result != null) {
      final playersProvider = Provider.of<PlayersProvider>(context, listen: false);
      await playersProvider.updatePlayer(result);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joueur "${result.pseudo}" modifié avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _deletePlayer(Player player) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le joueur "${player.pseudo}" ?\n\nCette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final playersProvider = Provider.of<PlayersProvider>(context, listen: false);
      await playersProvider.deletePlayer(player.id);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Joueur "${player.pseudo}" supprimé'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

