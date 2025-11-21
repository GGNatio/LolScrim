import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:io';
import '../services/lol_connection_service.dart';

/// Écran de debug pour la connexion LCU
class DebugConnectionScreen extends StatefulWidget {
  const DebugConnectionScreen({super.key});

  @override
  State<DebugConnectionScreen> createState() => _DebugConnectionScreenState();
}

class _DebugConnectionScreenState extends State<DebugConnectionScreen> {
  Map<String, dynamic>? _summonerData;
  String? _gameflowPhase;
  Map<String, dynamic>? _lobbyData;
  Map<String, dynamic>? _champSelectData;
  Map<String, dynamic>? _inGameData;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lolService = context.read<LolConnectionService>();

      if (!lolService.isConnected) {
        setState(() {
          _error = 'Non connecté au client LoL';
          _isLoading = false;
        });
        return;
      }

      // Récupérer les données du summoner
      final summoner = await lolService.request('/lol-summoner/v1/current-summoner');
      
      // Récupérer la phase de jeu actuelle (retourne une string)
      final gameflowRaw = await lolService.requestRaw('/lol-gameflow/v1/gameflow-phase');
      final phase = gameflowRaw?.replaceAll('"', '').trim();
      
      // Essayer de récupérer les données du lobby (peut échouer si pas en lobby)
      final lobby = await lolService.request('/lol-lobby/v2/lobby');
      
      // Essayer de récupérer les données de champ select
      final champSelect = await lolService.request('/lol-champ-select/v1/session');
      
      // Si en partie, récupérer les données via l'API in-game (port 2999)
      Map<String, dynamic>? inGame;
      if (phase == 'InProgress' || phase == 'WaitingForStats') {
        inGame = await _getInGameData();
      }

      setState(() {
        _summonerData = summoner;
        _gameflowPhase = phase;
        _lobbyData = lobby;
        _champSelectData = champSelect;
        _inGameData = inGame;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Récupère les données de la partie en cours via l'API in-game (port 2999)
  Future<Map<String, dynamic>?> _getInGameData() async {
    try {
      final client = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      
      final request = await client.getUrl(Uri.parse('https://127.0.0.1:2999/liveclientdata/allgamedata'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        client.close();
        return json.decode(responseBody);
      }
      
      client.close();
      return null;
    } catch (e) {
      // L'API in-game n'est disponible que pendant une partie
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lolService = context.watch<LolConnectionService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Connexion LCU'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // État de connexion
                  _buildConnectionStatus(lolService),
                  const SizedBox(height: 24),

                  // Erreur éventuelle
                  if (_error != null) ...[
                    _buildErrorCard(_error!),
                    const SizedBox(height: 24),
                  ],

                  // Données du summoner
                  if (_summonerData != null) ...[
                    _buildSectionTitle('Informations du joueur'),
                    _buildDataCard(_summonerData!),
                    const SizedBox(height: 24),
                  ],

                  // Phase de jeu
                  if (_gameflowPhase != null) ...[
                    _buildSectionTitle('Phase de jeu'),
                    _buildPhaseCard(_gameflowPhase!),
                    const SizedBox(height: 24),
                  ],

                  // Champ select
                  if (_champSelectData != null) ...[
                    _buildSectionTitle('Champion Select'),
                    _buildDataCard(_champSelectData!),
                    const SizedBox(height: 24),
                  ],

                  // Données du lobby
                  if (_lobbyData != null) ...[
                    _buildSectionTitle('Lobby actuel'),
                    _buildDataCard(_lobbyData!),
                    const SizedBox(height: 24),
                  ],
                  
                  // Données in-game
                  if (_inGameData != null) ...[
                    _buildSectionTitle('Partie en cours (API 2999)'),
                    _buildInGameSummary(_inGameData!),
                    const SizedBox(height: 16),
                    _buildDataCard(_inGameData!),
                    const SizedBox(height: 24),
                  ],
                  
                  // Message si rien d'actif
                  if (_lobbyData == null && _champSelectData == null && _inGameData == null) ...[
                    _buildInfoCard('Aucune activité détectée'),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildConnectionStatus(LolConnectionService service) {
    return Card(
      color: service.isConnected ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              service.isConnected ? Icons.check_circle : Icons.error,
              color: service.isConnected ? Colors.green : Colors.red,
              size: 40,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.isConnected ? 'Connecté' : 'Déconnecté',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: service.isConnected ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  if (service.summonerName != null)
                    Text(
                      'Joueur: ${service.summonerName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPhaseCard(String phase) {
    Color phaseColor;
    IconData phaseIcon;
    
    switch (phase) {
      case 'None':
        phaseColor = Colors.grey;
        phaseIcon = Icons.power_off;
        break;
      case 'Lobby':
        phaseColor = Colors.blue;
        phaseIcon = Icons.people;
        break;
      case 'ChampSelect':
        phaseColor = Colors.orange;
        phaseIcon = Icons.person_search;
        break;
      case 'InProgress':
        phaseColor = Colors.green;
        phaseIcon = Icons.sports_esports;
        break;
      case 'WaitingForStats':
      case 'EndOfGame':
        phaseColor = Colors.purple;
        phaseIcon = Icons.emoji_events;
        break;
      default:
        phaseColor = Colors.grey;
        phaseIcon = Icons.help;
    }
    
    return Card(
      color: phaseColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(phaseIcon, color: phaseColor, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: phaseColor,
                    ),
                  ),
                  Text(
                    _getPhaseDescription(phase),
                    style: TextStyle(
                      fontSize: 14,
                      color: phaseColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseDescription(String phase) {
    switch (phase) {
      case 'None':
        return 'Client inactif';
      case 'Lobby':
        return 'En attente dans le lobby';
      case 'ChampSelect':
        return 'Sélection des champions en cours';
      case 'InProgress':
        return 'Partie en cours';
      case 'WaitingForStats':
        return 'En attente des statistiques';
      case 'EndOfGame':
        return 'Fin de partie';
      default:
        return 'Phase inconnue';
    }
  }

  Widget _buildInGameSummary(Map<String, dynamic> data) {
    final gameData = data['gameData'] as Map<String, dynamic>?;
    final activePlayer = data['activePlayer'] as Map<String, dynamic>?;
    final allPlayers = data['allPlayers'] as List?;
    
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sports_esports, color: Colors.green.shade700, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partie en cours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      if (gameData != null)
                        Text(
                          'Temps: ${_formatGameTime(gameData['gameTime'])} | Mode: ${gameData['gameMode']}',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (activePlayer != null) ...[
              const Divider(),
              Text('Champion: ${activePlayer['championName'] ?? 'Inconnu'}'),
              Text('Level: ${activePlayer['level'] ?? 0}'),
              if (activePlayer['scores'] != null) ...() {
                final scores = activePlayer['scores'] as Map<String, dynamic>;
                return [
                  Text('KDA: ${scores['kills']}/${scores['deaths']}/${scores['assists']}'),
                  Text('CS: ${scores['creepScore'] ?? 0}'),
                ];
              }(),
            ],
            if (allPlayers != null) ...[
              const Divider(),
              Text('Joueurs: ${allPlayers.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ],
        ),
      ),
    );
  }

  String _formatGameTime(dynamic gameTime) {
    if (gameTime == null) return '0:00';
    final seconds = (gameTime is double) ? gameTime.toInt() : gameTime as int;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildDataCard(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Données JSON',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copier JSON',
                  onPressed: () => _copyToClipboard(data),
                ),
              ],
            ),
            const Divider(),
            ...data.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      entry.value.toString(),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                error,
                style: TextStyle(color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String message) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(Map<String, dynamic> data) {
    final jsonString = data.entries
        .map((e) => '  "${e.key}": ${e.value is String ? '"${e.value}"' : e.value}')
        .join(',\n');
    
    Clipboard.setData(ClipboardData(text: '{\n$jsonString\n}'));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Données copiées dans le presse-papier'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
