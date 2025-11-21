import 'package:flutter/material.dart';
import '../services/live_game_tracker_service.dart';

/// Écran scoreboard style LoL pour afficher les stats en temps réel
class LiveScoreboardScreen extends StatelessWidget {
  final LiveGameData gameData;

  const LiveScoreboardScreen({
    super.key,
    required this.gameData,
  });

  @override
  Widget build(BuildContext context) {
    final blueSide = gameData.getTeamPlayers(100);
    final redSide = gameData.getTeamPlayers(200);
    
    final blueKills = blueSide.fold<int>(0, (sum, p) => sum + p.kills);
    final redKills = redSide.fold<int>(0, (sum, p) => sum + p.kills);
    final blueGold = blueSide.fold<int>(0, (sum, p) => sum + p.gold);
    final redGold = redSide.fold<int>(0, (sum, p) => sum + p.gold);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E2328), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête
            _buildHeader(blueKills, redKills, blueGold, redGold),
            
            // Corps avec les deux équipes
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Équipe bleue
                    _buildTeamSection('ÉQUIPE 1', blueSide, const Color(0xFF0BC6E3), true),
                    
                    const Divider(color: Color(0xFF1E2328), thickness: 2, height: 2),
                    
                    // Équipe rouge
                    _buildTeamSection('ÉQUIPE 2', redSide, const Color(0xFFE84057), false),
                  ],
                ),
              ),
            ),
            
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int blueKills, int redKills, int blueGold, int redGold) {
    final minutes = (gameData.gameTime / 60).floor();
    final seconds = (gameData.gameTime % 60).floor();
    final goldDiff = blueGold - redGold;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2328),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Score bleu
          _buildTeamScore('ÉQUIPE 1', blueKills, const Color(0xFF0BC6E3)),
          
          // Temps de jeu et gold diff
          Column(
            children: [
              Text(
                '$minutes:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: goldDiff >= 0 ? const Color(0xFF0BC6E3) : const Color(0xFFE84057),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  goldDiff >= 0 
                      ? '+${(goldDiff / 1000).toStringAsFixed(1)}k'
                      : '${(goldDiff / 1000).toStringAsFixed(1)}k',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          // Score rouge
          _buildTeamScore('ÉQUIPE 2', redKills, const Color(0xFFE84057)),
        ],
      ),
    );
  }

  Widget _buildTeamScore(String teamName, int kills, Color color) {
    return Column(
      children: [
        Text(
          teamName,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          kills.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(String title, List<LivePlayer> players, Color color, bool isBlue) {
    return Container(
      color: const Color(0xFF0A0E14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de colonne
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    'LVL',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
                  child: Text(
                    'JOUEUR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'K / D / A',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'CS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'OR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 200,
                  child: Text(
                    'ITEMS',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Lignes de joueurs
          ...players.map((player) => _buildPlayerRow(player, color)),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(LivePlayer player, Color teamColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: const Color(0xFF1E2328), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Level
          Container(
            width: 50,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2328),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: teamColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${player.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Nom du joueur et champion
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.championName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    player.summonerName,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // KDA
          SizedBox(
            width: 100,
            child: Text(
              '${player.kills} / ${player.deaths} / ${player.assists}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // CS
          SizedBox(
            width: 70,
            child: Text(
              '${player.cs}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          
          // Or
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${(player.gold / 1000).toStringAsFixed(1)}k',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Items
          SizedBox(
            width: 200,
            child: Row(
              children: List.generate(6, (index) {
                final hasItem = index < player.items.length && player.items[index] != 0;
                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: hasItem ? const Color(0xFF1E2328) : Colors.transparent,
                    border: Border.all(
                      color: const Color(0xFF1E2328),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: hasItem
                      ? const Center(
                          child: Icon(Icons.shield, color: Colors.white, size: 16),
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

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2328),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'FERMER',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
