import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../models/team.dart';
import '../models/scrim.dart';
import '../models/champion.dart';
import '../models/player.dart';
import '../models/game_data.dart';
import '../services/players_provider.dart';
import '../services/riot_api_service.dart';
import '../services/scrims_provider.dart';
import 'interactive_ocr_preview_screen.dart';

/// Données temporaires pour un joueur en cours de saisie
class MatchPlayerData {
  String? playerId;
  Champion? champion;
  List<SummonerSpell> summonerSpells = [SummonerSpell.none, SummonerSpell.none];
  List<Item> items = List.filled(6, Item.none);
  int? kills;
  int? deaths;
  int? assists;
  int? cs;
  int? gold;
  int? damage;
  String? pseudoName; // Pour les ennemis libres
  
  MatchPlayerData();
  
  bool get isComplete => 
    playerId != null && 
    champion != null && 
    kills != null && 
    deaths != null && 
    assists != null &&
    cs != null &&
    gold != null &&
    damage != null;
    
  String get kda => '${kills ?? 0} / ${deaths ?? 0} / ${assists ?? 0}';
}

/// Écran de saisie des détails des matchs avec interface League of Legends
class ScrimMatchDetailsScreen extends StatefulWidget {
  final Scrim scrim;
  final Team team;
  final int initialMatchIndex;
  final bool readOnly;

  const ScrimMatchDetailsScreen({
    super.key,
    required this.scrim,
    required this.team,
    this.initialMatchIndex = 0,
    this.readOnly = false,
  });

  @override
  State<ScrimMatchDetailsScreen> createState() => _ScrimMatchDetailsScreenState();
}

class _ScrimMatchDetailsScreenState extends State<ScrimMatchDetailsScreen> {
  late PageController _pageController;
  late Scrim _currentScrim;
  int _currentMatchIndex = 0;
  late String _currentMatchId; // ID unique pour le match en cours
  
  // Données du match en cours
  List<MatchPlayerData> myTeamData = List.generate(5, (_) => MatchPlayerData());
  List<MatchPlayerData> enemyTeamData = List.generate(5, (_) => MatchPlayerData());
  
  // Stats d'équipes
  int myTeamKills = 0;
  int myTeamDeaths = 0;
  int myTeamAssists = 0;
  int myTeamGold = 0;
  
  int enemyTeamKills = 0;
  int enemyTeamDeaths = 0;
  int enemyTeamAssists = 0;
  int enemyTeamGold = 0;
  
  // Objectifs
  int myTeamTurrets = 0;
  int enemyTeamTurrets = 0;
  int myTeamDragons = 0;
  int enemyTeamDragons = 0;
  int myTeamBarons = 0;
  int enemyTeamBarons = 0;
  int myTeamHeralds = 0;
  int enemyTeamHeralds = 0;
  int myTeamGroms = 0;
  int enemyTeamGroms = 0;
  bool myTeamNexusTurrets = false;
  bool enemyTeamNexusTurrets = false;

  // Bans
  List<Champion?> myTeamBans = List.filled(5, null);
  List<Champion?> enemyTeamBans = List.filled(5, null);
  
  bool? isVictory;
  Duration matchDuration = const Duration(minutes: 30);
  
  List<Player> availablePlayers = [];
  List<Champion> availableChampions = [];
  
  // TextEditingControllers pour les KDA de chaque joueur
  final List<List<TextEditingController>> myTeamControllers = [];
  final List<List<TextEditingController>> enemyTeamControllers = [];
  
  // TextEditingControllers pour les objectifs
  final Map<String, TextEditingController> objectiveControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentScrim = widget.scrim;
    _currentMatchIndex = widget.initialMatchIndex;
    _currentMatchId = _generateMatchId(_currentMatchIndex + 1);
    
    // Initialiser les controllers pour chaque joueur (5 stats chacun: K/D/A/CS/Gold)
    for (int i = 0; i < 5; i++) {
      myTeamControllers.add([
        TextEditingController(), // kills
        TextEditingController(), // deaths  
        TextEditingController(), // assists
        TextEditingController(), // cs
        TextEditingController(), // gold
      ]);
      enemyTeamControllers.add([
        TextEditingController(), // kills
        TextEditingController(), // deaths
        TextEditingController(), // assists  
        TextEditingController(), // cs
        TextEditingController(), // gold
      ]);
    }
    
    // Initialiser les controllers des objectifs
    final objectives = ['Tours', 'Dragons', 'Baron', 'Herald', 'Grubs', 'Nexus'];
    for (final obj in objectives) {
      objectiveControllers['my_$obj'] = TextEditingController();
      objectiveControllers['enemy_$obj'] = TextEditingController();
    }
    
    _loadGameData();
    _loadExistingMatchData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    
    // Nettoyer tous les controllers
    for (final playerControllers in myTeamControllers) {
      for (final controller in playerControllers) {
        controller.dispose();
      }
    }
    for (final playerControllers in enemyTeamControllers) {
      for (final controller in playerControllers) {
        controller.dispose();
      }
    }
    for (final controller in objectiveControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
  
  void _loadGameData() {
    final playersProvider = context.read<PlayersProvider>();
    availablePlayers = playersProvider.players;
    availableChampions = Champions.all;
  }
  
  /// Génère un ID unique pour un match basé sur le scrim ID et le numéro de match
  String _generateMatchId(int matchNumber) {
    return '${widget.scrim.id}_match_$matchNumber';
  }
  
  /// Initialise un match avec des données vides
  void _initializeEmptyMatch() {
    print('🆕 Initialisation d\'un match vide');
    setState(() {
      // Reset complet des données joueurs
      myTeamData = List.generate(5, (_) => MatchPlayerData());
      enemyTeamData = List.generate(5, (_) => MatchPlayerData());
      
      // Reset des autres données
      isVictory = null;
      matchDuration = const Duration(minutes: 30);
      
      // Reset des objectifs
      myTeamTurrets = 0;
      enemyTeamTurrets = 0;
      myTeamDragons = 0;
      enemyTeamDragons = 0;
      myTeamBarons = 0;
      enemyTeamBarons = 0;
      myTeamHeralds = 0;
      enemyTeamHeralds = 0;
      myTeamGroms = 0;
      enemyTeamGroms = 0;
      myTeamNexusTurrets = false;
      enemyTeamNexusTurrets = false;
      
      // Reset des bans
      myTeamBans = List.filled(5, null);
      enemyTeamBans = List.filled(5, null);
      
      _calculateTeamStats();
    });
  }
  
  void _loadExistingMatchData() {
    final matchNumber = _currentMatchIndex + 1;
    print('🔍 DEBUT: Chargement du match $matchNumber (index: $_currentMatchIndex)');
    print('📊 Scrim contient ${_currentScrim.matches.length} matchs');
    
    // Debug: lister tous les matchs
    for (int i = 0; i < _currentScrim.matches.length; i++) {
      final match = _currentScrim.matches[i];
      final firstPlayerKills = match.myTeamPlayers.isNotEmpty ? match.myTeamPlayers[0].kills : null;
      print('   Match ${match.matchNumber}: $firstPlayerKills kills');
    }
    
    final existingMatch = _currentScrim.getMatch(matchNumber);
    
    if (existingMatch != null) {
      final firstPlayerKills = existingMatch.myTeamPlayers.isNotEmpty ? existingMatch.myTeamPlayers[0].kills : null;
      print('📥 TROUVE: Match $matchNumber dans le JSON');
      print('💡 Premier joueur du match: $firstPlayerKills kills');
      
      setState(() {
        // RESET COMPLET avant de charger
        myTeamData = List.generate(5, (_) => MatchPlayerData());
        enemyTeamData = List.generate(5, (_) => MatchPlayerData());
        
        // Charger les données de base
        matchDuration = existingMatch.matchDuration ?? const Duration(minutes: 30);
        isVictory = existingMatch.isVictory;
        
        // Charger joueurs alliés
        for (int i = 0; i < 5; i++) {
          if (i < existingMatch.myTeamPlayers.length) {
            final player = existingMatch.myTeamPlayers[i];
            myTeamData[i].playerId = player.playerId;
            myTeamData[i].champion = player.championId.isNotEmpty ? Champions.getById(player.championId) : null;
            myTeamData[i].kills = player.kills;
            myTeamData[i].deaths = player.deaths;
            myTeamData[i].assists = player.assists;
            myTeamData[i].cs = player.cs;
            myTeamData[i].gold = player.gold;
            myTeamData[i].damage = player.damage;
            if (player.playerId == null) {
              myTeamData[i].pseudoName = player.pseudo;
            }
            print('   👤 Joueur ${i+1}: ${player.kills} kills chargés');
          }
        }
        
        // Charger joueurs ennemis
        for (int i = 0; i < 5; i++) {
          if (i < existingMatch.enemyPlayers.length) {
            final player = existingMatch.enemyPlayers[i];
            enemyTeamData[i].champion = player.championId.isNotEmpty ? Champions.getById(player.championId) : null;
            enemyTeamData[i].kills = player.kills;
            enemyTeamData[i].deaths = player.deaths;
            enemyTeamData[i].assists = player.assists;
            enemyTeamData[i].cs = player.cs;
            enemyTeamData[i].gold = player.gold;
            enemyTeamData[i].damage = player.damage;
            enemyTeamData[i].pseudoName = player.pseudo;
          }
        }
        
        // Charger objectifs et bannissements depuis le JSON
        myTeamTurrets = existingMatch.myTeamTurrets ?? 0;
        enemyTeamTurrets = existingMatch.enemyTeamTurrets ?? 0;
        myTeamDragons = existingMatch.myTeamDragons ?? 0;
        enemyTeamDragons = existingMatch.enemyTeamDragons ?? 0;
        myTeamBarons = existingMatch.myTeamBarons ?? 0;
        enemyTeamBarons = existingMatch.enemyTeamBarons ?? 0;
        myTeamHeralds = existingMatch.myTeamHeralds ?? 0;
        enemyTeamHeralds = existingMatch.enemyTeamHeralds ?? 0;
        myTeamGroms = existingMatch.myTeamGroms ?? 0;
        enemyTeamGroms = existingMatch.enemyTeamGroms ?? 0;
        myTeamNexusTurrets = existingMatch.myTeamNexusTurrets ?? false;
        enemyTeamNexusTurrets = existingMatch.enemyTeamNexusTurrets ?? false;
        
        // Charger bannissements
        myTeamBans = existingMatch.myTeamBans.map((banId) => 
          banId != null ? Champions.getById(banId) : null
        ).toList();
        enemyTeamBans = existingMatch.enemyTeamBans.map((banId) => 
          banId != null ? Champions.getById(banId) : null
        ).toList();
      });
      
      // Calculer les stats APRÈS le setState
      _calculateTeamStats();
      
      // FORCE un rebuild complet de l'interface après chargement
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {
            // Rebuild forcé pour mettre à jour tous les TextFields
          });
        }
      });
      
      // Mettre à jour TOUS les controllers avec les nouvelles données
      _updateAllControllers();
      
      print('✅ FIN: Match $matchNumber chargé');
    } else {
      print('⚠️ ABSENT: Match $matchNumber introuvable - initialisation vide');
      _initializeEmptyMatch();
    }
  }
  
  void _updateAllControllers() {
    // Mettre à jour les controllers des joueurs alliés
    for (int i = 0; i < 5; i++) {
      if (i < myTeamData.length) {
        final player = myTeamData[i];
        myTeamControllers[i][0].text = player.kills?.toString() ?? '';
        myTeamControllers[i][1].text = player.deaths?.toString() ?? '';
        myTeamControllers[i][2].text = player.assists?.toString() ?? '';
        myTeamControllers[i][3].text = player.cs?.toString() ?? '';
        myTeamControllers[i][4].text = player.gold?.toString() ?? '';
      }
    }
    
    // Mettre à jour les controllers des joueurs ennemis
    for (int i = 0; i < 5; i++) {
      if (i < enemyTeamData.length) {
        final player = enemyTeamData[i];
        enemyTeamControllers[i][0].text = player.kills?.toString() ?? '';
        enemyTeamControllers[i][1].text = player.deaths?.toString() ?? '';
        enemyTeamControllers[i][2].text = player.assists?.toString() ?? '';
        enemyTeamControllers[i][3].text = player.cs?.toString() ?? '';
        enemyTeamControllers[i][4].text = player.gold?.toString() ?? '';
      }
    }
    
    // Mettre à jour les controllers des objectifs
    objectiveControllers['my_Tours']?.text = myTeamTurrets.toString();
    objectiveControllers['enemy_Tours']?.text = enemyTeamTurrets.toString();
    objectiveControllers['my_Dragons']?.text = myTeamDragons.toString();
    objectiveControllers['enemy_Dragons']?.text = enemyTeamDragons.toString();
    objectiveControllers['my_Baron']?.text = myTeamBarons.toString();
    objectiveControllers['enemy_Baron']?.text = enemyTeamBarons.toString();
    objectiveControllers['my_Herald']?.text = myTeamHeralds.toString();
    objectiveControllers['enemy_Herald']?.text = enemyTeamHeralds.toString();
    objectiveControllers['my_Grubs']?.text = myTeamGroms.toString();
    objectiveControllers['enemy_Grubs']?.text = enemyTeamGroms.toString();
    objectiveControllers['my_Nexus']?.text = (myTeamNexusTurrets ? 1 : 0).toString();
    objectiveControllers['enemy_Nexus']?.text = (enemyTeamNexusTurrets ? 1 : 0).toString();
  }
  
  void _calculateTeamStats() {
    // Mon équipe
    myTeamKills = myTeamData.map((p) => p.kills ?? 0).fold(0, (a, b) => a + b);
    myTeamDeaths = myTeamData.map((p) => p.deaths ?? 0).fold(0, (a, b) => a + b);
    myTeamAssists = myTeamData.map((p) => p.assists ?? 0).fold(0, (a, b) => a + b);
    myTeamGold = myTeamData.map((p) => p.gold ?? 0).fold(0, (a, b) => a + b);
    
    // Équipe adverse
    enemyTeamKills = enemyTeamData.map((p) => p.kills ?? 0).fold(0, (a, b) => a + b);
    enemyTeamDeaths = enemyTeamData.map((p) => p.deaths ?? 0).fold(0, (a, b) => a + b);
    enemyTeamAssists = enemyTeamData.map((p) => p.assists ?? 0).fold(0, (a, b) => a + b);
    enemyTeamGold = enemyTeamData.map((p) => p.gold ?? 0).fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1428),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1428),
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Match ${_currentMatchIndex + 1}${widget.readOnly ? ' (Lecture seule)' : ''}'),
              Text(
                '${widget.team.name} vs ${_currentScrim.enemyTeamName}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B2434),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          actions: widget.readOnly ? [
            TextButton.icon(
              onPressed: () {
                // Passer en mode édition
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ScrimMatchDetailsScreen(
                      scrim: widget.scrim,
                      team: widget.team,
                      initialMatchIndex: _currentMatchIndex,
                      readOnly: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit, color: Colors.white, size: 16),
              label: const Text('Modifier', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFC89B3C),
              ),
            ),
            const SizedBox(width: 8),
          ] : null,
          bottom: const PreferredSize(
            preferredSize: Size.zero,
            child: SizedBox.shrink(),
          ),
        ),
      body: SafeArea(
        child: Container(
          color: const Color(0xFF0A1428),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _currentScrim.totalMatches,
              onPageChanged: (index) {
                print('📄 Changement de page vers match ${index + 1}');
                setState(() {
                  _currentMatchIndex = index;
                  _currentMatchId = _generateMatchId(index + 1);
                });
                
                // Charger les données du nouveau match après le changement de page
                Future.delayed(const Duration(milliseconds: 100), () {
                  _loadExistingMatchData();
                });
              },
              itemBuilder: (context, index) {
                return _buildMatchForm(index + 1);
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF1B2434),
        child: Row(
          children: [
            // Progression
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progression: ${_getCompletedMatches()}/${_currentScrim.totalMatches} matchs',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: _getCompletedMatches() / _currentScrim.totalMatches,
                    backgroundColor: Colors.grey.shade700,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3C89E8)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Bouton d'import automatique
            // Boutons selon le mode
            if (!widget.readOnly) ...[
              ElevatedButton.icon(
                onPressed: _importMatchFromRiot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.cloud_download, size: 18),
                label: const Text('Import', style: TextStyle(fontSize: 13)),
              ),
              
              const SizedBox(width: 8),
              
              ElevatedButton.icon(
                onPressed: _importFromScreenshot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.photo_camera, size: 18),
                label: const Text('Screenshot', style: TextStyle(fontSize: 13)),
              ),
              
              const SizedBox(width: 8),
              
              // Boutons de navigation en mode édition
              if (_currentMatchIndex > 0)
                ElevatedButton(
                  onPressed: _previousMatch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF463714),
                    foregroundColor: const Color(0xFFCDBC8A),
                  ),
                  child: const Text('Précédent'),
                ),
              
              if (_currentMatchIndex > 0) const SizedBox(width: 8),
              
              ElevatedButton(
                onPressed: _currentMatchIndex < _currentScrim.totalMatches - 1 ? _nextMatch : _finishScrim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C89E8),
                  foregroundColor: Colors.white,
                ),
                child: Text(_currentMatchIndex < _currentScrim.totalMatches - 1 ? 'Suivant' : 'Terminer'),
              ),
            ] else ...[
              // Navigation simple en mode lecture seule
              if (_currentMatchIndex > 0)
                IconButton(
                  onPressed: () => _navigateToMatch(_currentMatchIndex - 1),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF463714),
                    foregroundColor: const Color(0xFFCDBC8A),
                  ),
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Match précédent',
                ),
              
              Text(
                'Match ${_currentMatchIndex + 1} / ${_currentScrim.totalMatches}',
                style: const TextStyle(color: Colors.white),
              ),
              
              if (_currentMatchIndex < _currentScrim.totalMatches - 1)
                IconButton(
                  onPressed: () => _navigateToMatch(_currentMatchIndex + 1),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF3C89E8),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Match suivant',
                ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMatchForm(int matchNumber) {
    return Container(
      key: Key('match_form_$_currentMatchIndex'), // Force rebuild when match changes
      color: const Color(0xFF0A1428),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du match avec résultat
          _buildMatchHeader(),
          
          const SizedBox(height: 20),
          
          // Section Bans & Objectifs (version simplifiée)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2434),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF3C89E8), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('BANNISSEMENTS +', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    SizedBox(width: 40),
                    Icon(Icons.flag, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('OBJECTIFS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                // Section Bans
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.team.name.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF0596AA), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bannissements:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(5, (index) => _buildBanSelector(myTeamBans, index)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildObjectiveRow(true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_currentScrim.enemyTeamName ?? 'ÉQUIPE ADVERSE').toUpperCase(),
                            style: const TextStyle(color: Color(0xFFC8534A), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bannissements:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: List.generate(5, (index) => _buildBanSelector(enemyTeamBans, index)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildObjectiveRow(false),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Container(
            height: 20,
            color: const Color(0xFF0A1428),
          ),
          
          // Mon équipe
          _buildTeamSection(
            teamName: widget.team.name,
            teamData: myTeamData,
            teamKills: myTeamKills,
            teamDeaths: myTeamDeaths, 
            teamAssists: myTeamAssists,
            teamGold: myTeamGold,
            isMyTeam: true,
          ),
          
          Container(
            height: 30,
            color: const Color(0xFF0A1428),
          ),
          
          // Équipe adverse
          _buildTeamSection(
            teamName: _currentScrim.enemyTeamName ?? 'Équipe adverse',
            teamData: enemyTeamData,
            teamKills: enemyTeamKills,
            teamDeaths: enemyTeamDeaths,
            teamAssists: enemyTeamAssists,
            teamGold: enemyTeamGold,
            isMyTeam: false,
          ),
        ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMatchHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3C89E8), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.sports_esports, color: const Color(0xFF3C89E8), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Résultat du match',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _buildVictorySelector(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Durée du match
          Row(
            children: [
              const Icon(Icons.timer, color: Color(0xFFCDBC8A), size: 20),
              const SizedBox(width: 8),
              const Text('Durée: ', style: TextStyle(color: Colors.white70)),
              _buildDurationSelector(),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildVictorySelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.readOnly ? null : () => setState(() => isVictory = true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isVictory == true ? const Color(0xFF0596AA) : Colors.transparent,
              border: Border.all(
                color: widget.readOnly ? Colors.grey : const Color(0xFF0596AA)
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Victoire', 
              style: TextStyle(
                color: widget.readOnly ? Colors.grey : Colors.white
              )
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: widget.readOnly ? null : () => setState(() => isVictory = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isVictory == false ? const Color(0xFFC8534A) : Colors.transparent,
              border: Border.all(
                color: widget.readOnly ? Colors.grey : const Color(0xFFC8534A)
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Défaite', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDurationSelector() {
    return DropdownButton<int>(
      value: matchDuration.inMinutes,
      dropdownColor: const Color(0xFF1B2434),
      style: const TextStyle(color: Colors.white),
      items: List.generate(61, (index) => index + 10)
          .map((minutes) => DropdownMenuItem(
                value: minutes,
                child: Text('${minutes}min'),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            matchDuration = Duration(minutes: value);
          });
        }
      },
    );
  }

  Widget _buildTeamSection({
    required String teamName,
    required List<MatchPlayerData> teamData,
    required int teamKills,
    required int teamDeaths,
    required int teamAssists,
    required int teamGold,
    required bool isMyTeam,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B2434),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMyTeam ? const Color(0xFF0596AA) : const Color(0xFFC8534A),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête d'équipe avec stats globales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isMyTeam ? const Color(0xFF0596AA).withOpacity(0.1) : const Color(0xFFC8534A).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildTeamStats(teamKills, teamDeaths, teamAssists),
                const SizedBox(width: 20),
                _buildGoldDisplay(teamGold),
              ],
            ),
          ),
          
          // Liste des joueurs
          ...List.generate(5, (index) => 
            _buildPlayerRow(teamData[index], index, isMyTeam)
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamStats(int kills, int deaths, int assists) {
    return Text(
      '$kills / $deaths / $assists',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildGoldDisplay(int gold) {
    return Row(
      children: [
        const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
        const SizedBox(width: 4),
        Text(
          '${gold}k',
          style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPlayerRow(MatchPlayerData playerData, int index, bool isMyTeam) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Niveau et avatar champion
          _buildChampionSelector(playerData),
          
          const SizedBox(width: 12),
          
          // Nom du joueur
          Expanded(
            flex: 2,
            child: _buildPlayerSelector(playerData, isMyTeam),
          ),
          
          const SizedBox(width: 12),
          
          // Sorts d'invocateur
          _buildSummonerSpellsSelector(playerData),
          
          const SizedBox(width: 12),
          
          // Build (objets)
          _buildItemsSelector(playerData),
          
          const SizedBox(width: 12),
          
          // KDA
          _buildKDAInput(playerData, index, isMyTeam),
          
          const SizedBox(width: 12),
          
          // CS
          _buildCSInput(playerData, index, isMyTeam),
          
          const SizedBox(width: 12),
          
          // Damage
          _buildDamageInput(playerData),
          
          const SizedBox(width: 12),
          
          // Gold
          _buildGoldInput(playerData, index, isMyTeam),
        ],
      ),
    );
  }
  
  Widget _buildPlayerSelector(MatchPlayerData playerData, bool isMyTeam) {
    if (!isMyTeam) {
      // Pour les ennemis : champ texte libre
      return SizedBox(
        width: 140,
        child: TextFormField(
          initialValue: playerData.pseudoName,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            hintText: 'Pseudo ennemi',
            hintStyle: TextStyle(color: Colors.grey),
          ),
          onChanged: (value) {
            setState(() {
              playerData.pseudoName = value.isEmpty ? null : value;
            });
          },
        ),
      );
    }
    
    // Pour mon équipe : dropdown avec joueurs
    final players = availablePlayers.where((p) => widget.team.playerIds.contains(p.id)).toList();
    
    return DropdownButtonFormField<String>(
        initialValue: playerData.playerId,
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          hintText: 'Joueur',
        ),
        dropdownColor: const Color(0xFF1B2434),
        style: const TextStyle(color: Colors.white, fontSize: 12),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Sélectionner...', style: TextStyle(color: Colors.grey)),
          ),
          ...players.map((player) => DropdownMenuItem(
            value: player.id,
            child: Text(player.inGameId, style: const TextStyle(color: Colors.white)),
          )),
        ],
        onChanged: (value) {
          setState(() {
            playerData.playerId = value;
            _calculateTeamStats();
          });
        },
      );
  }
  
  Widget _buildChampionSelector(MatchPlayerData playerData) {
    return GestureDetector(
      onTap: () => _showChampionSelector(playerData),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF463714),
          border: Border.all(color: const Color(0xFFCDBC8A), width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: playerData.champion != null
            ? Center(
                child: Text(
                  playerData.champion!.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : const Icon(Icons.person, color: Colors.grey),
      ),
    );
  }
  
  Widget _buildSummonerSpellsSelector(MatchPlayerData playerData) {
    return Row(
      children: List.generate(2, (index) =>
        GestureDetector(
          onTap: () => _showSummonerSpellSelector(playerData, index),
          child: Container(
            width: 24,
            height: 24,
            margin: EdgeInsets.only(right: index == 0 ? 4 : 0),
            decoration: BoxDecoration(
              color: const Color(0xFF463714),
              border: Border.all(color: const Color(0xFFCDBC8A)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Text(
                playerData.summonerSpells[index].emoji,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildItemsSelector(MatchPlayerData playerData) {
    return Row(
      children: List.generate(6, (index) =>
        GestureDetector(
          onTap: () => _showItemSelector(playerData, index),
          child: Container(
            width: 24,
            height: 24,
            margin: EdgeInsets.only(right: index < 5 ? 2 : 0),
            decoration: BoxDecoration(
              color: const Color(0xFF463714),
              border: Border.all(color: const Color(0xFFCDBC8A)),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Text(
                playerData.items[index].emoji,
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildKDAInput(MatchPlayerData playerData, int playerIndex, bool isMyTeam) {
    return Row(
      children: [
        // Kills
        SizedBox(
          width: 40,
          child: TextFormField(
            controller: isMyTeam ? myTeamControllers[playerIndex][0] : enemyTeamControllers[playerIndex][0],
            enabled: !widget.readOnly,
            style: TextStyle(
              color: widget.readOnly ? Colors.grey : Colors.white, 
              fontSize: 12
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'K',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.readOnly ? null : (value) {
              setState(() {
                playerData.kills = int.tryParse(value);
                _calculateTeamStats();
              });
            },
          ),
        ),
        const SizedBox(width: 4),
        const Text('/', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 4),
        // Deaths
        SizedBox(
          width: 40,
          child: TextFormField(
            controller: isMyTeam ? myTeamControllers[playerIndex][1] : enemyTeamControllers[playerIndex][1],
            enabled: !widget.readOnly,
            style: TextStyle(
              color: widget.readOnly ? Colors.grey : Colors.white, 
              fontSize: 12
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'D',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.readOnly ? null : (value) {
              setState(() {
                playerData.deaths = int.tryParse(value);
                _calculateTeamStats();
              });
            },
          ),
        ),
        const SizedBox(width: 4),
        const Text('/', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 4),
        // Assists
        SizedBox(
          width: 40,
          child: TextFormField(
            controller: isMyTeam ? myTeamControllers[playerIndex][2] : enemyTeamControllers[playerIndex][2],
            enabled: !widget.readOnly,
            style: TextStyle(
              color: widget.readOnly ? Colors.grey : Colors.white, 
              fontSize: 12
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'A',
              hintStyle: TextStyle(color: Colors.grey),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: widget.readOnly ? null : (value) {
              setState(() {
                playerData.assists = int.tryParse(value);
                _calculateTeamStats();
              });
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildCSInput(MatchPlayerData playerData, int playerIndex, bool isMyTeam) {
    return SizedBox(
      width: 60,
      child: TextFormField(
        controller: isMyTeam ? myTeamControllers[playerIndex][3] : enemyTeamControllers[playerIndex][3],
        enabled: !widget.readOnly,
        style: TextStyle(
          color: widget.readOnly ? Colors.grey : Colors.white, 
          fontSize: 12
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          hintText: 'CS',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.readOnly ? null : (value) {
          setState(() {
            playerData.cs = int.tryParse(value);
            _calculateTeamStats();
          });
        },
      ),
    );
  }
  
  Widget _buildDamageInput(MatchPlayerData playerData) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        initialValue: playerData.damage?.toString(),
        enabled: !widget.readOnly,
        style: TextStyle(
          color: widget.readOnly ? Colors.grey : Colors.white, 
          fontSize: 12
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          hintText: 'Dégâts',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.readOnly ? null : (value) {
          setState(() {
            playerData.damage = int.tryParse(value);
          });
        },
      ),
    );
  }
  
  Widget _buildGoldInput(MatchPlayerData playerData, int playerIndex, bool isMyTeam) {
    return SizedBox(
      width: 70,
      child: TextFormField(
        controller: isMyTeam ? myTeamControllers[playerIndex][4] : enemyTeamControllers[playerIndex][4],
        enabled: !widget.readOnly,
        style: TextStyle(
          color: widget.readOnly ? Colors.grey : Colors.white, 
          fontSize: 12
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: OutlineInputBorder(),
          hintText: 'Gold',
          hintStyle: TextStyle(color: Colors.grey),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: widget.readOnly ? null : (value) {
          setState(() {
            playerData.gold = int.tryParse(value);
            _calculateTeamStats();
          });
        },
      ),
    );
  }

  void _showChampionSelector(MatchPlayerData playerData) async {
    final selected = await showDialog<Champion>(
      context: context,
      builder: (context) => _ChampionSelectorDialog(champions: availableChampions),
    );
    
    if (selected != null) {
      setState(() {
        playerData.champion = selected;
      });
    }
  }
  
  void _showSummonerSpellSelector(MatchPlayerData playerData, int index) async {
    final selected = await showDialog<SummonerSpell>(
      context: context,
      builder: (context) => _SummonerSpellSelectorDialog(),
    );
    
    if (selected != null) {
      setState(() {
        playerData.summonerSpells[index] = selected;
      });
    }
  }
  
  void _showItemSelector(MatchPlayerData playerData, int index) async {
    final selected = await showDialog<Item>(
      context: context,
      builder: (context) => _ItemSelectorDialog(),
    );
    
    if (selected != null) {
      setState(() {
        playerData.items[index] = selected;
      });
    }
  }

  Future<void> _previousMatch() async {
    if (_currentMatchIndex > 0) {
      // Sauvegarder le match actuel avec feedback
      await _saveCurrentMatch();
      
      // Afficher un feedback rapide
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💾 Match ${_currentMatchIndex + 1} sauvegardé !'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      
      // Calculer le précédent index AVANT la navigation
      final previousMatchIndex = _currentMatchIndex - 1;
      
      // Naviguer vers le match précédent
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Le chargement des données sera fait automatiquement par onPageChanged
      print('🔄 Navigation vers match ${previousMatchIndex + 1} - Chargement des données...');
    }
  }

  Future<void> _nextMatch() async {
    if (_currentMatchIndex < _currentScrim.totalMatches - 1) {
      // Sauvegarder le match actuel avant de passer au suivant
      await _saveCurrentMatch();
      
      // Afficher un feedback rapide
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💾 Match ${_currentMatchIndex + 1} sauvegardé !'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1500),
        ),
      );
      
      // Calculer le prochain index AVANT la navigation
      final nextMatchIndex = _currentMatchIndex + 1;
      
      // Naviguer vers le match suivant
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      
      // Le chargement des données sera fait automatiquement par onPageChanged
      print('🔄 Navigation vers match ${nextMatchIndex + 1} - Chargement des données...');
    }
  }

  /// Navigation directe vers un match spécifique (mode lecture seule)
  void _navigateToMatch(int targetIndex) {
    if (targetIndex >= 0 && targetIndex < _currentScrim.totalMatches) {
      // Naviguer vers le match cible
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScrimMatchDetailsScreen(
            scrim: widget.scrim,
            team: widget.team,
            initialMatchIndex: targetIndex,
            readOnly: true,
          ),
        ),
      );
    }
  }

  // Méthode _buildBansSection() supprimée - version simplifiée utilisée dans le build
  
  /// Import automatique d'un match via l'API Riot
  Future<void> _importMatchFromRiot() async {
    // Dialog pour saisir le code du match
    final matchId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer un match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le code du match :'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seuls les matchs officiels sont importables (Classé, Normal, ARAM). Les parties personnalisées ne sont pas disponibles.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Code du match',
                hintText: 'Ex: 7602580136 ou EUW1_7602580136',
                border: OutlineInputBorder(),
                helperText: 'Vous pouvez utiliser juste le code numérique',
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('TEMPLATE_CUSTOM'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('Template vide'),
          ),
          ElevatedButton(
            onPressed: () {
              // Récupérer la valeur du TextField et la retourner
              Navigator.of(context).pop('INPUT_VALUE'); // TODO: récupérer vraie valeur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    
    if (matchId == null || matchId.trim().isEmpty) return;
    
    // Cas spécial : template vide pour parties personnalisées
    if (matchId == 'TEMPLATE_CUSTOM') {
      _createCustomGameTemplate();
      return;
    }
    
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Import des données...'),
            ],
          ),
        ),
      );
      
      // Récupérer les données depuis l'API Riot
      final matchData = await RiotApiService.getMatchData(matchId.trim());
      
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement
      
      if (matchData != null) {
        await _fillMatchWithRiotData(matchData);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Match importé avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _showErrorDialog('Impossible de récupérer les données du match');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Fermer le dialog de chargement si encore ouvert
      _showErrorDialog('Erreur lors de l\'import: $e');
    }
  }
  
  /// Remplit les champs du match avec les données Riot
  Future<void> _fillMatchWithRiotData(RiotMatchData matchData) async {
    final match = matchData.info;
    
    // Déterminer quelle équipe est la nôtre (on prend la première équipe par défaut)
    final team1Participants = match.participants.where((p) => p.teamId == 100).toList();
    final team2Participants = match.participants.where((p) => p.teamId == 200).toList();
    
    final myTeam = team1Participants;
    final enemyTeam = team2Participants;
    
    setState(() {
      // Remplir les données de l'équipe alliée
      for (int i = 0; i < myTeam.length && i < 5; i++) {
        final participant = myTeam[i];
        
        // Trouver le champion correspondant
        Champion? champion;
        try {
          champion = Champions.all.firstWhere(
            (c) => c.name.toLowerCase() == participant.championName.toLowerCase(),
          );
        } catch (e) {
          // Champion non trouvé, on peut créer un placeholder ou ignorer
          continue;
        }
        
        myTeamData[i].champion = champion;
        myTeamData[i].kills = participant.kills;
        myTeamData[i].deaths = participant.deaths;
        myTeamData[i].assists = participant.assists;
        myTeamData[i].cs = participant.totalCs;
        myTeamData[i].gold = participant.goldEarned;
        myTeamData[i].damage = participant.totalDamageDealtToChampions;
        
        // Si pas de joueur assigné, utiliser le nom du summoner
        if (myTeamData[i].playerId == null) {
          myTeamData[i].pseudoName = participant.summonerName;
        }
      }
      
      // Remplir les données de l'équipe ennemie
      for (int i = 0; i < enemyTeam.length && i < 5; i++) {
        final participant = enemyTeam[i];
        
        // Trouver le champion correspondant
        Champion? champion;
        try {
          champion = Champions.all.firstWhere(
            (c) => c.name.toLowerCase() == participant.championName.toLowerCase(),
          );
        } catch (e) {
          continue;
        }
        
        enemyTeamData[i].champion = champion;
        enemyTeamData[i].kills = participant.kills;
        enemyTeamData[i].deaths = participant.deaths;
        enemyTeamData[i].assists = participant.assists;
        enemyTeamData[i].cs = participant.totalCs;
        enemyTeamData[i].gold = participant.goldEarned;
        enemyTeamData[i].damage = participant.totalDamageDealtToChampions;
        enemyTeamData[i].pseudoName = participant.summonerName;
      }
      
      // Mettre à jour les statistiques d'équipe
      final myTeamStats = match.teams.firstWhere((t) => t.teamId == 100);
      final enemyTeamStats = match.teams.firstWhere((t) => t.teamId == 200);
      
      myTeamTurrets = myTeamStats.getObjectiveKills('tower');
      enemyTeamTurrets = enemyTeamStats.getObjectiveKills('tower');
      myTeamDragons = myTeamStats.getObjectiveKills('dragon');
      enemyTeamDragons = enemyTeamStats.getObjectiveKills('dragon');
      myTeamBarons = myTeamStats.getObjectiveKills('baron');
      enemyTeamBarons = enemyTeamStats.getObjectiveKills('baron');
      myTeamHeralds = myTeamStats.getObjectiveKills('riftHerald');
      enemyTeamHeralds = enemyTeamStats.getObjectiveKills('riftHerald');
      
      // Déterminer le résultat
      final myTeamWon = myTeam.first.win;
      isVictory = myTeamWon;
      
      // Durée du match
      matchDuration = Duration(seconds: match.gameDuration);
      
      // Recalculer les stats
      _calculateTeamStats();
    });
  }
  
  /// Sauvegarde le match actuel dans le scrim et le provider (même avec données incomplètes)
  Future<void> _saveCurrentMatch() async {
    print('🔄 Sauvegarde du match ${_currentMatchIndex + 1} (ID: $_currentMatchId)');
    
    // Créer les joueurs alliés (TOUS, même sans champion)
    final myTeamPlayers = myTeamData.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      
      return TeamPlayer(
        playerId: player.playerId,
        pseudo: player.playerId != null 
            ? availablePlayers.firstWhere((p) => p.id == player.playerId, orElse: () => Player(
                id: '', 
                pseudo: 'Inconnu', 
                inGameId: 'Joueur ${index + 1}', 
                game: Game.leagueOfLegends, 
                role: 'Mid',
                createdAt: DateTime.now(),
              )).inGameId
            : player.pseudoName ?? 'Joueur ${index + 1}',
        role: _getRoleFromChampion(player.champion) ?? _getDefaultRole(index),
        championId: player.champion?.id ?? '',
        kills: player.kills,
        deaths: player.deaths,
        assists: player.assists,
        cs: player.cs,
        gold: player.gold,
        damage: player.damage,
      );
    }).toList();
    
    // Créer les joueurs ennemis (TOUS, même sans champion)
    final enemyPlayers = enemyTeamData.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;
      
      return EnemyPlayer(
        pseudo: player.pseudoName ?? 'Ennemi ${index + 1}',
        role: _getRoleFromChampion(player.champion) ?? _getDefaultRole(index),
        championId: player.champion?.id ?? '',
        kills: player.kills,
        deaths: player.deaths,
        assists: player.assists,
        cs: player.cs,
        gold: player.gold,
        damage: player.damage,
      );
    }).toList();
    
    // Créer le match avec TOUTES les données (même nulles/incomplètes)
    final currentMatch = ScrimMatch(
      matchNumber: _currentMatchIndex + 1,
      myTeamPlayers: myTeamPlayers,
      enemyPlayers: enemyPlayers,
      myTeamScore: myTeamKills,
      enemyTeamScore: enemyTeamKills,
      isVictory: isVictory,
      matchDuration: matchDuration,
      notes: 'Match ${_currentMatchIndex + 1} - ID: $_currentMatchId',
      // Sauvegarder bannissements et objectifs
      myTeamBans: List<String?>.from(myTeamBans.map((c) => c?.id)),
      enemyTeamBans: List<String?>.from(enemyTeamBans.map((c) => c?.id)),
      myTeamTurrets: myTeamTurrets,
      enemyTeamTurrets: enemyTeamTurrets,
      myTeamDragons: myTeamDragons,
      enemyTeamDragons: enemyTeamDragons,
      myTeamBarons: myTeamBarons,
      enemyTeamBarons: enemyTeamBarons,
      myTeamHeralds: myTeamHeralds,
      enemyTeamHeralds: enemyTeamHeralds,
      myTeamGroms: myTeamGroms,
      enemyTeamGroms: enemyTeamGroms,
      myTeamNexusTurrets: myTeamNexusTurrets,
      enemyTeamNexusTurrets: enemyTeamNexusTurrets,
    );

    // Mettre à jour le match existant dans le scrim (modification en place)
    final updatedMatches = List<ScrimMatch>.from(_currentScrim.matches);
    final matchIndex = _currentMatchIndex;
    
    // S'assurer que l'index est valide
    if (matchIndex < updatedMatches.length) {
      updatedMatches[matchIndex] = currentMatch;
    } else {
      // Étendre la liste si nécessaire (ne devrait pas arriver avec la nouvelle logique)
      while (updatedMatches.length <= matchIndex) {
        updatedMatches.add(currentMatch);
      }
      updatedMatches[matchIndex] = currentMatch;
    }
    
    // Recalculer les victoires
    int newMyWins = 0;
    int newEnemyWins = 0;
    for (final m in updatedMatches) {
      if (m.isVictory == true) newMyWins++;
      if (m.isVictory == false) newEnemyWins++;
    }
    
    final updatedScrim = _currentScrim.copyWith(
      matches: updatedMatches,
      myTeamWins: newMyWins,
      enemyTeamWins: newEnemyWins,
      playedAt: DateTime.now(),
    );
    
    // Sauvegarder via le provider (persiste dans le JSON)
    try {
      final scrimsProvider = context.read<ScrimsProvider>();
      await scrimsProvider.updateScrim(updatedScrim);
      
      setState(() {
        _currentScrim = updatedScrim;
      });
      
      print('✅ Match ${_currentMatchIndex + 1} sauvegardé avec succès dans le JSON');
      print('   - Mon équipe: ${myTeamPlayers.length} joueurs');
      print('   - Équipe adverse: ${enemyPlayers.length} joueurs');
      print('   - Résultat: ${isVictory == null ? "Non défini" : (isVictory! ? "Victoire" : "Défaite")}');
      print('   - Durée: ${matchDuration.inMinutes} min');
      print('   - Objectifs: T$myTeamTurrets-$enemyTeamTurrets | D$myTeamDragons-$enemyTeamDragons | B$myTeamBarons-$enemyTeamBarons');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Import des données depuis une screenshot
  Future<void> _importFromScreenshot() async {
    try {
      // Afficher le choix entre caméra et fichier
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Importer une screenshot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisissez la source de l\'image :'),
              const SizedBox(height: 16),
              
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF3C89E8)),
                title: const Text('Fichier'),
                subtitle: const Text('Choisir une image depuis votre ordinateur'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3C89E8)),
                title: const Text('Caméra'),
                subtitle: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
      
      if (source == null) return;
      
      File? imageFile;
      
      if (source == ImageSource.gallery) {
        // Utiliser file_picker pour plus de flexibilité
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'bmp'],
        );
        
        if (result != null && result.files.single.path != null) {
          imageFile = File(result.files.single.path!);
        }
      } else {
        // Utiliser image_picker pour la caméra
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(source: source);
        
        if (pickedFile != null) {
          imageFile = File(pickedFile.path);
        }
      }
      
      if (imageFile == null) return;
      
      if (!mounted) return;
      
      // Naviguer vers l'écran de prévisualisation interactive
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => InteractiveOCRPreviewScreen(
            screenshotFile: imageFile!,
            onConfirm: (myTeam, enemyTeam) {
              print('🎯 Données OCR reçues des zones personnalisées:');
              print('   Mon équipe: ${myTeam.length} joueurs');
              print('   Équipe adverse: ${enemyTeam.length} joueurs');
              _applyScreenshotData(myTeam, enemyTeam);
            },
          ),
        ),
      );
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'import: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Applique les données extraites de la screenshot au match actuel
  void _applyScreenshotData(List<Map<String, dynamic>> myTeam, List<Map<String, dynamic>> enemyTeam) {
    setState(() {
      // Appliquer les données de mon équipe
      for (int i = 0; i < myTeam.length && i < myTeamData.length; i++) {
        final extractedData = myTeam[i];
        
        // Copier les stats extraites
        myTeamData[i].kills = extractedData['kills'] as int? ?? 0;
        myTeamData[i].deaths = extractedData['deaths'] as int? ?? 0;
        myTeamData[i].assists = extractedData['assists'] as int? ?? 0;
        myTeamData[i].cs = extractedData['cs'] as int? ?? 0;
        myTeamData[i].gold = extractedData['gold'] as int? ?? 0;
        
        // Conserver les autres données existantes (joueur, champion)
      }
      
      // Appliquer les données de l'équipe adverse
      for (int i = 0; i < enemyTeam.length && i < enemyTeamData.length; i++) {
        final extractedData = enemyTeam[i];
        
        // Copier les stats extraites
        enemyTeamData[i].kills = extractedData['kills'] as int? ?? 0;
        enemyTeamData[i].deaths = extractedData['deaths'] as int? ?? 0;
        enemyTeamData[i].assists = extractedData['assists'] as int? ?? 0;
        enemyTeamData[i].cs = extractedData['cs'] as int? ?? 0;
        enemyTeamData[i].gold = extractedData['gold'] as int? ?? 0;
      }
      
      // Recalculer les statistiques d'équipe
      _calculateTeamStats();
      
      // Mettre à jour tous les controllers
      _updateAllControllers();
    });
    
    // Afficher une confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Screenshot importée ! ${myTeam.length + enemyTeam.length} joueurs mis à jour',
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    print('📸 Screenshot importée:');
    print('  - Mon équipe: ${myTeam.length} joueurs');
    print('  - Équipe adverse: ${enemyTeam.length} joueurs');
  }
  
  /// Utilitaire pour déterminer le rôle d'après le champion (approximatif)
  String? _getRoleFromChampion(Champion? champion) {
    if (champion == null) return null;
    return champion.role;
  }
  
  /// Rôle par défaut basé sur la position dans l'équipe (index)
  String _getDefaultRole(int index) {
    switch (index) {
      case 0: return 'Top';
      case 1: return 'Jungle';
      case 2: return 'Mid';
      case 3: return 'ADC';
      case 4: return 'Support';
      default: return 'Mid';
    }
  }

  /// Crée un template vide pour les parties personnalisées
  void _createCustomGameTemplate() {
    setState(() {
      // Template avec des valeurs par défaut pour une partie personnalisée
      for (int i = 0; i < 5; i++) {
        myTeamData[i] = MatchPlayerData()
          ..kills = 0
          ..deaths = 0
          ..assists = 0
          ..cs = 0
          ..gold = 0
          ..damage = 0;
        
        enemyTeamData[i] = MatchPlayerData()
          ..kills = 0
          ..deaths = 0
          ..assists = 0
          ..cs = 0
          ..gold = 0
          ..damage = 0
          ..pseudoName = 'Ennemi ${i + 1}';
      }
      
      // Objectifs à zéro
      myTeamTurrets = 0;
      enemyTeamTurrets = 0;
      myTeamDragons = 0;
      enemyTeamDragons = 0;
      myTeamBarons = 0;
      enemyTeamBarons = 0;
      myTeamHeralds = 0;
      enemyTeamHeralds = 0;
      
      // Durée par défaut d'une partie custom (30 min)
      matchDuration = const Duration(minutes: 30);
      
      // Résultat non défini
      isVictory = null;
      
      // Recalculer les stats
      _calculateTeamStats();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📝 Template vide créé ! Vous pouvez maintenant remplir les champs manuellement.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur d\'import'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _finishScrim() async {
    // Sauvegarder le match final
    await _saveCurrentMatch();
    
    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 Scrim terminé ! Tous les matchs sauvegardés (${_currentScrim.matches.length}/${_currentScrim.totalMatches})'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Retourner à l'écran précédent avec confirmation de sauvegarde
    Navigator.of(context).pop(true);
  }
  
  int _getCompletedMatches() {
    return _currentScrim.matches.length;
  }

  Widget _buildBanSelector(List<Champion?> bans, int index) {
    return GestureDetector(
      onTap: () async {
        final selected = await showDialog<Champion>(
          context: context,
          builder: (context) => _ChampionSelectorDialog(champions: availableChampions),
        );
        if (selected != null) {
          setState(() {
            bans[index] = selected;
          });
        }
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bans[index] != null ? const Color(0xFF2A3F5F) : const Color(0xFF1A1A1A),
          border: Border.all(
            color: bans[index] != null ? const Color(0xFFCDBC8A) : Colors.grey.shade700, 
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: bans[index] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: bans[index]!.imageUrl != null
                    ? Image.asset(
                        'assets/champ_icons/${bans[index]!.imageUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF8B4513),
                            child: Center(
                              child: Text(
                                bans[index]!.name.substring(0, 2).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: const Color(0xFF8B4513),
                        child: Center(
                          child: Text(
                            bans[index]!.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
              )
            : const Icon(Icons.add, color: Colors.grey, size: 20),
      ),
    );
  }

  Widget _buildObjectiveRow(bool isMyTeam) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildObjectiveIcon('Tours', isMyTeam ? myTeamTurrets : enemyTeamTurrets, (val) {
                setState(() {
                  if (isMyTeam) {
                    myTeamTurrets = val ?? 0;
                  } else {
                    enemyTeamTurrets = val ?? 0;
                  }
                });
              }, isMyTeam),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildObjectiveIcon('Dragons', isMyTeam ? myTeamDragons : enemyTeamDragons, (val) {
                setState(() {
                  if (isMyTeam) {
                    myTeamDragons = val ?? 0;
                  } else {
                    enemyTeamDragons = val ?? 0;
                  }
                });
              }, isMyTeam),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildObjectiveIcon('Baron', isMyTeam ? myTeamBarons : enemyTeamBarons, (val) {
                setState(() {
                  if (isMyTeam) {
                    myTeamBarons = val ?? 0;
                  } else {
                    enemyTeamBarons = val ?? 0;
                  }
                });
              }, isMyTeam),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _buildObjectiveIcon('Herald', isMyTeam ? myTeamHeralds : enemyTeamHeralds, (val) {
                setState(() {
                  if (isMyTeam) {
                    myTeamHeralds = val ?? 0;
                  } else {
                    enemyTeamHeralds = val ?? 0;
                  }
                });
              }, isMyTeam),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildObjectiveIcon('Grubs', isMyTeam ? myTeamGroms : enemyTeamGroms, (val) {
                setState(() {
                  if (isMyTeam) {
                    myTeamGroms = val ?? 0;
                  } else {
                    enemyTeamGroms = val ?? 0;
                  }
                });
              }, isMyTeam),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildObjectiveIcon('Nexus', isMyTeam ? (myTeamNexusTurrets ? 1 : 0) : (enemyTeamNexusTurrets ? 1 : 0), (val) {
                setState(() {
                  if (isMyTeam) {
                    myTeamNexusTurrets = (val ?? 0) > 0;
                  } else {
                    enemyTeamNexusTurrets = (val ?? 0) > 0;
                  }
                });
              }, isMyTeam),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObjectiveIcon(String label, int count, Function(int?) onChanged, bool isMyTeam) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3F5F),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF3C89E8), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 30,
            height: 24,
            child: TextFormField(
              controller: objectiveControllers['${isMyTeam ? 'my' : 'enemy'}_$label'],
              enabled: !widget.readOnly,
              style: TextStyle(
                color: widget.readOnly ? Colors.grey : Colors.white, 
                fontSize: 10, 
                fontWeight: FontWeight.bold
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(4),
                fillColor: Color(0xFF1B2434),
                filled: true,
              ),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: widget.readOnly ? null : (val) => onChanged(int.tryParse(val)),
            ),
          ),
        ],
      ),
    );
  }
}

// Dialogues de sélection
class _ChampionSelectorDialog extends StatefulWidget {
  final List<Champion> champions;
  
  const _ChampionSelectorDialog({required this.champions});
  
  @override
  State<_ChampionSelectorDialog> createState() => _ChampionSelectorDialogState();
}

class _ChampionSelectorDialogState extends State<_ChampionSelectorDialog> {
  String searchQuery = '';
  Role? selectedRole;
  
  @override
  Widget build(BuildContext context) {
    final filteredChampions = widget.champions.where((champion) {
      final matchesSearch = champion.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesRole = selectedRole == null || champion.primaryRole == selectedRole;
      return matchesSearch && matchesRole;
    }).toList();
    
    return AlertDialog(
      title: const Text('Sélectionner un champion'),
      backgroundColor: const Color(0xFF1B2434),
      content: SizedBox(
        width: 600,
        height: 650,
        child: Column(
          children: [
            // Barre de recherche
            TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
            
            const SizedBox(height: 8),
            
            // Filtres par rôle
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: Role.values.map((role) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(role.displayName),
                    selected: selectedRole == role,
                    onSelected: (_) => setState(() => selectedRole = selectedRole == role ? null : role),
                  ),
                )).toList(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des champions
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: filteredChampions.length,
                itemBuilder: (context, index) {
                  final champion = filteredChampions[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(champion),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF463714),
                        border: Border.all(color: const Color(0xFFCDBC8A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                              child: champion.imageUrl != null
                                  ? Image.asset(
                                      'assets/champ_icons/${champion.imageUrl}',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFF2A3F5F),
                                          child: Center(
                                            child: Text(
                                              champion.name.substring(0, 2).toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Container(
                                      color: const Color(0xFF2A3F5F),
                                      child: Center(
                                        child: Text(
                                          champion.name.substring(0, 2).toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF463714),
                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(7)),
                              ),
                              child: Text(
                                champion.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _SummonerSpellSelectorDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner un sort'),
      backgroundColor: const Color(0xFF1B2434),
      content: SizedBox(
        width: 300,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: SummonerSpell.values.length,
          itemBuilder: (context, index) {
            final spell = SummonerSpell.values[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).pop(spell),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF463714),
                  border: Border.all(color: const Color(0xFFCDBC8A)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(spell.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      spell.name,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _ItemSelectorDialog extends StatefulWidget {
  @override
  State<_ItemSelectorDialog> createState() => _ItemSelectorDialogState();
}

class _ItemSelectorDialogState extends State<_ItemSelectorDialog> {
  String selectedCategory = 'all';
  
  @override
  Widget build(BuildContext context) {
    List<Item> items = switch (selectedCategory) {
      'boots' => Item.boots,
      'ad' => Item.adItems,
      'ap' => Item.apItems,
      'tank' => Item.tankItems,
      'support' => Item.supportItems,
      _ => Item.allItems,
    };
    
    return AlertDialog(
      title: const Text('Sélectionner un objet'),
      backgroundColor: const Color(0xFF1B2434),
      content: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            // Catégories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Tous'),
                    selected: selectedCategory == 'all',
                    onSelected: (_) => setState(() => selectedCategory = 'all'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Bottes'),
                    selected: selectedCategory == 'boots',
                    onSelected: (_) => setState(() => selectedCategory = 'boots'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('AD'),
                    selected: selectedCategory == 'ad',
                    onSelected: (_) => setState(() => selectedCategory = 'ad'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('AP'),
                    selected: selectedCategory == 'ap',
                    onSelected: (_) => setState(() => selectedCategory = 'ap'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Tank'),
                    selected: selectedCategory == 'tank',
                    onSelected: (_) => setState(() => selectedCategory = 'tank'),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Support'),
                    selected: selectedCategory == 'support',
                    onSelected: (_) => setState(() => selectedCategory = 'support'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des objets
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length + 1, // +1 pour "Aucun objet"
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return GestureDetector(
                      onTap: () => Navigator.of(context).pop(Item.none),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.clear, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              'Aucun',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final item = items[index - 1];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(item),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF463714),
                        border: Border.all(color: const Color(0xFFCDBC8A)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text(
                            item.name,
                            style: const TextStyle(color: Colors.white, fontSize: 8),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}