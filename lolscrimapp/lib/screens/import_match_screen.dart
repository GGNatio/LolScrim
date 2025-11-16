import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/champion.dart';

import '../services/riot_api_service.dart';
import '../services/scrims_provider.dart';
import '../screens/scrim_match_details_screen.dart';
import 'package:uuid/uuid.dart';

/// Écran d'importation d'un match via l'API Riot
class ImportMatchScreen extends StatefulWidget {
  final Team team;

  const ImportMatchScreen({
    super.key,
    required this.team,
  });

  @override
  State<ImportMatchScreen> createState() => _ImportMatchScreenState();
}

class _ImportMatchScreenState extends State<ImportMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matchIdController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasApiKey = false;
  RiotMatchData? _matchPreview;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }
  
  @override
  void dispose() {
    _matchIdController.dispose();
    _apiKeyController.dispose();
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _checkApiKey() async {
    final apiKey = await RiotApiService.getApiKey();
    setState(() {
      _hasApiKey = apiKey != null && apiKey.isNotEmpty;
      if (_hasApiKey) {
        _apiKeyController.text = apiKey!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importer un match'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec infos
              Card(
                color: Colors.blue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Import automatique Riot Games',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Importez toutes les données d\'une partie (KDA, dégâts, CS, items, objectifs) '
                        'automatiquement via l\'API Riot Games.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Configuration API Key
              if (!_hasApiKey) ...[
                Text(
                  'Configuration API Riot',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.orange.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🔑 Clé API requise',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pour importer des matchs, vous devez fournir votre clé API Riot Games.\n'
                          '1. Allez sur https://developer.riotgames.com/\n'
                          '2. Connectez-vous avec votre compte Riot\n'
                          '3. Générez une "Development API Key"\n'
                          '4. Copiez-collez la clé ci-dessous',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _apiKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Clé API Riot *',
                            hintText: 'RGAPI-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) {
                              return 'La clé API est requise';
                            }
                            if (!value!.startsWith('RGAPI-')) {
                              return 'Format de clé API invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveApiKey,
                                child: const Text('Sauvegarder la clé'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Import de match
              if (_hasApiKey) ...[
                Text(
                  'Importer un match',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _matchIdController,
                  decoration: const InputDecoration(
                    labelText: 'Code du match *',
                    hintText: 'Ex: EUW1_7602580136',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_esports),
                  ),
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) {
                      return 'Le code du match est requis';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du scrim (optionnel)',
                    hintText: 'Ex: Scrim vs Team Alpha',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _previewMatch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
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
                            : const Text('Prévisualiser le match'),
                      ),
                    ),
                  ],
                ),
                
                // Message d'erreur
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Prévisualisation du match
                if (_matchPreview != null) ...[
                  const SizedBox(height: 24),
                  _buildMatchPreview(),
                ],
              ],
              
              // Gestion de la clé API existante
              if (_hasApiKey) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.vpn_key, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    const Text('Clé API configurée', style: TextStyle(color: Colors.green)),
                    const Spacer(),
                    TextButton(
                      onPressed: _clearApiKey,
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatchPreview() {
    final match = _matchPreview!.info;
    final duration = Duration(seconds: match.gameDuration);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Prévisualisation du match',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Durée: ${minutes}min ${seconds}s'),
                      Text('Patch: ${match.gameVersion}'),
                      Text('Mode: ${match.gameMode}'),
                      Text('Participants: ${match.participants.length}'),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Liste des participants
            const Text('Participants:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            ...match.participants.take(10).map((participant) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: participant.win ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${participant.summonerName} (${participant.championName})',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    '${participant.kills}/${participant.deaths}/${participant.assists}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _matchPreview = null;
                        _errorMessage = null;
                      });
                    },
                    child: const Text('Modifier'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _importMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Importer ce match'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await RiotApiService.saveApiKey(_apiKeyController.text.trim());
      setState(() {
        _hasApiKey = true;
        _errorMessage = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Clé API sauvegardée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sauvegarde: $e';
      });
    }
  }
  
  Future<void> _clearApiKey() async {
    await RiotApiService.clearApiKey();
    setState(() {
      _hasApiKey = false;
      _apiKeyController.clear();
      _matchPreview = null;
      _errorMessage = null;
    });
  }
  
  Future<void> _previewMatch() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _matchPreview = null;
    });
    
    try {
      final matchId = _matchIdController.text.trim();
      final matchData = await RiotApiService.getMatchData(matchId);
      
      if (matchData != null) {
        setState(() {
          _matchPreview = matchData;
          // Auto-générer un nom si pas fourni
          if (_nameController.text.trim().isEmpty) {
            final date = DateTime.now().toString().split(' ')[0];
            _nameController.text = 'Match importé - $date';
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Aucune donnée trouvée pour ce match';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _importMatch() async {
    if (_matchPreview == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Créer le scrim avec les données importées
      final scrim = await _createScrimFromRiotData(_matchPreview!);
      
      // Sauvegarder le scrim
      final scrimsProvider = Provider.of<ScrimsProvider>(context, listen: false);
      await scrimsProvider.addScrim(scrim);
      
      if (mounted) {
        // Naviguer vers la page de détails
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScrimMatchDetailsScreen(
              scrim: scrim,
              team: widget.team,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'import: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<Scrim> _createScrimFromRiotData(RiotMatchData matchData) async {
    final match = matchData.info;
    
    // Déterminer quelle équipe correspond à notre équipe
    // Pour l'instant, on prend la première équipe comme notre équipe
    final team1Participants = match.participants.where((p) => p.teamId == 100).toList();
    final team2Participants = match.participants.where((p) => p.teamId == 200).toList();
    
    final myTeam = team1Participants;
    final enemyTeam = team2Participants;
    
    final myTeamWon = myTeam.first.win;
    
    // Créer le match avec les données importées
    final scrimMatch = ScrimMatch(
      matchNumber: 1,
      myTeamPlayers: myTeam.map((p) => _participantToTeamPlayer(p)).toList(),
      enemyPlayers: enemyTeam.map((p) => _participantToEnemyPlayer(p)).toList(),
      myTeamScore: myTeam.fold<int>(0, (sum, p) => sum + p.kills),
      enemyTeamScore: enemyTeam.fold<int>(0, (sum, p) => sum + p.kills),
      isVictory: myTeamWon,
      matchDuration: Duration(seconds: match.gameDuration),
      notes: 'Match importé via l\'API Riot Games le ${DateTime.now().toString().split(' ')[0]}',
    );
    
    return Scrim(
      id: const Uuid().v4(),
      name: _nameController.text.trim().isNotEmpty 
          ? _nameController.text.trim()
          : 'Match importé - ${DateTime.now().toString().split(' ')[0]}',
      myTeamId: widget.team.id,
      enemyTeamName: 'Équipe adverse (importée)',
      totalMatches: 1,
      matches: [scrimMatch],
      myTeamWins: myTeamWon ? 1 : 0,
      enemyTeamWins: myTeamWon ? 0 : 1,
      createdAt: match.gameCreation,
      patch: match.gameVersion,
      notes: 'Scrim créé automatiquement via l\'API Riot Games',
    );
  }
  
  TeamPlayer _participantToTeamPlayer(RiotParticipant participant) {
    // Trouver le champion correspondant
    String championId;
    try {
      final champion = Champions.all.firstWhere(
        (c) => c.name.toLowerCase() == participant.championName.toLowerCase(),
      );
      championId = champion.id;
    } catch (e) {
      // Si le champion n'est pas trouvé, utiliser le nom comme ID
      championId = participant.championName.toLowerCase();
    }
    
    return TeamPlayer(
      playerId: null, // Pas d'ID joueur pour les imports automatiques
      pseudo: participant.summonerName,
      role: _getRoleFromParticipant(participant),
      championId: championId,
      kills: participant.kills,
      deaths: participant.deaths,
      assists: participant.assists,
      cs: participant.totalCs,
      gold: participant.goldEarned,
      damage: participant.totalDamageDealtToChampions,
    );
  }
  
  EnemyPlayer _participantToEnemyPlayer(RiotParticipant participant) {
    // Trouver le champion correspondant
    String championId;
    try {
      final champion = Champions.all.firstWhere(
        (c) => c.name.toLowerCase() == participant.championName.toLowerCase(),
      );
      championId = champion.id;
    } catch (e) {
      // Si le champion n'est pas trouvé, utiliser le nom comme ID
      championId = participant.championName.toLowerCase();
    }
    
    return EnemyPlayer(
      pseudo: participant.summonerName,
      role: _getRoleFromParticipant(participant),
      championId: championId,
      kills: participant.kills,
      deaths: participant.deaths,
      assists: participant.assists,
      cs: participant.totalCs,
      gold: participant.goldEarned,
      damage: participant.totalDamageDealtToChampions,
    );
  }
  
  String _getRoleFromParticipant(RiotParticipant participant) {
    // Mapping basique des rôles
    switch (participant.teamPosition.toLowerCase()) {
      case 'top': return 'Top';
      case 'jungle': return 'Jungle';
      case 'middle': return 'Mid';
      case 'bottom': return 'ADC';
      case 'utility': return 'Support';
      default: return 'Mid'; // Par défaut
    }
  }
}