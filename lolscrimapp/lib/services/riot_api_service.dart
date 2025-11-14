import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour interagir avec l'API Riot Games
class RiotApiService {
  // Clé API hardcodée pour éviter de demander à l'utilisateur
  static const String _hardcodedApiKey = 'RGAPI-fb013113-e53c-4eb0-bd55-07a1829c83b8';
  static const String _apiKeyKey = 'riot_api_key';
  static const String _baseUrlEurope = 'https://europe.api.riotgames.com';
  
  static String? _cachedApiKey;
  
  /// Sauvegarde la clé API
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
    _cachedApiKey = apiKey;
  }
  
  /// Récupère la clé API sauvegardée ou utilise la clé hardcodée
  static Future<String?> getApiKey() async {
    // Utilise toujours la clé hardcodée
    _cachedApiKey = _hardcodedApiKey;
    return _cachedApiKey;
  }
  
  /// Supprime la clé API
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyKey);
    _cachedApiKey = null;
  }
  
  /// Récupère les données d'un match par son ID
  static Future<RiotMatchData?> getMatchData(String matchId) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Clé API Riot manquante');
    }
    
    try {
      // Ajouter automatiquement le préfixe de région si manquant
      String formattedMatchId = matchId;
      if (!matchId.contains('_')) {
        // Si pas de région spécifiée, ajouter EUW1_ par défaut
        formattedMatchId = 'EUW1_$matchId';
      }
      
      // Récupération des détails du match
      final matchUrl = '$_baseUrlEurope/lol/match/v5/matches/$formattedMatchId?api_key=$apiKey';
      final matchResponse = await http.get(Uri.parse(matchUrl));
      
      if (matchResponse.statusCode == 401) {
        throw Exception('Clé API invalide ou expirée');
      }
      
      if (matchResponse.statusCode == 404) {
        throw Exception('Match introuvable avec ce code.\n\n⚠️ Important: L\'API Riot ne stocke que les matchs en parties classées, normales, ARAM et modes de jeu officiels.\n\nLes parties personnalisées (custom games) ne sont PAS disponibles via l\'API et ne peuvent donc pas être importées automatiquement.');
      }
      
      if (matchResponse.statusCode != 200) {
        throw Exception('Erreur API Riot: ${matchResponse.statusCode}');
      }
      
      final matchData = json.decode(matchResponse.body);
      return RiotMatchData.fromJson(matchData);
      
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur de connexion: $e');
    }
  }
  
  /// Récupère les informations d'un joueur par son PUUID
  static Future<RiotSummoner?> getSummonerByPuuid(String puuid) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) return null;
    
    try {
      final url = 'https://euw1.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/$puuid?api_key=$apiKey';
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RiotSummoner.fromJson(data);
      }
    } catch (e) {
      // Ignore les erreurs pour les summoners
    }
    
    return null;
  }
}

/// Modèle de données pour un match Riot
class RiotMatchData {
  final RiotMatchInfo info;
  
  RiotMatchData({required this.info});
  
  factory RiotMatchData.fromJson(Map<String, dynamic> json) {
    return RiotMatchData(
      info: RiotMatchInfo.fromJson(json['info']),
    );
  }
}

/// Informations du match
class RiotMatchInfo {
  final int gameDuration;
  final String gameVersion;
  final List<RiotParticipant> participants;
  final List<RiotTeam> teams;
  final DateTime gameCreation;
  final String gameMode;
  final int queueId;
  
  RiotMatchInfo({
    required this.gameDuration,
    required this.gameVersion,
    required this.participants,
    required this.teams,
    required this.gameCreation,
    required this.gameMode,
    required this.queueId,
  });
  
  factory RiotMatchInfo.fromJson(Map<String, dynamic> json) {
    return RiotMatchInfo(
      gameDuration: json['gameDuration'] ?? 0,
      gameVersion: json['gameVersion'] ?? '',
      participants: (json['participants'] as List)
          .map((p) => RiotParticipant.fromJson(p))
          .toList(),
      teams: (json['teams'] as List)
          .map((t) => RiotTeam.fromJson(t))
          .toList(),
      gameCreation: DateTime.fromMillisecondsSinceEpoch(json['gameCreation'] ?? 0),
      gameMode: json['gameMode'] ?? '',
      queueId: json['queueId'] ?? 0,
    );
  }
}

/// Données d'un participant
class RiotParticipant {
  final String puuid;
  final String summonerName;
  final String championName;
  final int championId;
  final String teamPosition;
  final int teamId;
  final bool win;
  
  // KDA
  final int kills;
  final int deaths;
  final int assists;
  
  // Stats
  final int totalMinionsKilled;
  final int neutralMinionsKilled;
  final int goldEarned;
  final int totalDamageDealtToChampions;
  final int totalDamageTaken;
  final int visionScore;
  final int champLevel;
  
  // Items (0-6)
  final int item0;
  final int item1;
  final int item2;
  final int item3;
  final int item4;
  final int item5;
  final int item6; // Trinket
  
  // Summoner spells
  final int summoner1Id;
  final int summoner2Id;
  
  RiotParticipant({
    required this.puuid,
    required this.summonerName,
    required this.championName,
    required this.championId,
    required this.teamPosition,
    required this.teamId,
    required this.win,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.totalMinionsKilled,
    required this.neutralMinionsKilled,
    required this.goldEarned,
    required this.totalDamageDealtToChampions,
    required this.totalDamageTaken,
    required this.visionScore,
    required this.champLevel,
    required this.item0,
    required this.item1,
    required this.item2,
    required this.item3,
    required this.item4,
    required this.item5,
    required this.item6,
    required this.summoner1Id,
    required this.summoner2Id,
  });
  
  factory RiotParticipant.fromJson(Map<String, dynamic> json) {
    return RiotParticipant(
      puuid: json['puuid'] ?? '',
      summonerName: json['riotIdGameName'] ?? json['summonerName'] ?? 'Inconnu',
      championName: json['championName'] ?? '',
      championId: json['championId'] ?? 0,
      teamPosition: json['teamPosition'] ?? '',
      teamId: json['teamId'] ?? 0,
      win: json['win'] ?? false,
      kills: json['kills'] ?? 0,
      deaths: json['deaths'] ?? 0,
      assists: json['assists'] ?? 0,
      totalMinionsKilled: json['totalMinionsKilled'] ?? 0,
      neutralMinionsKilled: json['neutralMinionsKilled'] ?? 0,
      goldEarned: json['goldEarned'] ?? 0,
      totalDamageDealtToChampions: json['totalDamageDealtToChampions'] ?? 0,
      totalDamageTaken: json['totalDamageTaken'] ?? 0,
      visionScore: json['visionScore'] ?? 0,
      champLevel: json['champLevel'] ?? 0,
      item0: json['item0'] ?? 0,
      item1: json['item1'] ?? 0,
      item2: json['item2'] ?? 0,
      item3: json['item3'] ?? 0,
      item4: json['item4'] ?? 0,
      item5: json['item5'] ?? 0,
      item6: json['item6'] ?? 0,
      summoner1Id: json['summoner1Id'] ?? 0,
      summoner2Id: json['summoner2Id'] ?? 0,
    );
  }
  
  /// Calcule le CS total (minions + jungle)
  int get totalCs => totalMinionsKilled + neutralMinionsKilled;
  
  /// Calcule le KDA ratio
  double get kdaRatio {
    if (deaths == 0) {
      return (kills + assists).toDouble();
    }
    return (kills + assists) / deaths;
  }
}

/// Données d'une équipe
class RiotTeam {
  final int teamId;
  final bool win;
  final List<RiotObjective> objectives;
  
  RiotTeam({
    required this.teamId,
    required this.win,
    required this.objectives,
  });
  
  factory RiotTeam.fromJson(Map<String, dynamic> json) {
    final objectives = <RiotObjective>[];
    final objectivesData = json['objectives'] as Map<String, dynamic>? ?? {};
    
    objectivesData.forEach((key, value) {
      objectives.add(RiotObjective(
        type: key,
        kills: value['kills'] ?? 0,
        first: value['first'] ?? false,
      ));
    });
    
    return RiotTeam(
      teamId: json['teamId'] ?? 0,
      win: json['win'] ?? false,
      objectives: objectives,
    );
  }
  
  /// Récupère le nombre d'objectifs par type
  int getObjectiveKills(String type) {
    final objective = objectives.firstWhere(
      (obj) => obj.type.toLowerCase() == type.toLowerCase(),
      orElse: () => RiotObjective(type: type, kills: 0, first: false),
    );
    return objective.kills;
  }
}

/// Objectif d'équipe (dragons, barons, etc.)
class RiotObjective {
  final String type;
  final int kills;
  final bool first;
  
  RiotObjective({
    required this.type,
    required this.kills,
    required this.first,
  });
}

/// Informations d'un summoner
class RiotSummoner {
  final String id;
  final String name;
  final String puuid;
  final int summonerLevel;
  
  RiotSummoner({
    required this.id,
    required this.name,
    required this.puuid,
    required this.summonerLevel,
  });
  
  factory RiotSummoner.fromJson(Map<String, dynamic> json) {
    return RiotSummoner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      puuid: json['puuid'] ?? '',
      summonerLevel: json['summonerLevel'] ?? 0,
    );
  }
}