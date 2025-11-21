import 'package:flutter/material.dart';
import '../models/team.dart';
import 'live_scrim_tracking_screen.dart';

/// Écran de configuration d'un scrim en direct
class LiveScrimConfigScreen extends StatefulWidget {
  final Team team;

  const LiveScrimConfigScreen({
    super.key,
    required this.team,
  });

  @override
  State<LiveScrimConfigScreen> createState() => _LiveScrimConfigScreenState();
}

class _LiveScrimConfigScreenState extends State<LiveScrimConfigScreen> {
  final TextEditingController _opponentController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Mode de scrim
  ScrimMode _scrimMode = ScrimMode.bestOf;
  
  // Pour le mode Best Of
  int _bestOfValue = 3;
  
  // Pour le mode nombre de matchs
  int _numberOfGames = 3;

  @override
  void dispose() {
    _opponentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration du scrim en direct'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Votre équipe
            _buildSection(
              title: 'Votre équipe',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      child: Text(widget.team.name.substring(0, 1).toUpperCase()),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.team.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.team.playerIds.length} joueurs',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Équipe adverse
            _buildSection(
              title: 'Équipe adverse',
              child: TextField(
                controller: _opponentController,
                decoration: const InputDecoration(
                  hintText: 'Nom de l\'équipe adverse',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mode de scrim
            _buildSection(
              title: 'Format du scrim',
              child: Column(
                children: [
                  // Boutons de sélection du mode
                  Row(
                    children: [
                      Expanded(
                        child: _buildModeButton(
                          mode: ScrimMode.bestOf,
                          icon: Icons.emoji_events,
                          label: 'Best of',
                          subtitle: 'S\'arrête au vainqueur',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModeButton(
                          mode: ScrimMode.fixedGames,
                          icon: Icons.format_list_numbered,
                          label: 'Nombre de matchs',
                          subtitle: 'Joue X matchs',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Configuration selon le mode
                  if (_scrimMode == ScrimMode.bestOf) ...[
                    _buildBestOfSelector(),
                  ] else ...[
                    _buildNumberOfGamesSelector(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notes
            _buildSection(
              title: 'Notes (optionnel)',
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ajoutez des notes sur ce scrim...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _startScrim,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Démarrer le scrim',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildModeButton({
    required ScrimMode mode,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _scrimMode == mode;
    return InkWell(
      onTap: () => setState(() => _scrimMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.green : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green : Colors.grey.shade700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.green.shade700 : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestOfSelector() {
    return Column(
      children: [
        const Text('Format Best of:'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildBestOfChip(1),
            const SizedBox(width: 8),
            _buildBestOfChip(3),
            const SizedBox(width: 8),
            _buildBestOfChip(5),
          ],
        ),
      ],
    );
  }

  Widget _buildBestOfChip(int value) {
    final isSelected = _bestOfValue == value;
    return ChoiceChip(
      label: Text('BO$value'),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _bestOfValue = value);
        }
      },
    );
  }

  Widget _buildNumberOfGamesSelector() {
    return Column(
      children: [
        const Text('Nombre de matchs à jouer:'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _numberOfGames > 1
                  ? () => setState(() => _numberOfGames--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_numberOfGames',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _numberOfGames < 10
                  ? () => setState(() => _numberOfGames++)
                  : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  void _startScrim() {
    if (_opponentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer le nom de l\'équipe adverse'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigation vers l'écran de tracking
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LiveScrimTrackingScreen(
          yourTeam: widget.team,
          opponentTeamName: _opponentController.text.trim(),
          scrimMode: _scrimMode,
          bestOfValue: _bestOfValue,
          numberOfGames: _numberOfGames,
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }
}

/// Mode de scrim
enum ScrimMode {
  bestOf, // BO1, BO3, BO5 - s'arrête quand une équipe gagne
  fixedGames, // Nombre fixe de matchs
}
