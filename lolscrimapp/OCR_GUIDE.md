# 🎮 Guide OCR pour League of Legends

## 📋 Prérequis

### Installation de Tesseract OCR

1. **Télécharger Tesseract** :
   - Aller sur https://github.com/UB-Mannheim/tesseract/wiki
   - Télécharger `tesseract-ocr-w64-setup-5.x.x.exe` (version 64-bit)

2. **Installer Tesseract** :
   - Lancer l'installeur
   - **Important** : Noter le chemin d'installation (par défaut : `C:\Program Files\Tesseract-OCR`)
   - Cocher la langue **eng** (anglais) durant l'installation

3. **Ajouter au PATH** :
   ```powershell
   [Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";C:\Program Files\Tesseract-OCR", "Machine")
   ```
   
   Ou manuellement :
   - Rechercher "Variables d'environnement" dans Windows
   - Variables système → Path → Modifier
   - Nouveau → `C:\Program Files\Tesseract-OCR`
   - OK

4. **Vérifier l'installation** :
   ```powershell
   tesseract --version
   ```

## 🎯 Utilisation

### Importer un match via screenshot

1. Dans l'app, aller dans un scrim
2. Cliquer sur "Ajouter Match"
3. Sélectionner "Importer depuis Screenshot"
4. Choisir une image de scoreboard de fin de partie LoL
5. L'OCR analyse automatiquement l'image
6. Vérifier les données extraites
7. Confirmer

### Format d'image recommandé

- **Résolution** : 1920x1080 ou 1280x720
- **Format** : PNG ou JPG
- **Type** : Scoreboard de fin de partie (écran de victoire/défaite)
- **Qualité** : Image nette, bien éclairée

## ⚙️ Configuration des zones OCR

Si l'OCR ne détecte pas correctement les données, vous pouvez ajuster les zones dans le fichier :
`lib/services/lol_scoreboard_config.dart`

### Paramètres ajustables :

```dart
ResolutionConfig(
  team1StartY: 0.065,    // Position verticale premier joueur équipe 1 (%)
  team2StartY: 0.57,     // Position verticale premier joueur équipe 2 (%)
  lineHeight: 0.075,     // Espacement entre chaque ligne de joueur (%)
  nameX: 0.13,           // Position horizontale des noms (%)
  nameWidth: 0.15,       // Largeur zone nom (%)
  kdaX: 0.50,            // Position horizontale KDA (%)
  kdaWidth: 0.12,        // Largeur zone KDA (%)
  csX: 0.63,             // Position horizontale CS (%)
  csWidth: 0.07,         // Largeur zone CS (%)
  goldX: 0.71,           // Position horizontale Gold (%)
  goldWidth: 0.08,       // Largeur zone Gold (%)
  elementHeight: 0.035,  // Hauteur de chaque zone de texte (%)
)
```

### Comment calibrer :

1. Ouvrir votre screenshot dans un éditeur d'image
2. Noter les dimensions (ex: 1920x1080)
3. Mesurer la position des éléments :
   - Position Y du premier joueur équipe 1
   - Position Y du premier joueur équipe 2
   - Espace entre chaque joueur
   - Position X et largeur des colonnes
4. Convertir en pourcentage : `valeur / dimension`
5. Mettre à jour dans `lol_scoreboard_config.dart`

## 🔧 Dépannage

### L'OCR ne détecte rien

1. **Vérifier Tesseract** :
   ```powershell
   tesseract --version
   ```

2. **Vérifier le chemin** :
   - Ouvrir `lib/services/tesseract_engine.dart`
   - Vérifier `_tesseractPath` correspond à votre installation

3. **Qualité de l'image** :
   - Image trop petite : redimensionner à 1920x1080
   - Image floue : prendre un nouveau screenshot
   - Mauvais format : utiliser PNG

### Les noms sont mal reconnus

1. **Ajuster le contraste** dans `image_preprocessor.dart` :
   ```dart
   enhanced = img.adjustColor(
     croppedImage,
     contrast: 2.5,  // Augmenter pour texte plus clair
     brightness: 1.5,
     saturation: 0.3,
   );
   ```

2. **Modifier la whitelist** dans `tesseract_engine.dart` :
   ```dart
   '-c', 'tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 /-_'
   ```

### Les stats (KDA/CS/Gold) sont incorrectes

1. **Vérifier les zones** dans `lol_scoreboard_config.dart`
2. **Ajuster PSM mode** dans `tesseract_engine.dart` :
   ```dart
   '--psm', '7'  // Essayer 6, 7, ou 8
   ```

## 📊 Structure du système

```
lib/services/
├── ocr_orchestrator.dart       # Orchestrateur principal
├── tesseract_engine.dart       # Interface Tesseract
├── image_preprocessor.dart     # Prétraitement d'images
├── scoreboard_parser.dart      # Parsing des données
├── lol_scoreboard_config.dart  # Configuration des zones
└── screenshot_analyzer.dart    # Interface haut niveau
```

## 🎨 Exemple de zones

```
┌─────────────────────────────────────────────────┐
│ ÉQUIPE 1          KILLS/DEATHS/ASSISTS  CS  GOLD│
│                                                  │
│ [Icon] KS Natio      8 / 3 / 8         244 15247│← Ligne 1
│ [Icon] yhotone      10 / 4 / 16        173 14056│← Ligne 2
│ [Icon] KS Macha      5 / 8 / 14        277 16404│← Ligne 3
│ [Icon] Coach         8 / 4 / 10        268 17265│← Ligne 4
│ [Icon] KS Genius     3 / 3 / 22         25 10880│← Ligne 5
│                                                  │
├─────────────────────────────────────────────────┤← Séparateur
│                                                  │
│ ÉQUIPE 2          KILLS/DEATHS/ASSISTS  CS  GOLD│
│                                                  │
│ [Icon] Jesper        7 / 5 / 5         258 15673│
│ [Icon] GzzZ          5 / 7 / 16        174 12857│
│ [Icon] Sebber        3 / 11 / 11       221 11984│
│ [Icon] BluWolf95     7 / 4 / 5         300 15295│
│ [Icon] Birthe Kj     0 / 7 / 16         25  8144│
└─────────────────────────────────────────────────┘
```

## 🚀 Améliorations futures

- [ ] Support de plus de résolutions
- [ ] Détection automatique des zones
- [ ] OCR des objectifs (dragons, barons, etc.)
- [ ] Reconnaissance des champions
- [ ] Détection du gagnant
- [ ] Export des zones détectées pour debug

## 📝 Notes

- Les coordonnées sont en **pourcentage** pour supporter différentes résolutions
- Le système utilise un **fallback** si l'OCR échoue
- Les joueurs de votre équipe (KS) sont automatiquement reconnus
- La confiance minimale par défaut est **30%**
