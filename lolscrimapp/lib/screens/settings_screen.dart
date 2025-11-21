import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/lol_connection_service.dart';

/// Écran des paramètres de l'application
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Espacement pour pousser le bouton en bas
            const Spacer(),
            
            // Bouton de connexion LOL
            Consumer<LolConnectionService>(
              builder: (context, lolService, child) {
                final isConnected = lolService.isConnected;
                
                return SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _handleConnectionToggle(context, lolService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? Colors.green : Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnected ? Icons.check_circle : Icons.error,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          isConnected ? 'Connecté à LoL' : 'Se connecter à LoL',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Gère le clic sur le bouton de connexion
  void _handleConnectionToggle(BuildContext context, LolConnectionService service) async {
    if (service.isConnected) {
      // Déjà connecté, ne rien faire pour le moment
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déjà connecté à LoL'),
          backgroundColor: Colors.blue,
        ),
      );
    } else {
      // Tenter la connexion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentative de connexion à LoL...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      try {
        await service.connect();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Connecté à LoL avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Échec de connexion: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
