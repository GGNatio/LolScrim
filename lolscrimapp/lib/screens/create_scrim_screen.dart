import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../services/scrims_provider.dart';
import '../services/teams_provider.dart';
import 'scrim_match_details_screen.dart';
import 'import_match_screen.dart';

/// Écran de création d'un nouveau scrim
class CreateScrimScreen extends StatefulWidget {
  final Team team;

  const CreateScrimScreen({
    super.key,
    required this.team,
  });

  @override
  State<CreateScrimScreen> createState() => _CreateScrimScreenState();
}

class _CreateScrimScreenState extends State<CreateScrimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _enemyTeamController = TextEditingController();
  final _notesController = TextEditingController();
  
  int _totalMatches = 1;
  int _myTeamWins = 0;
  int _enemyTeamWins = 0;
  String? _patch;
  bool _isLoading = false;
  Team? _selectedTeam;

  @override
  void initState() {
    super.initState();
    _selectedTeam = widget.team;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _enemyTeamController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un scrim'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sélection d'équipe (simple)
              Consumer<TeamsProvider>(
                builder: (context, teamsProvider, child) {
                  return DropdownButtonFormField<Team>(
                    initialValue: _selectedTeam,
                    decoration: const InputDecoration(
                      labelText: 'Équipe qui joue *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports_esports),
                    ),
                    items: teamsProvider.teams.map((team) {
                      return DropdownMenuItem<Team>(
                        value: team,
                        child: Text('${team.name} (${team.playerIds.length} joueurs)'),
                      );
                    }).toList(),
                    onChanged: (Team? team) {
                      setState(() {
                        _selectedTeam = team;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une équipe';
                      }
                      return null;
                    },
                  );
                },
              ),
              
              const SizedBox(height: 16),
              

              
              // Nom du scrim
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du scrim *',
                  hintText: 'Ex: Scrim vs Team Alpha - 14/11/2024',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_esports),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Le nom du scrim est obligatoire';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Équipe adverse
              TextFormField(
                controller: _enemyTeamController,
                decoration: const InputDecoration(
                  labelText: 'Équipe adverse *',
                  hintText: 'Nom de l\'équipe contre qui vous jouez',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Le nom de l\'équipe adverse est obligatoire';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Configuration du BO
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sports_esports, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Configuration du Best-Of',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Nombre de matchs
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Nombre de matchs:', style: TextStyle(fontWeight: FontWeight.w500)),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: _totalMatches > 1 ? () {
                                    setState(() {
                                      _totalMatches--;
                                      // Ajuster les victoires si nécessaire
                                      if (_myTeamWins + _enemyTeamWins > _totalMatches) {
                                        _myTeamWins = 0;
                                        _enemyTeamWins = 0;
                                      }
                                    });
                                  } : null,
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_totalMatches',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _totalMatches < 9 ? () {
                                    setState(() => _totalMatches++);
                                  } : null,
                                  icon: const Icon(Icons.add_circle),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Victoires de mon équipe
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'Victoires ${_selectedTeam?.name ?? 'Mon équipe'}:',
                              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.blue),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: _myTeamWins > 0 ? () {
                                    setState(() => _myTeamWins--);
                                  } : null,
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.blue),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.blue.withOpacity(0.1),
                                  ),
                                  child: Text(
                                    '$_myTeamWins',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                                IconButton(
                                  onPressed: (_myTeamWins + _enemyTeamWins < _totalMatches) ? () {
                                    setState(() => _myTeamWins++);
                                  } : null,
                                  icon: const Icon(Icons.add_circle),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Victoires équipe adverse
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Victoires équipe adverse:',
                              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  onPressed: _enemyTeamWins > 0 ? () {
                                    setState(() => _enemyTeamWins--);
                                  } : null,
                                  icon: const Icon(Icons.remove_circle),
                                  color: Colors.red,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red),
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.red.withOpacity(0.1),
                                  ),
                                  child: Text(
                                    '$_enemyTeamWins',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ),
                                IconButton(
                                  onPressed: (_myTeamWins + _enemyTeamWins < _totalMatches) ? () {
                                    setState(() => _enemyTeamWins++);
                                  } : null,
                                  icon: const Icon(Icons.add_circle),
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Récapitulatif
                      if (_totalMatches > 1) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Text('Score actuel', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '$_myTeamWins - $_enemyTeamWins',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Text('Matchs restants', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  '${_totalMatches - _myTeamWins - _enemyTeamWins}',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ],
                            ),
                            if (_myTeamWins > _enemyTeamWins)
                              const Column(
                                children: [
                                  Text('Statut', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('🏆 En tête', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              )
                            else if (_enemyTeamWins > _myTeamWins)
                              const Column(
                                children: [
                                  Text('Statut', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('⚠️ Derrière', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                                ],
                              )
                            else
                              const Column(
                                children: [
                                  Text('Statut', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text('🤝 Égalité', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                                ],
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Patch
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Patch (optionnel)',
                  hintText: 'Ex: 13.24',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.update),
                ),
                onChanged: (value) => _patch = value.trim().isEmpty ? null : value,
              ),
              
              const SizedBox(height: 16),
              
              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Notes sur le scrim, stratégies testées, points à retenir...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note_alt),
                  alignLabelWithHint: true,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton d'import automatique
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImportMatchScreen(team: _selectedTeam ?? widget.team),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.cloud_download,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Importer un match automatiquement',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Utilisez l\'API Riot pour importer toutes les données d\'une partie (KDA, CS, dégâts, items, objectifs) automatiquement via un code de match.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Divider avec "OU"
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createScrim,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Suivant : Détails des matchs'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Crée une liste de 5 joueurs d'équipe vides avec des rôles par défaut
  List<TeamPlayer> _createEmptyTeamPlayers() {
    final defaultRoles = ['Top', 'Jungle', 'Mid', 'ADC', 'Support'];
    
    return List.generate(5, (index) => TeamPlayer(
      playerId: null, // Pas de joueur assigné initially
      pseudo: 'Joueur ${index + 1}',
      role: defaultRoles[index],
      championId: '', // Pas de champion sélectionné
      kills: null,
      deaths: null,
      assists: null,
      cs: null,
      gold: null,
      damage: null,
    ));
  }
  
  /// Crée une liste de 5 joueurs ennemis vides avec des rôles par défaut  
  List<EnemyPlayer> _createEmptyEnemyPlayers() {
    final defaultRoles = ['Top', 'Jungle', 'Mid', 'ADC', 'Support'];
    
    return List.generate(5, (index) => EnemyPlayer(
      pseudo: 'Ennemi ${index + 1}',
      role: defaultRoles[index],
      championId: '', // Pas de champion sélectionné
      kills: null,
      deaths: null,
      assists: null,
      cs: null,
      gold: null,
      damage: null,
    ));
  }

  Future<void> _createScrim() async {
    if (!_formKey.currentState!.validate()) return;
    


    setState(() => _isLoading = true);

    try {
      // Générer l'ID du scrim
      final scrimId = const Uuid().v4();
      
      // Créer automatiquement tous les matchs vides selon le nombre configuré
      final List<ScrimMatch> emptyMatches = [];
      for (int i = 1; i <= _totalMatches; i++) {
        emptyMatches.add(ScrimMatch(
          matchNumber: i,
          myTeamPlayers: _createEmptyTeamPlayers(),
          enemyPlayers: _createEmptyEnemyPlayers(),
          myTeamScore: null,
          enemyTeamScore: null,
          isVictory: null,
          matchDuration: const Duration(minutes: 30),
          notes: 'Match $i - Vide',
        ));
      }
      
      // Créer le scrim avec tous les matchs pré-générés
      final scrim = Scrim(
        id: scrimId,
        name: _nameController.text.trim(),
        myTeamId: _selectedTeam?.id ?? widget.team.id,
        enemyTeamName: _enemyTeamController.text.trim(),
        totalMatches: _totalMatches,
        matches: emptyMatches, // ✅ Maintenant pré-rempli avec tous les matchs vides
        myTeamWins: _myTeamWins,
        enemyTeamWins: _enemyTeamWins,
        createdAt: DateTime.now(),
        patch: _patch,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      // Sauvegarder le scrim
      final scrimsProvider = Provider.of<ScrimsProvider>(context, listen: false);
      await scrimsProvider.addScrim(scrim);

      if (mounted) {
        // Naviguer vers la page de détails des matchs
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScrimMatchDetailsScreen(
              scrim: scrim,
              team: _selectedTeam ?? widget.team,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la création: $e'),
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
}