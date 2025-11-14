import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/player.dart';
import '../models/team.dart';

/// Modal pour créer un nouveau joueur avec champs adaptatifs selon le jeu
class CreatePlayerModal extends StatefulWidget {
  final Game? defaultGame; // Jeu par défaut (si vient d'une équipe)
  
  const CreatePlayerModal({
    super.key,
    this.defaultGame,
  });

  @override
  State<CreatePlayerModal> createState() => _CreatePlayerModalState();
}

class _CreatePlayerModalState extends State<CreatePlayerModal> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoController = TextEditingController();
  final _inGameIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _realNameController = TextEditingController();
  final _regionController = TextEditingController();
  
  Game _selectedGame = Game.leagueOfLegends;
  String? _selectedRole;
  String? _selectedRank;

  @override
  void initState() {
    super.initState();
    if (widget.defaultGame != null) {
      _selectedGame = widget.defaultGame!;
    }
    _updateRoleAndRank();
  }

  void _updateRoleAndRank() {
    final roles = GameRoles.getRolesForGame(_selectedGame);
    final ranks = GameRanks.getRanksForGame(_selectedGame);
    
    // Sélectionner automatiquement le premier rôle et rang disponible
    _selectedRole = roles.isNotEmpty ? roles.first : null;
    _selectedRank = ranks.isNotEmpty ? ranks.first : null;
  }

  void _onGameChanged(Game? newGame) {
    if (newGame != null && newGame != _selectedGame) {
      setState(() {
        _selectedGame = newGame;
        _updateRoleAndRank();
      });
    }
  }

  void _createPlayer() {
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

    final player = Player(
      id: const Uuid().v4(),
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
      createdAt: DateTime.now(),
    );

    Navigator.pop(context, player);
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
                    const Icon(Icons.person_add, size: 28, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Créer un joueur',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          value: _selectedGame,
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
                          value: _selectedRole,
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
                          value: _selectedRank,
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
                      onPressed: _createPlayer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Créer le joueur'),
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