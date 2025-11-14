import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scrims_provider.dart';
import '../services/teams_provider.dart';
import '../models/scrim.dart';
import 'create_scrim_screen.dart';
import 'scrim_details_screen.dart';

/// Écran de gestion des scrims
class ScrimsScreen extends StatefulWidget {
  const ScrimsScreen({super.key});

  @override
  State<ScrimsScreen> createState() => _ScrimsScreenState();
}

class _ScrimsScreenState extends State<ScrimsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ScrimsProvider>(
      builder: (context, scrimsProvider, child) {
        if (scrimsProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (scrimsProvider.scrims.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_esports,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucun scrim enregistré',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Cliquez sur le bouton + pour créer votre premier scrim',
                  style: TextStyle(color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateScrim(),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un scrim'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Afficher la liste des scrims
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scrimsProvider.scrims.length,
          itemBuilder: (context, index) {
            final scrim = scrimsProvider.scrims[index];
            return _buildScrimCard(scrim);
          },
        );
      },
    );
  }
  
  Widget _buildScrimCard(Scrim scrim) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToScrimDetails(scrim),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scrim.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'vs ${scrim.enemyTeamName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${scrim.myTeamWins} - ${scrim.enemyTeamWins}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${scrim.matches.length}/${scrim.totalMatches} matchs',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '${scrim.createdAt.day}/${scrim.createdAt.month}/${scrim.createdAt.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (scrim.patch != null) ...[
                  Icon(
                    Icons.update,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Patch ${scrim.patch}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            if (scrim.matches.length < scrim.totalMatches) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: scrim.matches.length / scrim.totalMatches,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ],
          ],
        ),
      ),
    ));
  }
  
  void _navigateToCreateScrim() async {
    final teamsProvider = context.read<TeamsProvider>();
    
    if (teamsProvider.teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vous devez créer au moins une équipe avant de pouvoir créer un scrim'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Si une seule équipe, l'utiliser directement
    if (teamsProvider.teams.length == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateScrimScreen(team: teamsProvider.teams.first),
        ),
      );
      return;
    }
    
    // Sinon, permettre à l'utilisateur de choisir
    final selectedTeam = await showDialog<dynamic>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner une équipe'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teamsProvider.teams.length,
            itemBuilder: (context, index) {
              final team = teamsProvider.teams[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    team.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(color: Colors.blue.shade800),
                  ),
                ),
                title: Text(team.name),
                subtitle: Text('${team.playerIds.length}/5 joueurs'),
                onTap: () => Navigator.of(context).pop(team),
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
      ),
    );
    
    if (selectedTeam != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateScrimScreen(team: selectedTeam),
        ),
      );
    }
  }
  
  void _navigateToScrimDetails(Scrim scrim) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ScrimDetailsScreen(scrim: scrim),
      ),
    ).then((result) {
      if (result == true) {
        // Les données ont été modifiées, recharger
        setState(() {});
      }
    });
  }
}