# 🎮 LolScrim - Application Compagnon Esport LoL

Application de gestion d'équipes esport League of Legends avec système de requêtes statistiques avancées.

## 🚀 Fonctionnalités

- **Gestion des équipes** : Création, modification, roster management
- **Gestion des joueurs** : Création, association aux équipes, statistiques
- **Scrims & Matchs** : Enregistrement complet des parties avec KDA, champions, résultats
- **Requêtes statistiques** : Système modulaire pour analyses personnalisées
- **Base de données locale** : Stockage JSON pour portabilité maximale

## 🏗️ Architecture

- **Backend** : Node.js + TypeScript + Express
- **Base de données** : JSON local (pas de SQL)
- **Build** : Compilation en .exe avec PKG

## 🔧 Installation

```bash
npm install
npm run dev
```

## 📦 Build .exe

```bash
npm run build
npm run build:exe
```

## 📊 Structure des données

Toutes les données sont stockées dans `/data/` au format JSON :
- `teams.json` : Équipes
- `players.json` : Joueurs  
- `scrims.json` : Parties/Scrims
- `stats.json` : Cache statistiques