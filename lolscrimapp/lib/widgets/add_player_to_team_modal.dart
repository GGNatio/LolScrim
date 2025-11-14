import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/players_provider.dart';
import '../services/teams_provider.dart';

/// Modal pour ajouter un joueur à une équipe
class AddPlayerToTeamModal extends StatefulWidget {
  final Team team;

  const AddPlayerToTeamModal({
    super.key,
    required this.team,
  });

  @override
  State<AddPlayerToTeamModal> createState() => _AddPlayerToTeamModalState();
}

class _AddPlayerToTeamModalState extends State<AddPlayerToTeamModal> {
  Player? selectedPlayer;
  String searchQuery = '';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  const Icon(Icons.person_add, size: 28, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ajouter un joueur à ${widget.team.name}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Informations sur l'équipe
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Jeu: ${widget.team.game.displayName} • ${widget.team.playerIds.length}/5 joueurs',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Barre de recherche
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Rechercher un joueur',
                  hintText: 'Tapez le nom d\'un joueur...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 16),

              // Liste des joueurs disponibles
              Expanded(
                child: Consumer2<PlayersProvider, TeamsProvider>(
                  builder: (context, playersProvider, teamsProvider, child) {
                    final availablePlayers = _getAvailablePlayers(playersProvider, teamsProvider);
                    
                    if (availablePlayers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun joueur disponible',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tous les joueurs compatibles sont déjà dans des équipes ou aucun joueur ${widget.team.game.displayName} n\'est disponible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: availablePlayers.length,
                      itemBuilder: (context, index) {
                        final player = availablePlayers[index];
                        final isSelected = selectedPlayer?.id == player.id;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          color: isSelected ? Colors.blue.shade50 : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200,
                              child: Text(
                                player.pseudo[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            title: Text(
                              player.pseudo,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${player.role}${player.rank != null ? ' • ${player.rank}' : ''}'),
                                Text(
                                  player.inGameId,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              color: isSelected ? Colors.blue : Colors.grey,
                            ),
                            onTap: () {
                              setState(() {
                                selectedPlayer = isSelected ? null : player;
                              });
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Boutons d'action
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: selectedPlayer == null || isLoading ? null : _addPlayerToTeam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Ajouter à l\'équipe'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Player> _getAvailablePlayers(PlayersProvider playersProvider, TeamsProvider teamsProvider) {
    return playersProvider.players.where((player) {
      // Filtrer par jeu
      if (player.game != widget.team.game) return false;
      
      // Filtrer par recherche
      if (searchQuery.isNotEmpty && 
          !player.pseudo.toLowerCase().contains(searchQuery) &&
          !player.inGameId.toLowerCase().contains(searchQuery) &&
          !player.role.toLowerCase().contains(searchQuery)) {
        return false;
      }
      
      // Exclure les joueurs déjà dans cette équipe
      if (widget.team.playerIds.contains(player.id)) return false;
      
      // Exclure les joueurs déjà dans d'autres équipes complètes
      final playerTeams = teamsProvider.teams.where((team) => 
        team.playerIds.contains(player.id)
      ).toList();
      
      // Un joueur peut être dans plusieurs équipes tant qu'elles ne sont pas complètes
      // ou dans des jeux différents
      return playerTeams.every((team) => 
        !team.hasFullRoster || team.game != widget.team.game
      );
    }).toList();
  }

  Future<void> _addPlayerToTeam() async {
    if (selectedPlayer == null) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      final teamsProvider = Provider.of<TeamsProvider>(context, listen: false);
      
      // Ajouter le joueur à l'équipe
      await teamsProvider.addPlayerToTeam(widget.team.id, selectedPlayer!.id);
      
      if (mounted) {
        Navigator.pop(context, selectedPlayer);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${selectedPlayer!.pseudo} ajouté à l\'équipe ${widget.team.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}