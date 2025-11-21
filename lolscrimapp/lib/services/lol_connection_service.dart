import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service de connexion à League of Legends via LCU API
class LolConnectionService extends ChangeNotifier {
  bool _isConnected = false;
  String? _port;
  String? _password;
  String? _summonerName;
  
  // Chemins possibles du lockfile
  static const List<String> _lockfilePaths = [
    r'D:\League Of Legends\Riot Games\League of Legends\lockfile',
    r'C:\Riot Games\League of Legends\lockfile',
    r'C:\Program Files\Riot Games\League of Legends\lockfile',
    r'C:\Program Files (x86)\Riot Games\League of Legends\lockfile',
  ];

  /// Indique si le service est actuellement connecté au client LoL
  bool get isConnected => _isConnected;
  
  /// Nom du joueur connecté (si disponible)
  String? get summonerName => _summonerName;

  /// Tente de se connecter au client League of Legends
  Future<void> connect() async {
    try {
      // 1. Lire le lockfile
      final lockfileData = await _readLockfile();
      if (lockfileData == null) {
        throw Exception('Client League of Legends non détecté.\n\nAssurez-vous que le client est lancé.');
      }
      
      _port = lockfileData['port'];
      _password = lockfileData['password'];
      
      // 2. Tester la connexion en récupérant les infos du joueur
      final summoner = await _getCurrentSummoner();
      if (summoner == null) {
        throw Exception('Impossible de se connecter à l\'API du client.');
      }
      
      _summonerName = summoner['displayName'] ?? summoner['gameName'] ?? 'Inconnu';
      _isConnected = true;
      notifyListeners();
      
    } catch (e) {
      _isConnected = false;
      _port = null;
      _password = null;
      _summonerName = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Déconnecte du client League of Legends
  Future<void> disconnect() async {
    _isConnected = false;
    _port = null;
    _password = null;
    _summonerName = null;
    notifyListeners();
  }
  
  /// Récupère les données du lockfile pour usage externe
  Future<Map<String, String>?> getLockfileData() async {
    return await _readLockfile();
  }
  
  /// Lit le fichier lockfile pour extraire les informations de connexion
  Future<Map<String, String>?> _readLockfile() async {
    for (final path in _lockfilePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final content = await file.readAsString();
          // Format: LeagueClient:pid:port:password:protocol
          final parts = content.trim().split(':');
          
          if (parts.length >= 5) {
            return {
              'port': parts[2],
              'password': parts[3],
              'protocol': parts[4],
            };
          }
        }
      } catch (e) {
        // Continue vers le prochain chemin
        continue;
      }
    }
    return null;
  }
  
  /// Récupère les informations du joueur actuellement connecté
  Future<Map<String, dynamic>?> _getCurrentSummoner() async {
    if (_port == null || _password == null) return null;
    
    try {
      final uri = Uri.parse('https://127.0.0.1:$_port/lol-summoner/v1/current-summoner');
      final credentials = base64Encode(utf8.encode('riot:$_password'));
      
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Basic $credentials');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        return json.decode(responseBody);
      }
      
      client.close();
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du summoner: $e');
      return null;
    }
  }
  
  /// Effectue une requête GET vers l'API LCU et retourne la réponse brute
  Future<String?> requestRaw(String endpoint) async {
    if (!_isConnected || _port == null || _password == null) {
      return null;
    }
    
    try {
      final uri = Uri.parse('https://127.0.0.1:$_port$endpoint');
      final credentials = base64Encode(utf8.encode('riot:$_password'));
      
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Basic $credentials');
      
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        client.close();
        return responseBody;
      }
      
      client.close();
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la requête LCU: $e');
      return null;
    }
  }

  /// Effectue une requête GET vers l'API LCU
  Future<Map<String, dynamic>?> request(String endpoint) async {
    if (!_isConnected || _port == null || _password == null) {
      return null;
    }
    
    try {
      final uri = Uri.parse('https://127.0.0.1:$_port$endpoint');
      final credentials = base64Encode(utf8.encode('riot:$_password'));
      
      final client = HttpClient()
        ..badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      
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
      debugPrint('Erreur lors de la requête LCU: $e');
      return null;
    }
  }
}
