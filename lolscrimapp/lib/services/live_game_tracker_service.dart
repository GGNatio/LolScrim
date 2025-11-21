import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service qui track une partie en cours via les APIs LCU et in-game
class LiveGameTrackerService extends ChangeNotifier {
  Timer? _pollingTimer;
  LiveGameData? _currentGameData;
  String? _lcuPort;
  String? _lcuPassword;
  String? _currentPhase;
  bool _isTracking = false;
  int _api2999FailCount = 0;

  /// Données actuelles de la partie
  LiveGameData? get currentGameData => _currentGameData;
  
  /// Phase actuelle du gameflow
  String? get currentPhase => _currentPhase;
  
  /// Indique si le service est en train de tracker
  bool get isTracking => _isTracking;

  /// Démarre le tracking avec les credentials LCU
  void startTracking(String port, String password) {
    _lcuPort = port;
    _lcuPassword = password;
    _isTracking = true;
    
    // Poll toutes les 2 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollGameState());
    
    // Premier poll immédiat
    _pollGameState();
  }

  /// Arrête le tracking
  void stopTracking() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isTracking = false;
    _currentGameData = null;
    _currentPhase = null;
    notifyListeners();
  }

  /// Poll l'état de la partie
  Future<void> _pollGameState() async {
    try {
      // 1. Récupérer la phase actuelle via LCU
      final phase = await _getGameflowPhase();
      final phaseChanged = phase != _currentPhase;
      
      if (phaseChanged) {
        debugPrint('🔄 Changement de phase: $_currentPhase → $phase');
      }
      
      _currentPhase = phase;

      // 2. Si en partie, récupérer les données in-game
      if (phase == 'InProgress') {
        final gameData = await _getInGameData();
        if (gameData != null) {
          _currentGameData = gameData;
          // Reset counter et log success
          if (_api2999FailCount > 0) {
            debugPrint('✅ API 2999 maintenant disponible ! Données récupérées: ${gameData.players.length} joueurs');
            _api2999FailCount = 0;
          }
          
          // Toujours notifier pour mettre à jour l'UI
          if (hasListeners) notifyListeners();
        } else {
          // Ne log qu'une fois toutes les 10 tentatives
          _api2999FailCount++;
          if (_api2999FailCount == 1 || _api2999FailCount % 10 == 0) {
            debugPrint('⏳ En attente de l\'API 2999... (tentative $_api2999FailCount)');
          }
        }
      } else if (phase == 'ChampSelect') {
        _api2999FailCount = 0; // Reset counter
        final champSelectData = await _getChampSelectData();
        if (champSelectData != null) {
          _currentGameData = LiveGameData.fromChampSelect(champSelectData);
          if (phaseChanged) {
            debugPrint('✅ Données ChampSelect récupérées: ${_currentGameData?.players.length} joueurs');
          }
          if (hasListeners) notifyListeners();
        }
      } else if (phase == 'WaitingForStats' || phase == 'EndOfGame') {
        _api2999FailCount = 0;
        // Fin de partie détectée
        if (phaseChanged) {
          debugPrint('🏁 Fin de partie détectée ! Phase: $phase');
          // Mettre à jour la phase pour déclencher l'affichage du résultat
          if (hasListeners) notifyListeners();
        }
      } else if (phaseChanged) {
        _api2999FailCount = 0; // Reset counter
        // Phase a changé vers autre chose (None, Lobby, etc.)
        debugPrint('⚠️ Phase changée vers: $phase');
        if (hasListeners) notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur lors du poll: $e');
    }
  }

  /// Récupère la phase actuelle via LCU
  Future<String?> _getGameflowPhase() async {
    if (_lcuPort == null || _lcuPassword == null) return null;
    
    try {
      final client = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      
      final uri = Uri.parse('https://127.0.0.1:$_lcuPort/lol-gameflow/v1/gameflow-phase');
      final credentials = base64Encode(utf8.encode('riot:$_lcuPassword'));
      
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Basic $credentials');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        client.close();
        return responseBody.replaceAll('"', '').trim();
      }
      
      client.close();
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère les données de champion select via LCU
  Future<Map<String, dynamic>?> _getChampSelectData() async {
    if (_lcuPort == null || _lcuPassword == null) return null;
    
    try {
      final client = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      
      final uri = Uri.parse('https://127.0.0.1:$_lcuPort/lol-champ-select/v1/session');
      final credentials = base64Encode(utf8.encode('riot:$_lcuPassword'));
      
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Basic $credentials');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        client.close();
        return json.decode(responseBody);
      }
      
      client.close();
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère les données de la partie en cours via API in-game (port 2999)
  Future<LiveGameData?> _getInGameData() async {
    try {
      final client = HttpClient()
        ..badCertificateCallback = ((cert, host, port) => true);
      
      final request = await client.getUrl(Uri.parse('https://127.0.0.1:2999/liveclientdata/allgamedata'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        
        // Vérifier que la réponse n'est pas vide
        if (responseBody.isEmpty) {
          debugPrint('⚠️ API 2999: Réponse vide');
          client.close();
          return null;
        }
        
        try {
          final data = json.decode(responseBody);
          final gameData = LiveGameData.fromInGameApi(data);
          client.close();
          return gameData;
        } catch (parseError) {
          debugPrint('❌ Erreur parsing JSON API 2999: $parseError');
          debugPrint('📄 Début de la réponse: ${responseBody.substring(0, responseBody.length > 200 ? 200 : responseBody.length)}');
          client.close();
          return null;
        }
      }
      
      if (response.statusCode == 404) {
        // 404 = API pas encore prête, ne pas logger à chaque fois
        client.close();
        return null;
      }
      
      debugPrint('❌ API 2999 status: ${response.statusCode}');
      client.close();
      return null;
    } catch (e) {
      // Ne logger que les erreurs non-404
      if (!e.toString().contains('404')) {
        debugPrint('❌ Erreur API 2999: $e');
        if (e is RangeError) {
          debugPrint('🔍 RangeError détecté - Réponse probablement vide ou mal formée');
        }
      }
      return null;
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}

/// Données d'une partie en direct
class LiveGameData {
  final String phase; // 'ChampSelect' ou 'InProgress'
  final double gameTime;
  final String gameMode;
  final List<LivePlayer> players;
  final Map<String, dynamic>? rawData;

  LiveGameData({
    required this.phase,
    required this.gameTime,
    required this.gameMode,
    required this.players,
    this.rawData,
  });

  factory LiveGameData.fromInGameApi(Map<String, dynamic> data) {
    final gameData = data['gameData'] as Map<String, dynamic>;
    final allPlayers = data['allPlayers'] as List;
    final activePlayer = data['activePlayer'] as Map<String, dynamic>?;
    
    // Récupérer l'or et le nom du joueur actif
    final activePlayerGold = activePlayer?['currentGold'] is num 
      ? (activePlayer!['currentGold'] as num).toInt() 
      : 0;
    final activePlayerName = activePlayer?['riotIdGameName'] ?? activePlayer?['summonerName'] ?? '';
    
    debugPrint('💰 Or du joueur actif ($activePlayerName): $activePlayerGold');
    
    return LiveGameData(
      phase: 'InProgress',
      gameTime: (gameData['gameTime'] as num?)?.toDouble() ?? 0.0,
      gameMode: gameData['gameMode'] ?? 'CLASSIC',
      players: allPlayers.map((p) => LivePlayer.fromInGameApi(p, activePlayerName, activePlayerGold)).toList(),
      rawData: data,
    );
  }

  factory LiveGameData.fromChampSelect(Map<String, dynamic> data) {
    // Récupérer les données des deux équipes
    final myTeam = data['myTeam'] as List? ?? [];
    final theirTeam = data['theirTeam'] as List? ?? [];
    
    debugPrint('📊 ChampSelect - MyTeam: ${myTeam.length} joueurs, TheirTeam: ${theirTeam.length} joueurs');
    debugPrint('📊 RAW myTeam data: $myTeam');
    debugPrint('📊 RAW theirTeam data: $theirTeam');
    
    final players = [
      ...myTeam.map((p) => LivePlayer.fromChampSelect(p, 100)),
      ...theirTeam.map((p) => LivePlayer.fromChampSelect(p, 200)),
    ];
    
    debugPrint('📊 Total joueurs créés: ${players.length}');
    
    return LiveGameData(
      phase: 'ChampSelect',
      gameTime: 0.0,
      gameMode: 'CLASSIC',
      players: players,
      rawData: data,
    );
  }

  List<LivePlayer> getTeamPlayers(int teamId) {
    return players.where((p) => p.teamId == teamId).toList();
  }
}

/// Données d'un joueur en direct
class LivePlayer {
  final String summonerName;
  final String championName;
  final int championId;
  final int teamId;
  final String position;
  
  // Stats in-game
  final int kills;
  final int deaths;
  final int assists;
  final int level;
  final int cs;
  final int gold;
  final List<int> items;
  final List<int> summonerSpells;

  LivePlayer({
    required this.summonerName,
    required this.championName,
    required this.championId,
    required this.teamId,
    required this.position,
    this.kills = 0,
    this.deaths = 0,
    this.assists = 0,
    this.level = 1,
    this.cs = 0,
    this.gold = 0,
    this.items = const [],
    this.summonerSpells = const [],
  });

  factory LivePlayer.fromInGameApi(Map<String, dynamic> data, String activePlayerName, int activePlayerGold) {
    final scores = data['scores'] as Map<String, dynamic>?;
    
    // Nom du joueur
    final name = data['riotIdGameName'] ?? data['summonerName'] ?? 'Unknown';
    
    // Parser les items de manière sécurisée et calculer leur valeur totale
    final itemsList = data['items'] as List?;
    final items = <int>[];
    int itemsValue = 0;
    
    if (itemsList != null) {
      for (int i = 0; i < 6; i++) {
        if (i < itemsList.length && itemsList[i] != null) {
          final item = itemsList[i] as Map<String, dynamic>?;
          final itemId = item?['itemID'] ?? 0;
          items.add(itemId);
          
          // Ignorer les consommables (potions, wards)
          if (itemId == 0 || itemId >= 3340 || itemId == 2003 || itemId == 2055 || itemId == 2031 || itemId == 2010) {
            continue;
          }
          
          // Utiliser la valeur réelle de l'item via une base de données de prix
          final itemPrice = _getItemPrice(itemId);
          itemsValue += itemPrice;
          
          debugPrint('💎 Item $itemId: prix estimé = $itemPrice');
        } else {
          items.add(0);
        }
      }
    } else {
      items.addAll([0, 0, 0, 0, 0, 0]);
    }
    
    debugPrint('💰 $name: Or en poche=${name == activePlayerName ? activePlayerGold : "?"}, Items=$itemsValue');
    
    // Récupérer les valeurs
    final csRaw = scores?['creepScore'] ?? 0;
    final cs = csRaw is num ? csRaw.toInt() : 0;
    
    // Calculer l'or total = or en poche + valeur des items
    int gold = 0;
    if (name == activePlayerName) {
      // Pour le joueur actif : or en poche + valeur des items
      gold = activePlayerGold + itemsValue;
    } else {
      // Pour les autres : estimer avec items + CS
      gold = itemsValue + (cs * 20);
    }
    
    return LivePlayer(
      summonerName: name,
      championName: data['championName'] ?? '',
      championId: 0,
      teamId: data['team'] == 'ORDER' ? 100 : 200,
      position: data['position'] ?? 'NONE',
      kills: scores?['kills'] ?? 0,
      deaths: scores?['deaths'] ?? 0,
      assists: scores?['assists'] ?? 0,
      level: data['level'] ?? 1,
      cs: cs,
      gold: gold,
      items: items,
      summonerSpells: [
        data['summonerSpells']?['summonerSpellOne']?['displayName'] != null ? 1 : 0,
        data['summonerSpells']?['summonerSpellTwo']?['displayName'] != null ? 1 : 0,
      ],
    );
  }

  factory LivePlayer.fromChampSelect(Map<String, dynamic> data, int teamId) {
    // Le pseudo est dans gameName + tagLine
    String name = 'Unknown';
    final gameName = data['gameName']?.toString() ?? '';
    final tagLine = data['tagLine']?.toString() ?? '';
    
    if (gameName.isNotEmpty) {
      name = tagLine.isNotEmpty ? '$gameName#$tagLine' : gameName;
    } else if (data['summonerName'] != null && data['summonerName'].toString().isNotEmpty) {
      name = data['summonerName'];
    } else if (data['displayName'] != null && data['displayName'].toString().isNotEmpty) {
      name = data['displayName'];
    } else if (data['puuid'] != null) {
      // Utiliser une partie du PUUID si aucun nom n'est disponible
      name = 'Player ${data['puuid'].toString().substring(0, 8)}';
    }
    
    final champId = data['championId'] ?? 0;
    final champName = _getChampionNameFromId(champId);
    
    debugPrint('👤 Joueur ChampSelect: $name | Champion ID: $champId → $champName | Team: $teamId');
    
    return LivePlayer(
      summonerName: name,
      championName: champName,
      championId: champId,
      teamId: teamId,
      position: data['assignedPosition'] ?? 'NONE',
      summonerSpells: [
        data['spell1Id'] ?? 0,
        data['spell2Id'] ?? 0,
      ],
    );
  }

  static int _getItemPrice(int itemId) {
    // Base de prix approximative des items les plus courants
    final Map<int, int> itemPrices = {
      // Items de départ
      1055: 450, 1056: 450, 1054: 400, 1082: 350, 1083: 400,
      // Bottes
      1001: 300, 3006: 900, 3047: 1100, 3020: 1100, 3111: 1100, 3009: 1100, 3158: 1100,
      // Mythiques ADC
      6672: 3000, 6673: 2800, 3153: 3200, 3031: 3400,
      // Mythiques Support
      3107: 2200, 3190: 2500, 3152: 2500,
      // Mythiques Tank
      3068: 3200, 6630: 2800, 3001: 2500,
      // Items légendaires courants
      3004: 2600, 3072: 3000, 3074: 3300, 3087: 2600, 3094: 2800,
      3508: 2700, 3046: 3000, 3085: 2800, 3036: 2600, 3033: 2500,
      3075: 2700, 3109: 2500, 3050: 2500, 3065: 2700,
      // Composants
      1037: 1300, 1038: 1300, 1053: 800, 1052: 800, 1058: 600,
      1027: 350, 1028: 300, 1029: 300, 1026: 350, 1011: 350,
      3067: 800, 3057: 800, 3066: 700, 1036: 400, 1042: 600,
    };
    
    // Si l'item est connu, retourner son prix, sinon estimation basique
    if (itemPrices.containsKey(itemId)) {
      return itemPrices[itemId]!;
    }
    
    // Estimation par range d'ID
    if (itemId >= 6600) return 3000; // Mythiques récents
    if (itemId >= 3000) return 2500; // Items légendaires
    if (itemId >= 2000) return 50;   // Consommables
    if (itemId >= 1000) return 500;  // Composants
    return 0;
  }

  static String _getChampionNameFromId(int id) {
    // Mapping des champions les plus communs - à compléter avec la liste complète
    final Map<int, String> champions = {
      1: 'Annie', 2: 'Olaf', 3: 'Galio', 4: 'Twisted Fate', 5: 'Xin Zhao',
      6: 'Urgot', 7: 'LeBlanc', 8: 'Vladimir', 9: 'Fiddlesticks', 10: 'Kayle',
      11: 'Master Yi', 12: 'Alistar', 13: 'Ryze', 14: 'Sion', 15: 'Sivir',
      16: 'Soraka', 17: 'Teemo', 18: 'Tristana', 19: 'Warwick', 20: 'Nunu',
      21: 'Miss Fortune', 22: 'Ashe', 23: 'Tryndamere', 24: 'Jax', 25: 'Morgana',
      26: 'Zilean', 27: 'Singed', 28: 'Evelynn', 29: 'Twitch', 30: 'Karthus',
      31: 'Cho\'Gath', 32: 'Amumu', 33: 'Rammus', 34: 'Anivia', 35: 'Shaco',
      36: 'Dr. Mundo', 37: 'Sona', 38: 'Kassadin', 39: 'Irelia', 40: 'Janna',
      41: 'Gangplank', 42: 'Corki', 43: 'Karma', 44: 'Taric', 45: 'Veigar',
      48: 'Trundle', 50: 'Swain', 51: 'Caitlyn', 53: 'Blitzcrank', 54: 'Malphite',
      55: 'Katarina', 56: 'Nocturne', 57: 'Maokai', 58: 'Renekton', 59: 'Jarvan IV',
      60: 'Elise', 61: 'Orianna', 62: 'Wukong', 63: 'Brand', 64: 'Lee Sin',
      67: 'Vayne', 68: 'Rumble', 69: 'Cassiopeia', 72: 'Skarner', 74: 'Heimerdinger',
      75: 'Nasus', 76: 'Nidalee', 77: 'Udyr', 78: 'Poppy', 79: 'Gragas',
      80: 'Pantheon', 81: 'Ezreal', 82: 'Mordekaiser', 83: 'Yorick', 84: 'Akali',
      85: 'Kennen', 86: 'Garen', 89: 'Leona', 90: 'Malzahar', 91: 'Talon',
      92: 'Riven', 96: 'Kog\'Maw', 98: 'Shen', 99: 'Lux', 101: 'Xerath',
      102: 'Shyvana', 103: 'Ahri', 104: 'Graves', 105: 'Fizz', 106: 'Volibear',
      107: 'Rengar', 110: 'Varus', 111: 'Nautilus', 112: 'Viktor', 113: 'Sejuani',
      114: 'Fiora', 115: 'Ziggs', 117: 'Lulu', 119: 'Draven', 120: 'Hecarim',
      121: 'Kha\'Zix', 122: 'Darius', 126: 'Jayce', 127: 'Lissandra', 131: 'Diana',
      133: 'Quinn', 134: 'Syndra', 136: 'Aurelion Sol', 141: 'Kayn', 142: 'Zoe',
      143: 'Zyra', 145: 'Kai\'Sa', 147: 'Seraphine', 150: 'Gnar', 154: 'Zac',
      157: 'Yasuo', 161: 'Vel\'Koz', 163: 'Taliyah', 164: 'Camille', 166: 'Akshan',
      201: 'Braum', 202: 'Jhin', 203: 'Kindred', 221: 'Zeri', 222: 'Jinx',
      223: 'Tahm Kench', 234: 'Viego', 235: 'Senna', 236: 'Lucian', 238: 'Zed',
      240: 'Kled', 245: 'Ekko', 246: 'Qiyana', 254: 'Vi', 266: 'Aatrox',
      267: 'Nami', 268: 'Azir', 350: 'Yuumi', 360: 'Samira', 412: 'Thresh',
      420: 'Illaoi', 421: 'Rek\'Sai', 427: 'Ivern', 429: 'Kalista', 432: 'Bard',
      497: 'Rakan', 498: 'Xayah', 516: 'Ornn', 517: 'Sylas', 518: 'Neeko',
      523: 'Aphelios', 526: 'Rell', 555: 'Pyke', 711: 'Vex', 777: 'Yone',
      799: 'Ambessa', 875: 'Sett', 876: 'Lillia', 887: 'Gwen', 888: 'Renata Glasc',
      895: 'Nilah', 897: 'K\'Sante', 902: 'Milio', 910: 'Hwei', 950: 'Smolder',
      200: 'Bel\'Veth', 893: 'Aurora', 233: 'Briar'
    };
    
    return champions[id] ?? 'Champion #$id';
  }

  double get kda {
    if (deaths == 0) return (kills + assists).toDouble();
    return (kills + assists) / deaths;
  }
}
