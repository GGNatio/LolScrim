import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/team.dart';
import '../services/lol_connection_service.dart';
import '../services/live_game_tracker_service.dart';
import 'live_scrim_config_screen.dart';

/// Écran principal de tracking d'un scrim en direct
class LiveScrimTrackingScreen extends StatefulWidget {
  final Team yourTeam;
  final String opponentTeamName;
  final ScrimMode scrimMode;
  final int bestOfValue;
  final int numberOfGames;
  final String notes;

  const LiveScrimTrackingScreen({
    super.key,
    required this.yourTeam,
    required this.opponentTeamName,
    required this.scrimMode,
    required this.bestOfValue,
    required this.numberOfGames,
    required this.notes,
  });

  @override
  State<LiveScrimTrackingScreen> createState() => _LiveScrimTrackingScreenState();
}

class _LiveScrimTrackingScreenState extends State<LiveScrimTrackingScreen> {
  late LiveGameTrackerService _tracker;
  int _yourScore = 0;
  int _opponentScore = 0;
  int _currentGameIndex = 0;
  final List<GameResult> _gameResults = [];
  bool _scrimEnded = false;
  LiveGameData? _lastGameData; // Sauvegarder les données avant la fin

  @override
  void initState() {
    super.initState();
    _tracker = LiveGameTrackerService();
    _initializeTracker();
  }

  Future<void> _initializeTracker() async {
    final lolService = context.read<LolConnectionService>();
    
    if (!lolService.isConnected) {
      _showError('Non connecté au client LoL. Veuillez vous connecter dans les paramètres.');
      return;
    }

    // Récupérer les credentials LCU
    final lockfileData = await lolService.getLockfileData();
    if (lockfileData != null) {
      _tracker.startTracking(lockfileData['port']!, lockfileData['password']!);
      _tracker.addListener(_onTrackerUpdate);
    }
  }

  void _onTrackerUpdate() {
    if (!mounted) return;
    
    final phase = _tracker.currentPhase;
    final currentData = _tracker.currentGameData;
    
    // Sauvegarder les données pendant la partie
    if (phase == 'InProgress' && currentData != null) {
      _lastGameData = currentData;
    }
    
    // Détecter la fin d'une game
    if (phase == 'WaitingForStats' || phase == 'EndOfGame') {
      if (!_gameEndHandled) {
        _gameEndHandled = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _handleGameEnd();
        });
      }
    } else {
      _gameEndHandled = false; // Reset pour la prochaine game
    }
    
    setState(() {});
  }

  bool _gameEndHandled = false;

  Future<void> _handleGameEnd() async {
    // Utiliser les dernières données sauvegardées (l'API 2999 s'arrête à la fin)
    final gameData = _lastGameData;
    
    if (gameData == null) {
      debugPrint('❌ Aucune donnée de partie disponible !');
      return;
    }
    
    // Afficher le dialog de résultat avec les stats complètes
    final won = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildGameResultDialog(gameData),
    );
    
    if (won != null) {
      // Sauvegarder toutes les données de la partie
      final gameEndData = {
        'gameNumber': _currentGameIndex + 1,
        'won': won,
        'gameTime': gameData?.gameTime ?? 0,
        'gameMode': gameData?.gameMode ?? 'CLASSIC',
        'timestamp': DateTime.now().toIso8601String(),
        'players': gameData?.players.map((p) => {
          'summonerName': p.summonerName,
          'championName': p.championName,
          'teamId': p.teamId,
          'kills': p.kills,
          'deaths': p.deaths,
          'assists': p.assists,
          'cs': p.cs,
          'level': p.level,
          'gold': p.gold,
          'items': p.items,
        }).toList() ?? [],
      };
      
      setState(() {
        _gameResults.add(GameResult(won: won, data: gameEndData));
        _currentGameIndex++;
      });
      
      debugPrint('💾 Game ${_currentGameIndex} sauvegardée: ${won ? "VICTOIRE" : "DÉFAITE"}');
      debugPrint('📊 Données complètes: $gameEndData');
      
      // Vérifier si le scrim doit se terminer
      if (_shouldEndScrim) {
        _showEndScrimDialog();
      }
    }
  }

  Widget _buildGameResultDialog(LiveGameData? gameData) {
    if (gameData == null) {
      return AlertDialog(
        title: const Text('Fin de partie'),
        content: const Text('Aucune donnée disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    final blueSide = gameData.getTeamPlayers(100);
    final redSide = gameData.getTeamPlayers(200);
    final blueKills = blueSide.fold<int>(0, (sum, p) => sum + p.kills);
    final redKills = redSide.fold<int>(0, (sum, p) => sum + p.kills);
    final minutes = (gameData.gameTime / 60).floor();
    final seconds = (gameData.gameTime % 60).floor();

    return AlertDialog(
      title: const Text('Fin de partie', textAlign: TextAlign.center),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Durée de la partie
              Text(
                'Durée: $minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Score
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$blueKills',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0BC6E3)),
                  ),
                  const Text(' - ', style: TextStyle(fontSize: 24)),
                  Text(
                    '$redKills',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFFE84057)),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Stats des joueurs
              _buildTeamStats('BLUE SIDE', blueSide, const Color(0xFF0BC6E3)),
              const SizedBox(height: 16),
              _buildTeamStats('RED SIDE', redSide, const Color(0xFFE84057)),
              
              const SizedBox(height: 24),
              const Text(
                'Résultat de la partie ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Boutons Victoire/Défaite
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('VICTOIRE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.cancel),
                      label: const Text('DÉFAITE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
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

  Widget _buildTeamStats(String teamName, List<LivePlayer> players, Color teamColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          teamName,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: teamColor),
        ),
        const SizedBox(height: 8),
        ...players.map((p) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '${p.championName} (${p.summonerName})',
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.kills}/${p.deaths}/${p.assists}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${p.cs} CS • ${(p.gold / 1000).toStringAsFixed(1)}k',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        )),
      ],
    );
  }

  void _showEndScrimDialog() {
    final wins = _gameResults.where((r) => r.won).length;
    final losses = _gameResults.length - wins;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Scrim terminé !', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              wins > losses ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              size: 64,
              color: wins > losses ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Score final : $wins - $losses',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              wins > losses ? 'Victoire du scrim !' : 'Défaite du scrim',
              style: TextStyle(
                fontSize: 18,
                color: wins > losses ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer le dialog
              Navigator.of(context).pop(); // Retour à l'écran précédent
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool get _shouldEndScrim {
    if (_scrimEnded) return true;
    
    if (widget.scrimMode == ScrimMode.bestOf) {
      final requiredWins = (widget.bestOfValue / 2).ceil();
      return _yourScore >= requiredWins || _opponentScore >= requiredWins;
    } else {
      return _gameResults.length >= widget.numberOfGames;
    }
  }

  @override
  void dispose() {
    _tracker.stopTracking();
    _tracker.removeListener(_onTrackerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.yourTeam.name} vs ${widget.opponentTeamName}'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [
          // Indicateur de connexion
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _tracker.isTracking ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _tracker.isTracking ? 'Connecté' : 'Déconnecté',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec score
          _buildScoreHeader(),
          
          // Onglets des games
          if (_gameResults.isNotEmpty || _tracker.currentGameData != null)
            _buildGameTabs(),
          
          // Contenu principal
          Expanded(
            child: _buildGameContent(),
          ),
          
          // Bouton terminer
          if (_shouldEndScrim)
            _buildEndScrimButton(),
        ],
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  widget.yourTeam.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  '$_yourScore - $_opponentScore',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.opponentTeamName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.scrimMode == ScrimMode.bestOf
                ? 'Best of ${widget.bestOfValue}'
                : '${widget.numberOfGames} matchs',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildGameTabs() {
    return Container(
      height: 60,
      color: Colors.grey.shade100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _gameResults.length + (_tracker.currentGameData != null ? 1 : 0),
        itemBuilder: (context, index) {
          final isCurrentGame = index == _gameResults.length;
          final isActive = isCurrentGame || index == _currentGameIndex;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _currentGameIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Game ${index + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.black,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrentGame)
                      Icon(
                        Icons.videogame_asset,
                        size: 16,
                        color: isActive ? Colors.white : Colors.green,
                      )
                    else if (index < _gameResults.length)
                      Icon(
                        _gameResults[index].won ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: isActive
                            ? Colors.white
                            : (_gameResults[index].won ? Colors.green : Colors.red),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameContent() {
    final gameData = _tracker.currentGameData;
    final phase = _tracker.currentPhase;

    if (gameData == null) {
      return _buildWaitingForGame();
    }

    if (gameData.phase == 'ChampSelect') {
      return _buildChampSelectView(gameData);
    } else if (gameData.phase == 'InProgress') {
      return _buildInGameView(gameData);
    }

    return _buildWaitingForGame();
  }

  Widget _buildWaitingForGame() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'En attente de la prochaine partie...',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Lancez une partie personnalisée pour commencer',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildChampSelectView(LiveGameData gameData) {
    final blueSide = gameData.getTeamPlayers(100);
    final redSide = gameData.getTeamPlayers(200);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Phase indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.person_search, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Champion Select',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Sélection des champions en cours'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Blue side
          _buildTeamSection('Votre équipe (BLUE SIDE)', blueSide, Colors.blue, true),
          
          const SizedBox(height: 24),
          
          // Red side
          _buildTeamSection('Équipe adverse (RED SIDE)', redSide, Colors.red, false),
        ],
      ),
    );
  }

  Widget _buildInGameView(LiveGameData gameData) {
    final blueSide = gameData.getTeamPlayers(100);
    final redSide = gameData.getTeamPlayers(200);
    
    final minutes = (gameData.gameTime / 60).floor();
    final seconds = (gameData.gameTime % 60).floor();
    
    final blueKills = blueSide.fold<int>(0, (sum, p) => sum + p.kills);
    final redKills = redSide.fold<int>(0, (sum, p) => sum + p.kills);
    final blueGold = blueSide.fold<int>(0, (sum, p) => sum + p.gold);
    final redGold = redSide.fold<int>(0, (sum, p) => sum + p.gold);
    final goldDiff = blueGold - redGold;

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFF0A0E14),
        child: Column(
          children: [
            // Header avec score et temps
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2328),
                border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Score blue
                  Text(
                    '$blueKills',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0BC6E3)),
                  ),
                  // Timer et gold diff
                  Column(
                    children: [
                      Text(
                        '$minutes:${seconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: goldDiff > 0 ? const Color(0xFF0BC6E3) : const Color(0xFFE84057),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${goldDiff > 0 ? '+' : ''}${(goldDiff / 1000).toStringAsFixed(1)}k',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  // Score red
                  Text(
                    '$redKills',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFFE84057)),
                  ),
                ],
              ),
            ),
            
            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2328),
                border: Border(bottom: BorderSide(color: Color(0xFF30363D))),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 40), // Level
                  const SizedBox(width: 180), // Player
                  _buildColumnHeader('K / D / A', 100),
                  _buildColumnHeader('CS', 60),
                  _buildColumnHeader('OR', 80),
                  _buildColumnHeader('ITEMS', 200),
                ],
              ),
            ),
            
            // Blue team
            _buildScoreboardTeam('ÉQUIPE 1', blueSide, const Color(0xFF0BC6E3)),
            
            const SizedBox(height: 2),
            
            // Red team  
            _buildScoreboardTeam('ÉQUIPE 2', redSide, const Color(0xFFE84057)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildColumnHeader(String text, double width) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7B8490)),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildScoreboardTeam(String teamName, List<LivePlayer> players, Color teamColor) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E14),
        border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Team header
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E2328),
            child: Text(
              teamName,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: teamColor),
            ),
          ),
          // Players
          ...players.map((player) => _buildScoreboardPlayerRow(player)),
        ],
      ),
    );
  }
  
  Widget _buildScoreboardPlayerRow(LivePlayer player) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E2328))),
      ),
      child: Row(
        children: [
          // Level badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2328),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(
                '${player.level}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          // Champion & player name
          SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.championName.isNotEmpty ? player.championName : 'Unknown',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  player.summonerName,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7B8490)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // KDA
          SizedBox(
            width: 100,
            child: Text(
              '${player.kills} / ${player.deaths} / ${player.assists}',
              style: const TextStyle(fontSize: 13, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          
          // CS
          SizedBox(
            width: 60,
            child: Text(
              '${player.cs}',
              style: const TextStyle(fontSize: 13, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Gold
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, size: 14, color: Color(0xFFFFD700)),
                const SizedBox(width: 4),
                Text(
                  '${(player.gold / 1000).toStringAsFixed(1)}k',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFFFD700)),
                ),
              ],
            ),
          ),
          
          // Items
          SizedBox(
            width: 200,
            child: Row(
              children: List.generate(6, (i) {
                final hasItem = i < player.items.length && player.items[i] != 0;
                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: hasItem ? const Color(0xFF1E2328) : const Color(0xFF0A0E14),
                    border: Border.all(color: const Color(0xFF30363D)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: hasItem 
                    ? Center(
                        child: Text(
                          '${player.items[i]}',
                          style: const TextStyle(fontSize: 8, color: Colors.white),
                        ),
                      )
                    : null,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalStats(List<LivePlayer> blueSide, List<LivePlayer> redSide) {
    final blueGold = blueSide.fold<int>(0, (sum, p) => sum + p.gold);
    final redGold = redSide.fold<int>(0, (sum, p) => sum + p.gold);
    final goldDiff = blueGold - redGold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Or', '${(blueGold / 1000).toStringAsFixed(1)}k', Colors.blue),
                Text(
                  goldDiff > 0 ? '+${(goldDiff / 1000).toStringAsFixed(1)}k' : '${(goldDiff / 1000).toStringAsFixed(1)}k',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: goldDiff > 0 ? Colors.green : Colors.red,
                  ),
                ),
                _buildStatColumn('Or', '${(redGold / 1000).toStringAsFixed(1)}k', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(String title, List<LivePlayer> players, Color color, bool isYourTeam) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: players.map((player) => _buildPlayerRow(player, isYourTeam)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(LivePlayer player, bool isYourTeam) {
    final isInGame = _tracker.currentGameData?.phase == 'InProgress';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          // Champion icon placeholder
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.person, size: 32),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.championName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  player.summonerName,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (player.position != 'NONE')
                  Text(
                    player.position,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          
          // Stats
          if (isInGame) ...[
            _buildStatChip('${player.kills}/${player.deaths}/${player.assists}', Icons.military_tech),
            const SizedBox(width: 8),
            _buildStatChip('Lvl ${player.level}', Icons.trending_up),
            const SizedBox(width: 8),
            _buildStatChip('${player.cs} CS', Icons.agriculture),
            const SizedBox(width: 8),
            _buildStatChip('${(player.gold / 1000).toStringAsFixed(1)}k', Icons.monetization_on),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEndScrimButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _endScrim,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 0),
        ),
        child: const Text(
          'Terminer le scrim',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _endScrim() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer le scrim'),
        content: const Text('Êtes-vous sûr de vouloir terminer ce scrim ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
            _tracker.stopTracking();
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Terminer'),
        ),
      ],
    ),
  );
}

}

/// Résultat d'une game
class GameResult {
  final bool won;
  final Map<String, dynamic>? data;

  GameResult({required this.won, this.data});
}
