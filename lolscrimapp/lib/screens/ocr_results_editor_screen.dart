import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📝 Classe pour stocker les données d'édition d'un joueur
class PlayerEditData {
  String name;
  int kills;
  int deaths;
  int assists;
  int cs;
  int gold;
  double confidence;
  bool recognized;
  
  PlayerEditData({
    required this.name,
    required this.kills,
    required this.deaths,
    required this.assists,
    required this.cs,
    required this.gold,
    this.confidence = 0.0,
    this.recognized = false,
  });
  
  factory PlayerEditData.fromMap(Map<String, dynamic> map) {
    return PlayerEditData(
      name: map['name']?.toString() ?? '',
      kills: (map['kills'] as num?)?.toInt() ?? 0,
      deaths: (map['deaths'] as num?)?.toInt() ?? 0,
      assists: (map['assists'] as num?)?.toInt() ?? 0,
      cs: (map['cs'] as num?)?.toInt() ?? 0,
      gold: (map['gold'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      recognized: map['recognized'] as bool? ?? false,
    );
  }
  
  factory PlayerEditData.empty(int playerNumber) {
    return PlayerEditData(
      name: 'Joueur $playerNumber',
      kills: 0,
      deaths: 0,
      assists: 0,
      cs: 0,
      gold: 0,
      confidence: 0.0,
      recognized: false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'kills': kills,
      'deaths': deaths,
      'assists': assists,
      'cs': cs,
      'gold': gold,
      'confidence': confidence,
      'recognized': recognized,
    };
  }
}

/// 🎯 Écran d'édition rapide des résultats OCR
/// Permet de corriger facilement les données détectées
class OCRResultsEditorScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialPlayers;
  final Function(List<Map<String, dynamic>> correctedPlayers) onSave;
  
  const OCRResultsEditorScreen({
    super.key,
    required this.initialPlayers,
    required this.onSave,
  });

  @override
  State<OCRResultsEditorScreen> createState() => _OCRResultsEditorScreenState();
}

class _OCRResultsEditorScreenState extends State<OCRResultsEditorScreen> {
  late List<PlayerEditData> _players;
  bool _hasUnsavedChanges = false;
  
  @override
  void initState() {
    super.initState();
    _players = widget.initialPlayers.map((p) => PlayerEditData.fromMap(p)).toList();
    
    // S'assurer qu'on a 10 joueurs (5 par équipe)
    while (_players.length < 10) {
      _players.add(PlayerEditData.empty(_players.length + 1));
    }
  }
  
  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }
  
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📝 Modifications non sauvegardées'),
        content: const Text('Voulez-vous perdre vos modifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Perdre les modifications', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }
  
  void _saveResults() {
    final correctedPlayers = _players.map((p) => p.toMap()).toList();
    widget.onSave(correctedPlayers);
    setState(() => _hasUnsavedChanges = false);
    Navigator.of(context).pop();
  }
  
  void _resetPlayer(int index) {
    setState(() {
      if (index < widget.initialPlayers.length) {
        _players[index] = PlayerEditData.fromMap(widget.initialPlayers[index]);
      } else {
        _players[index] = PlayerEditData.empty(index + 1);
      }
      _markAsChanged();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('✏️ Corriger les Résultats OCR'),
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          actions: [
            if (_hasUnsavedChanges)
              const Icon(Icons.circle, color: Colors.orange, size: 12),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHelp,
              tooltip: 'Aide',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveResults,
              tooltip: 'Sauvegarder',
            ),
          ],
        ),
        body: Column(
          children: [
            // 📊 Barre d'info rapide
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue[50],
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Tapez rapidement pour corriger les erreurs OCR',
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  if (_hasUnsavedChanges)
                    const Text(
                      '● Non sauvé',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
            
            // 📝 Liste des joueurs à éditer
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 🔵 Équipe 1
                  _buildTeamHeader('🔵 Mon Équipe', Colors.blue),
                  const SizedBox(height: 8),
                  ..._buildTeamPlayers(0, 5, Colors.blue[50]!),
                  
                  const SizedBox(height: 24),
                  
                  // 🔴 Équipe 2  
                  _buildTeamHeader('🔴 Équipe Adverse', Colors.red),
                  const SizedBox(height: 8),
                  ..._buildTeamPlayers(5, 10, Colors.red[50]!),
                ],
              ),
            ),
            
            // 💾 Boutons d'action
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saveResults,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('💾 Sauvegarder et Continuer'),
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
  
  Widget _buildTeamHeader(String title, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  
  List<Widget> _buildTeamPlayers(int startIndex, int endIndex, Color backgroundColor) {
    return List.generate(endIndex - startIndex, (i) {
      final playerIndex = startIndex + i;
      final player = _players[playerIndex];
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 Nom du joueur
            Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${i + 1}.',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: player.name,
                    decoration: const InputDecoration(
                      labelText: '👤 Nom du joueur',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      player.name = value;
                      _markAsChanged();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: () => _resetPlayer(playerIndex),
                  tooltip: 'Réinitialiser',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 📊 Stats en ligne
            Row(
              children: [
                // K/D/A
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: player.kills.toString(),
                          decoration: const InputDecoration(
                            labelText: '⚔️ K',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            player.kills = int.tryParse(value) ?? 0;
                            _markAsChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          initialValue: player.deaths.toString(),
                          decoration: const InputDecoration(
                            labelText: '💀 D',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            player.deaths = int.tryParse(value) ?? 0;
                            _markAsChanged();
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          initialValue: player.assists.toString(),
                          decoration: const InputDecoration(
                            labelText: '🤝 A',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            player.assists = int.tryParse(value) ?? 0;
                            _markAsChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // CS
                Expanded(
                  child: TextFormField(
                    initialValue: player.cs.toString(),
                    decoration: const InputDecoration(
                      labelText: '🗡️ CS',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      player.cs = int.tryParse(value) ?? 0;
                      _markAsChanged();
                    },
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Gold
                Expanded(
                  child: TextFormField(
                    initialValue: player.gold.toString(),
                    decoration: const InputDecoration(
                      labelText: '💰 Gold',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      player.gold = int.tryParse(value) ?? 0;
                      _markAsChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
  
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Aide - Édition Rapide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯 **Correction rapide des résultats OCR**\n'),
              Text('• Tapez directement pour corriger les noms'),
              Text('• Les nombres sont automatiquement validés'),
              Text('• Utilisez 🔄 pour réinitialiser un joueur'),
              Text('• Les modifications sont marquées par ●\n'),
              Text('🔵 **Mon Équipe** = 5 premiers joueurs'),
              Text('🔴 **Équipe Adverse** = 5 derniers joueurs\n'),
              Text('💾 **Sauvegarde automatique** avant fermeture'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris !'),
          ),
        ],
      ),
    );
  }
}