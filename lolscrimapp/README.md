# LoL Scrim Manager 🎮

Une application compagnon esport complète pour gérer des équipes League of Legends avec un système avancé de requêtes statistiques.

## 🎯 Fonctionnalités Principales

### Gestion Complète
- **Équipes** : Création, modification, gestion des rosters
- **Joueurs** : Profils détaillés avec rôles et statistiques
- **Scrims** : Enregistrement complet des matchs d'entraînement

### Système de Requêtes Avancées 🔍
- **Winrate vs Champions** : Performance contre des champions spécifiques
- **Stats Moyennes** : KDA, CS, performances par champion
- **Analyse d'Équipes** : Performance contre des équipes adverses
- **Métriques Personnalisées** : Système modulaire extensible

## 🏗️ Architecture

### Modèles de Données
```
lib/models/
├── player.dart          # Joueur avec rôle et informations
├── team.dart            # Équipe avec roster management
├── scrim.dart           # Match avec résultats détaillés
└── player_stats.dart    # Statistiques individuelles par match
```

### Moteur de Requêtes
```
lib/query_engine/
├── query_types.dart     # Types de requêtes et filtres
├── query_result.dart    # Résultats et métriques
└── query_engine.dart    # Moteur principal d'exécution
```

### Services
```
lib/services/
├── database_service.dart    # SQLite avec relations complètes
├── players_provider.dart    # État des joueurs
├── teams_provider.dart      # État des équipes
└── scrims_provider.dart     # État des scrims
```

### Interface Utilisateur
```
lib/screens/
├── home_screen.dart     # Navigation principale par onglets
├── search_screen.dart   # Interface de recherche avancée
├── teams_screen.dart    # Gestion des équipes
├── players_screen.dart  # Gestion des joueurs
└── scrims_screen.dart   # Gestion des scrims
```

## 🚀 Démarrage Rapide

### Prérequis
- Flutter 3.10+
- Dart 3.0+

### Installation
```bash
# Cloner le projet
git clone <repository-url>
cd lolscrimapp

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
```

## 📊 Exemples de Requêtes Supportées

### 1. Winrate Individuel
```
🎯 "Quel est le winrate de notre midlaner contre Yasuo ?"
→ Type: Winrate vs Champion
→ Joueur: [Sélectionner midlaner]
→ Filtre: Champion ennemi = "Yasuo"
```

### 2. Performance Moyenne
```
📈 "Quelle est la KDA moyenne de notre ADC sur Jinx ?"
→ Type: Stats moyennes sur Champion  
→ Joueur: [Sélectionner ADC]
→ Champion: "Jinx"
```

### 3. Analyse d'Équipe
```
⚔️ "Comment performons-nous contre Team Liquid ?"
→ Type: Performance vs Équipe
→ Équipe adverse: "Team Liquid"
```

### 4. Requêtes Complexes Possibles
- "Quels champions notre midlaner performe le mieux contre les assassins ?"
- "Quel joueur est le plus performant sur le patch actuel ?"
- "Quel champion a le meilleur impact (KDA + winrate pondéré) ?"

## 🛠️ Technologies Utilisées

- **Flutter** : Interface utilisateur cross-platform
- **Provider** : Gestion d'état réactive
- **SQLite** : Base de données locale avec relations
- **Google Fonts** : Typography moderne
- **FL Chart** : Visualisations statistiques (prévu)

## 📱 Captures d'écran

L'application dispose d'une interface moderne avec :
- Navigation par onglets intuitive
- Thème adaptatif clair/sombre
- Interface de recherche en deux panneaux
- Cartes et visualisations élégantes

## 🔮 Roadmap

### Phase 1 ✅ (Complété)
- [x] Architecture des modèles de données
- [x] Moteur de requêtes modulaire
- [x] Base de données avec relations
- [x] Interface de base avec navigation

### Phase 2 🔨 (En cours)
- [ ] Formulaires de création (équipes, joueurs, scrims)
- [ ] Interface de recherche fonctionnelle
- [ ] Validation des données
- [ ] Données d'exemple pour tests

### Phase 3 📊 (Prévu)
- [ ] Graphiques et visualisations
- [ ] Export des résultats
- [ ] Filtres avancés (patch, date, etc.)
- [ ] Comparaisons entre joueurs

### Phase 4 🎯 (Futur)
- [ ] Analyse de draft
- [ ] Calendrier des scrims
- [ ] Synchronisation cloud
- [ ] API de statistiques externes

## 🧩 Extensibilité

Le système est conçu pour être facilement extensible :

### Nouveaux Types de Requêtes
Ajoutez simplement un nouveau `QueryType` et implémentez la méthode correspondante dans `QueryEngine`.

### Nouvelles Métriques
Étendez `MetricType` et ajoutez le calcul dans les classes de résultats.

### Nouveaux Filtres
Définissez un `FilterType` et ajoutez la logique de filtrage.

## 🤝 Contribution

Les contributions sont les bienvenues ! L'architecture modulaire facilite l'ajout de nouvelles fonctionnalités.

## 📄 Licence

Ce projet est sous licence MIT.

---

*Développé pour la communauté esport League of Legends* 🏆
