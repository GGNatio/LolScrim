import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';

/// Modal pour éditer un joueur existant avec préremplissage des champs
class EditPlayerModal extends StatefulWidget {
  final Player player;
  
  const EditPlayerModal({
    super.key,
    required this.player,
  });

  @override
  State<EditPlayerModal> createState() => _EditPlayerModalState();
}

class _EditPlayerModalState extends State<EditPlayerModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _pseudoController;
  late final TextEditingController _inGameIdController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _realNameController;
  late final TextEditingController _regionController;
  
  late Game _selectedGame;
  late String? _selectedRole;
  late String? _selectedRank;

  @override
  void initState() {
    super.initState();
    
    // Préremplir avec les données existantes du joueur
    _pseudoController = TextEditingController(text: widget.player.pseudo);
    _inGameIdController = TextEditingController(text: widget.player.inGameId);
    _descriptionController = TextEditingController(text: widget.player.description ?? '');
    _realNameController = TextEditingController(text: widget.player.realName ?? '');
    _regionController = TextEditingController(text: widget.player.region ?? '');
    
    _selectedGame = widget.player.game;
    _selectedRole = widget.player.role;
    _selectedRank = widget.player.rank;
  }

  void _updateRoleIfNeeded() {
    final roles = GameRoles.getRolesForGame(_selectedGame);
    
    // Si le rôle actuel n'est pas valide pour le nouveau jeu, sélectionner le premier
    if (_selectedRole != null && !roles.contains(_selectedRole)) {
      _selectedRole = roles.isNotEmpty ? roles.first : null;
    }
  }

  void _updateRankIfNeeded() {
    final ranks = GameRanks.getRanksForGame(_selectedGame);
    
    // Si le rang actuel n'est pas valide pour le nouveau jeu, le réinitialiser
    if (_selectedRank != null && !ranks.contains(_selectedRank)) {
      _selectedRank = ranks.isNotEmpty ? ranks.first : null;
    }
  }

  void _onGameChanged(Game? newGame) {
    if (newGame != null && newGame != _selectedGame) {
      setState(() {
        _selectedGame = newGame;
        _updateRoleIfNeeded();
        _updateRankIfNeeded();
      });
    }
  }

  void _updatePlayer() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Veuillez sélectionner un rôle'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedPlayer = widget.player.copyWith(
      pseudo: _pseudoController.text.trim(),
      inGameId: _inGameIdController.text.trim(),
      game: _selectedGame,
      role: _selectedRole!,
      rank: _selectedRank,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      realName: _realNameController.text.trim().isEmpty 
          ? null 
          : _realNameController.text.trim(),
      region: _regionController.text.trim().isEmpty 
          ? null 
          : _regionController.text.trim(),
    );

    Navigator.pop(context, updatedPlayer);
  }

  String _getInGameIdLabel() {
    switch (_selectedGame) {
      case Game.leagueOfLegends:
      case Game.wildRift:
        return 'Nom d\'invocateur';
      case Game.valorant:
        return 'Riot ID (ex: Pseudo#TAG)';
      case Game.teamfightTactics:
        return 'Nom d\'invocateur TFT';
      case Game.legendsOfRuneterra:
        return 'Nom de joueur LoR';
    }
  }

  String _getInGameIdHint() {
    switch (_selectedGame) {
      case Game.leagueOfLegends:
      case Game.wildRift:
        return 'Votre nom d\'invocateur';
      case Game.valorant:
        return 'VotreNom#1234';
      case Game.teamfightTactics:
        return 'Votre nom TFT';
      case Game.legendsOfRuneterra:
        return 'Votre nom LoR';
    }
  }

  @override
  Widget build(BuildContext context) {
    final roles = GameRoles.getRolesForGame(_selectedGame);
    final ranks = GameRanks.getRanksForGame(_selectedGame);
    
    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  children: [
                    const Icon(Icons.edit, size: 28, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      'Modifier ${widget.player.pseudo}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Contenu scrollable
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pseudo (obligatoire)
                        TextFormField(
                          controller: _pseudoController,
                          decoration: const InputDecoration(
                            labelText: 'Pseudo *',
                            hintText: 'Nom affiché du joueur',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'Le pseudo est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Jeu
                        DropdownButtonFormField<Game>(
                          initialValue: _selectedGame,
                          decoration: const InputDecoration(
                            labelText: 'Jeu *',
                            border: OutlineInputBorder(),
                          ),
                          items: Game.values.map((game) {
                            return DropdownMenuItem(
                              value: game,
                              child: Text(game.displayName),
                            );
                          }).toList(),
                          onChanged: _onGameChanged,
                        ),
                        const SizedBox(height: 16),
                        
                        // ID dans le jeu (obligatoire)
                        TextFormField(
                          controller: _inGameIdController,
                          decoration: InputDecoration(
                            labelText: '${_getInGameIdLabel()} *',
                            hintText: _getInGameIdHint(),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return '${_getInGameIdLabel()} est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Rôle (adaptatif selon le jeu)
                        DropdownButtonFormField<String>(
                          initialValue: roles.contains(_selectedRole) ? _selectedRole : null,
                          decoration: const InputDecoration(
                            labelText: 'Rôle *',
                            border: OutlineInputBorder(),
                          ),
                          items: roles.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Rang (adaptatif selon le jeu)
                        DropdownButtonFormField<String>(
                          initialValue: ranks.contains(_selectedRank) ? _selectedRank : null,
                          decoration: const InputDecoration(
                            labelText: 'Rang',
                            border: OutlineInputBorder(),
                          ),
                          items: ranks.map((rank) {
                            return DropdownMenuItem(
                              value: rank,
                              child: Text(rank),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRank = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            hintText: 'Description du joueur, ses spécialités...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        
                        // Nom réel (optionnel)
                        TextFormField(
                          controller: _realNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nom réel',
                            hintText: 'Nom et prénom du joueur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Région (optionnel)
                        TextFormField(
                          controller: _regionController,
                          decoration: const InputDecoration(
                            labelText: 'Région',
                            hintText: 'EUW, NA, KR, etc.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _updatePlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Modifier le joueur'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pseudoController.dispose();
    _inGameIdController.dispose();
    _descriptionController.dispose();
    _realNameController.dispose();
    _regionController.dispose();
    super.dispose();
  }
}