
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/players_provider.dart';
import '../services/teams_provider.dart';
import '../services/scrims_provider.dart';
import '../services/storage_service.dart';
import '../widgets/create_team_modal.dart';
import 'teams_screen.dart';
import 'players_screen.dart';
import 'scrims_screen.dart';
import 'search_screen.dart';
import 'create_scrim_screen.dart';
import 'settings_screen.dart';
import 'debug_connection_screen.dart';
import 'create_scrim_modal.dart';


/// Écran principal avec navigation par onglets
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  final List<Tab> _tabs = [
    const Tab(text: 'Équipes', icon: Icon(Icons.groups)),
    const Tab(text: 'Joueurs', icon: Icon(Icons.person)),
    const Tab(text: 'Scrims', icon: Icon(Icons.sports_esports)),
    const Tab(text: 'Recherche', icon: Icon(Icons.search)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
    
    // Charger les données initiales après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Charge les données initiales de l'application
  Future<void> _loadInitialData() async {
    final playersProvider = context.read<PlayersProvider>();
    final teamsProvider = context.read<TeamsProvider>();
    final scrimsProvider = context.read<ScrimsProvider>();

    await Future.wait([
      playersProvider.loadPlayers(),
      teamsProvider.loadTeams(),
      scrimsProvider.loadScrims(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoL Scrim Manager'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        actions: [

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Plus d\'options',
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _openSettings();
                  break;
                case 'debug_connect':
                  _openDebugConnection();
                  break;
                case 'debug':
                  _debugStorage();
                  break;
                case 'test':
                  _testPersistence();
                  break;
                case 'clear':
                  _clearAllData();
                  break;
                case 'refresh':
                  _refreshData();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(children: [
                  Icon(Icons.settings), 
                  SizedBox(width: 8), 
                  Text('Paramètres')
                ]),
              ),
              const PopupMenuItem(
                value: 'debug_connect',
                child: Row(children: [
                  Icon(Icons.cable), 
                  SizedBox(width: 8), 
                  Text('Debug Connect')
                ]),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: Row(children: [
                  Icon(Icons.bug_report), 
                  SizedBox(width: 8), 
                  Text('Debug')
                ]),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Row(children: [
                  Icon(Icons.save), 
                  SizedBox(width: 8), 
                  Text('Test sauvegarde')
                ]),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(children: [
                  Icon(Icons.delete_sweep), 
                  SizedBox(width: 8), 
                  Text('Vider données')
                ]),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(children: [
                  Icon(Icons.refresh), 
                  SizedBox(width: 8), 
                  Text('Actualiser')
                ]),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(children: [
                  Icon(Icons.info_outline), 
                  SizedBox(width: 8), 
                  Text('À propos')
                ]),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TeamsScreen(),
          PlayersScreen(),
          ScrimsScreen(),
          SearchScreen(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Construit le bouton d'action flottant selon l'onglet actuel
  Widget? _buildFloatingActionButton() {
    switch (_currentIndex) {
      case 0: // Équipes
        return FloatingActionButton(
          onPressed: () => _showCreateTeamDialog(),
          tooltip: 'Ajouter une équipe',
          child: const Icon(Icons.group_add),
        );
      case 1: // Joueurs
        return FloatingActionButton(
          onPressed: () => _showCreatePlayerDialog(),
          tooltip: 'Ajouter un joueur',
          child: const Icon(Icons.person_add),
        );
      case 2: // Scrims
        return FloatingActionButton(
          onPressed: () => _showCreateScrimDialog(),
          tooltip: 'Ajouter un scrim',
          child: const Icon(Icons.add),
        );
      case 3: // Recherche
        return null; // Pas de FAB pour la recherche
      default:
        return null;
    }
  }

  /// Actualise toutes les données
  Future<void> _refreshData() async {
    try {
      await _loadInitialData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données actualisées'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'actualisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche la boîte de dialogue À propos
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'LoL Scrim Manager',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 LoL Scrim Manager',
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'Application de gestion d\'équipes esport pour League of Legends.\n\n'
            'Fonctionnalités :\n'
            '• Gestion des équipes et joueurs\n'
            '• Enregistrement des scrims\n'
            '• Analyses statistiques avancées\n'
            '• Recherches personnalisées',
          ),
        ),
      ],
    );
  }

  /// Affiche le modal de création d'équipe
  void _showCreateTeamDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTeamModal(
        onTeamCreated: (team) async {
          try {
            await context.read<TeamsProvider>().addTeam(team);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de la sauvegarde : $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  /// Placeholder pour la création de joueur
  void _showCreatePlayerDialog() {
    // TODO: Implémenter la création de joueur
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Création de joueur - À implémenter')),
    );
  }

  /// Navigue vers la création de scrim
  void _showCreateScrimDialog() async {
    final teamsProvider = context.read<TeamsProvider>();
    final teams = teamsProvider.teams;
    
    if (teams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vous devez d\'abord créer une équipe'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (teams.length == 1) {
      // Si une seule équipe, ouvrir le modal de choix
      showDialog(
        context: context,
        builder: (context) => CreateScrimModal(team: teams.first),
      );
    } else {
      // Sinon, montrer un dialogue de sélection d'équipe
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une équipe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: teams.map((team) => ListTile(
              leading: CircleAvatar(
                child: Text(team.name.substring(0, 1).toUpperCase()),
              ),
              title: Text(team.name),
              subtitle: Text('${team.playerIds.length} joueurs'),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => CreateScrimModal(team: team),
                );
              },
            )).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );
    }
  }

  /// Test de persistance des données
  void _testPersistence() async {
    try {
      // Force la sauvegarde
      await StorageService.forceSave();
      
      // Test immédiat de rechargement
      await StorageService.debugReport();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Données sauvegardées ! Vérifiez la console (F12) puis testez avec CTRL+R (pas redémarrage serveur)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Vide toutes les données
  void _clearAllData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider toutes les données'),
        content: const Text('Voulez-vous vraiment supprimer toutes les équipes, joueurs et scrims ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await StorageService.clearAll();
                await _loadInitialData(); // Recharge l'interface
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Toutes les données ont été supprimées'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Debug du stockage
  void _debugStorage() async {
    await StorageService.debugReport();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🐛 Rapport de debug affiché dans la console (F12 → Console)'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Ouvre l'écran des paramètres
  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  /// Ouvre l'écran de debug de la connexion LCU
  void _openDebugConnection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DebugConnectionScreen(),
      ),
    );
  }
}