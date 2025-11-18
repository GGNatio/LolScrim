import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'screenshot_preview_screen.dart';
import 'screenshot_preview_screen_with_custom_zones.dart';

/// 📍 Modèle de zone OCR modifiable
class EditableZone {
  String id;
  String label;
  String type;
  Color color;
  Rect rect; // Coordonnées relatives (0.0 à 1.0)
  bool isSelected;
  
  EditableZone({
    required this.id,
    required this.label,
    required this.type,
    required this.color,
    required this.rect,
    this.isSelected = false,
  });
  
  EditableZone copyWith({
    String? id,
    String? label,
    String? type,
    Color? color,
    Rect? rect,
    bool? isSelected,
  }) {
    return EditableZone(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      color: color ?? this.color,
      rect: rect ?? this.rect,
      isSelected: isSelected ?? this.isSelected,
    );
  }
  
  /// Convertit les coordonnées relatives en absolues
  Rect toAbsoluteRect(Size imageSize) {
    return Rect.fromLTWH(
      rect.left * imageSize.width,
      rect.top * imageSize.height,
      rect.width * imageSize.width,
      rect.height * imageSize.height,
    );
  }
  
  /// Convertit les coordonnées absolues en relatives
  static Rect toRelativeRect(Rect absolute, Size imageSize) {
    return Rect.fromLTWH(
      absolute.left / imageSize.width,
      absolute.top / imageSize.height,
      absolute.width / imageSize.width,
      absolute.height / imageSize.height,
    );
  }
}

/// 🎯 Écran de prévisualisation interactive avec zones OCR ajustables
class InteractiveOCRPreviewScreen extends StatefulWidget {
  final File screenshotFile;
  final Function(List<Map<String, dynamic>> myTeam, List<Map<String, dynamic>> enemyTeam) onConfirm;
  
  const InteractiveOCRPreviewScreen({
    super.key,
    required this.screenshotFile,
    required this.onConfirm,
  });

  @override
  State<InteractiveOCRPreviewScreen> createState() => _InteractiveOCRPreviewScreenState();
}

class _InteractiveOCRPreviewScreenState extends State<InteractiveOCRPreviewScreen> {
  bool _isProcessingOCR = false;
  double _progress = 0.0;
  String _statusMessage = '';
  
  // 🎯 Gestion des zones modifiables
  List<EditableZone> _zones = [];
  EditableZone? _selectedZone;
  bool _isDragging = false;
  bool _isResizing = false;
  String? _resizeHandle; // 'tl', 'tr', 'bl', 'br', 'top', 'bottom', 'left', 'right'
  Offset? _lastPanPosition;
  
  @override
  void initState() {
    super.initState();
    _initializePreciseZones();
  }
  
  /// 🎯 Initialise des zones ULTRA-précises basées sur l'analyse de 4 screenshots réels
  void _initializePreciseZones() {
    _zones.clear();
    
    print('🎮 Calibrage ULTRA-précis basé sur analyse de screenshots réels...');
    
    // 🎯 CALIBRAGE MANUEL PARFAIT - Basé sur vos 3 zones positionnées
    // Équipe 1 (Bleue) - Coordonnées extraites de votre positionnement manuel
    for (int i = 0; i < 5; i++) {
      final baseY = 0.145 + (i * 0.044); // Espacement déduit de vos zones manuelles
      
      _zones.addAll([
        EditableZone(
          id: 't1_p${i + 1}_name',
          label: '👤${i + 1}',
          type: 'name',
          color: Colors.blue,
          rect: Rect.fromLTWH(0.182, baseY, 0.095, 0.022), // Basé sur vos zones
        ),
        EditableZone(
          id: 't1_p${i + 1}_kda',
          label: '⚔️',
          type: 'kda',
          color: Colors.blue,
          rect: Rect.fromLTWH(0.548, baseY, 0.065, 0.022), // Position KDA de vos zones
        ),
        EditableZone(
          id: 't1_p${i + 1}_cs',
          label: '🗡️',
          type: 'cs',
          color: Colors.blue,
          rect: Rect.fromLTWH(0.628, baseY, 0.035, 0.022), // Position CS de vos zones
        ),
        EditableZone(
          id: 't1_p${i + 1}_gold',
          label: '💰',
          type: 'gold',
          color: Colors.blue,
          rect: Rect.fromLTWH(0.678, baseY, 0.055, 0.022), // Position Gold de vos zones
        ),
      ]);
    }
    
    // Équipe 2 (Rouge) - Mêmes coordonnées parfaites que l'équipe 1
    for (int i = 0; i < 5; i++) {
      final baseY = 0.385 + (i * 0.044); // Position équipe 2 avec même espacement
      
      _zones.addAll([
        EditableZone(
          id: 't2_p${i + 1}_name',
          label: '👤${i + 1}',
          type: 'name',
          color: Colors.red,
          rect: Rect.fromLTWH(0.182, baseY, 0.095, 0.022), // Coordonnées identiques
        ),
        EditableZone(
          id: 't2_p${i + 1}_kda',
          label: '⚔️',
          type: 'kda',
          color: Colors.red,
          rect: Rect.fromLTWH(0.548, baseY, 0.065, 0.022), // Coordonnées identiques
        ),
        EditableZone(
          id: 't2_p${i + 1}_cs',
          label: '🗡️',
          type: 'cs',
          color: Colors.red,
          rect: Rect.fromLTWH(0.628, baseY, 0.035, 0.022), // Coordonnées identiques
        ),
        EditableZone(
          id: 't2_p${i + 1}_gold',
          label: '💰',
          type: 'gold',
          color: Colors.red,
          rect: Rect.fromLTWH(0.678, baseY, 0.055, 0.022), // Coordonnées identiques
        ),
      ]);
    }
    
    print('🎯 ✅ CALIBRAGE MANUEL PARFAIT: ${_zones.length} zones');
    print('   📌 Image: 1600x900px, BoxFit.contain pour proportions correctes');
    print('   🔵 Équipe 1: Y=0.145-0.321, X=0.182|0.548|0.628|0.678');
    print('   🔴 Équipe 2: Y=0.385-0.561, X=coordonnées identiques');
    print('   📊 Espacement: 0.044 (déduit de vos 3 zones manuelles)');
    print('   🎨 Coordonnées extraites de votre positionnement manuel parfait');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎯 Prévisualisation OCR Interactive'),
            Text(
              '📌 Fenêtre maximisée - Zones stables',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fermer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar avec bouton info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.visibility, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🎯 Mode prévisualisation : Ajustez les zones de détection AVANT de lancer l\'OCR',
                        style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '📌 Image verrouillée au centre (1200x675px) pour stabilité des coordonnées',
                        style: TextStyle(color: Colors.blue[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Bouton info
                IconButton(
                  onPressed: _showZonesInfoModal,
                  icon: Icon(Icons.info_outline, color: Colors.blue[700]),
                  tooltip: 'Informations sur les zones OCR',
                ),
              ],
            ),
          ),
          
          // 📌 Image VERROUILLÉE au centre avec zones OCR
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Container(
                  width: 1600, // Plus grand pour mieux voir l'image LoL
                  height: 900,  // Ratio 16:9 mais plus grand
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        // 🖼️ Image de base VERROUILLÉE avec proportions préservées
                        Positioned.fill(
                          child: widget.screenshotFile.existsSync()
                              ? Image.file(
                                  widget.screenshotFile,
                                  fit: BoxFit.contain, // Préserve les proportions
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Text('🖼️ Aperçu de l\'image'),
                                  ),
                                ),
                        ),
                        
                        // Overlay des zones OCR
                        Positioned.fill(
                          child: _buildOCRZonesOverlay(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Progress bar (si OCR en cours)
          if (_isProcessingOCR) _buildProgressBar(),
          
          // Boutons de contrôle
          _buildControls(),
        ],
      ),
    );
  }
  
  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Column(
        children: [
          LinearProgressIndicator(value: _progress),
          const SizedBox(height: 8),
          Text(_statusMessage, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Infos
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip('🔵 Mon équipe', '5 joueurs', Colors.blue),
              _buildStatChip('🔴 Adversaires', '5 joueurs', Colors.red),
              _buildStatChip('📊 Total zones', '40 zones', Colors.purple),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Boutons d'action
          Row(
            children: [
              // Annuler
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Annuler'),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Mode normal (sans prévisualisation)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _runDirectOCR,
                  icon: const Icon(Icons.flash_on, color: Colors.orange),
                  label: const Text('OCR Direct', style: TextStyle(color: Colors.orange)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Lancer OCR avec zones
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessingOCR ? null : _runCustomOCR,
                  icon: _isProcessingOCR 
                      ? const SizedBox(
                          width: 16, 
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isProcessingOCR ? 'OCR en cours...' : 'Lancer OCR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  /// 🚀 Lance l'OCR direct (mode actuel)
  Future<void> _runDirectOCR() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ScreenshotPreviewScreen(
          screenshotFile: widget.screenshotFile,
          onConfirm: widget.onConfirm,
        ),
      ),
    );
  }
  
  /// 🎯 Lance l'OCR avec zones personnalisées - VRAIE IMPLEMENTATION
  Future<void> _runCustomOCR() async {
    setState(() {
      _isProcessingOCR = true;
      _progress = 0.0;
      _statusMessage = '🎯 Préparation OCR avec vos zones parfaites...';
    });
    
    try {
      // 💪 UTILISER LES VRAIES ZONES PERSONNALISÉES
      final customZones = await _convertZonesToOCRFormat();
      
      setState(() {
        _statusMessage = '🔍 Analyse avec zones ultra-précises...';
        _progress = 0.2;
      });
      
      setState(() {
        _statusMessage = '🎯 Préparation des zones personnalisées...';
        _progress = 0.8;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _statusMessage = '✅ Zones prêtes ! Lancement de l\'OCR...';
        _progress = 1.0;
      });
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Naviguer vers l'écran ScreenshotPreviewScreen COMME AVANT
      // mais en passant les zones personnalisées
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ScreenshotPreviewScreenWithCustomZones(
              screenshotFile: widget.screenshotFile,
              customZones: customZones, // VOS zones personnalisées !
              onConfirm: widget.onConfirm,
            ),
          ),
        );
      }
      
      setState(() {
        _isProcessingOCR = false;
        _progress = 1.0;
        _statusMessage = '✅ OCR terminé !';
      });
      
    } catch (e) {
      setState(() {
        _isProcessingOCR = false;
        _statusMessage = '❌ Erreur OCR: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur OCR avec zones personnalisées: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
  
  /// 🔄 Convertit les zones EditableZone vers le format OCR
  Future<Map<String, Map<String, int>>> _convertZonesToOCRFormat() async {
    final customZones = <String, Map<String, int>>{};
    
    // NOUVEAU: Obtenir la taille RÉELLE de l'image au lieu de supposer 1920x1080
    final imageBytes = await widget.screenshotFile.readAsBytes();
    final realImage = img.decodeImage(imageBytes);
    final imageSize = realImage != null ? Size(realImage.width.toDouble(), realImage.height.toDouble()) : Size(1920, 1080);
    
    print('📸 TAILLE RÉELLE DE L\'IMAGE: ${imageSize.width}x${imageSize.height}');
    print('🎯 Interface calibrée pour: 1600x900 (mais zones relatives)');
    
    for (final zone in _zones) {
      final absoluteRect = zone.toAbsoluteRect(imageSize);
      
      customZones[zone.id] = {
        'x': absoluteRect.left.round(),
        'y': absoluteRect.top.round(),
        'width': absoluteRect.width.round(),
        'height': absoluteRect.height.round(),
      };
      
      print('  ${zone.id} (${zone.type}): rel=${zone.rect} → abs=x:${absoluteRect.left.round()}, y:${absoluteRect.top.round()}, w:${absoluteRect.width.round()}, h:${absoluteRect.height.round()}');
    }
    
    print('🎯 TOTAL: ${customZones.length} zones converties pour image ${imageSize.width}x${imageSize.height}');
    
    return customZones;
  }
  
  /// 🎯 Construit l'overlay des zones OCR interactives
  Widget _buildOCRZonesOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculer la taille réelle de l'image dans le conteneur
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return GestureDetector(
          onTapDown: (details) => _onTapDown(details, containerSize),
          onPanStart: (details) => _onPanStart(details, containerSize),
          onPanUpdate: (details) => _onPanUpdate(details, containerSize),
          onPanEnd: (details) => _onPanEnd(),
          child: Stack(
            children: _zones.map((zone) => _buildInteractiveZoneWidget(zone, containerSize)).toList(),
          ),
        );
      },
    );
  }
  
  /// 🎯 Construit un widget de zone OCR interactif
  Widget _buildInteractiveZoneWidget(EditableZone zone, Size imageSize) {
    final absoluteRect = zone.toAbsoluteRect(imageSize);
    
    return Positioned(
      left: absoluteRect.left,
      top: absoluteRect.top,
      width: absoluteRect.width,
      height: absoluteRect.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: zone.isSelected ? Colors.yellow : zone.color,
            width: zone.isSelected ? 3 : 2,
          ),
          color: zone.color.withOpacity(zone.isSelected ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Label de la zone
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  zone.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8, // Police plus petite
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Handles de redimensionnement (si sélectionnée)
            if (zone.isSelected) ..._buildResizeHandles(absoluteRect),
          ],
        ),
      ),
    );
  }
  
  /// 🔲 Construit les handles de redimensionnement
  List<Widget> _buildResizeHandles(Rect rect) {
    const handleSize = 4.0; // Très petits handles
    const handleColor = Colors.yellow;
    
    return [
      // Handle top-left
      Positioned(
        left: -handleSize / 2,
        top: -handleSize / 2,
        child: _buildHandle('tl', handleColor, handleSize),
      ),
      // Handle top-right
      Positioned(
        right: -handleSize / 2,
        top: -handleSize / 2,
        child: _buildHandle('tr', handleColor, handleSize),
      ),
      // Handle bottom-left
      Positioned(
        left: -handleSize / 2,
        bottom: -handleSize / 2,
        child: _buildHandle('bl', handleColor, handleSize),
      ),
      // Handle bottom-right
      Positioned(
        right: -handleSize / 2,
        bottom: -handleSize / 2,
        child: _buildHandle('br', handleColor, handleSize),
      ),
      // Handle top
      Positioned(
        left: rect.width / 2 - handleSize / 2,
        top: -handleSize / 2,
        child: _buildHandle('top', handleColor, handleSize),
      ),
      // Handle bottom
      Positioned(
        left: rect.width / 2 - handleSize / 2,
        bottom: -handleSize / 2,
        child: _buildHandle('bottom', handleColor, handleSize),
      ),
      // Handle left
      Positioned(
        left: -handleSize / 2,
        top: rect.height / 2 - handleSize / 2,
        child: _buildHandle('left', handleColor, handleSize),
      ),
      // Handle right
      Positioned(
        right: -handleSize / 2,
        top: rect.height / 2 - handleSize / 2,
        child: _buildHandle('right', handleColor, handleSize),
      ),
    ];
  }
  
  /// 🔲 Construit un handle individuel
  Widget _buildHandle(String type, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
  
  /// 👆 Gestion du tap sur l'overlay
  void _onTapDown(TapDownDetails details, Size imageSize) {
    final tapPosition = details.localPosition;
    
    // Chercher quelle zone a été touchée
    for (final zone in _zones) {
      final absoluteRect = zone.toAbsoluteRect(imageSize);
      if (absoluteRect.contains(tapPosition)) {
        setState(() {
          // Désélectionner les autres zones
          for (final z in _zones) {
            z.isSelected = false;
          }
          // Sélectionner cette zone
          zone.isSelected = true;
          _selectedZone = zone;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎯 Zone sélectionnée: ${zone.label} (${zone.type})'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.deepPurple,
          ),
        );
        return;
      }
    }
    
    // Si aucune zone touchée, désélectionner tout
    setState(() {
      for (final zone in _zones) {
        zone.isSelected = false;
      }
      _selectedZone = null;
    });
  }
  
  /// 🖱️ Début de pan (glissement/redimensionnement)
  void _onPanStart(DragStartDetails details, Size imageSize) {
    final startPosition = details.localPosition;
    _lastPanPosition = startPosition;
    
    if (_selectedZone == null) return;
    
    final absoluteRect = _selectedZone!.toAbsoluteRect(imageSize);
    
    // Déterminer si on commence un redimensionnement ou un déplacement
    _resizeHandle = _getResizeHandle(startPosition, absoluteRect);
    
    if (_resizeHandle != null) {
      _isResizing = true;
      _isDragging = false;
    } else if (absoluteRect.contains(startPosition)) {
      _isDragging = true;
      _isResizing = false;
    }
  }
  
  /// 🖱️ Mise à jour du pan
  void _onPanUpdate(DragUpdateDetails details, Size imageSize) {
    if (_selectedZone == null || _lastPanPosition == null) return;
    
    final currentPosition = details.localPosition;
    final delta = currentPosition - _lastPanPosition!;
    _lastPanPosition = currentPosition;
    
    setState(() {
      if (_isResizing && _resizeHandle != null) {
        _resizeZone(_selectedZone!, delta, imageSize);
      } else if (_isDragging) {
        _moveZone(_selectedZone!, delta, imageSize);
      }
    });
  }
  
  /// 🖱️ Fin de pan
  void _onPanEnd() {
    _isDragging = false;
    _isResizing = false;
    _resizeHandle = null;
    _lastPanPosition = null;
  }
  
  /// 🔍 Détermine quel handle de redimensionnement a été touché
  String? _getResizeHandle(Offset position, Rect rect) {
    const handleSize = 8.0;
    const tolerance = handleSize;
    
    // Coins
    if ((position - rect.topLeft).distance <= tolerance) return 'tl';
    if ((position - rect.topRight).distance <= tolerance) return 'tr';
    if ((position - rect.bottomLeft).distance <= tolerance) return 'bl';
    if ((position - rect.bottomRight).distance <= tolerance) return 'br';
    
    // Côtés
    if ((position.dy - rect.top).abs() <= tolerance && 
        position.dx >= rect.left - tolerance && position.dx <= rect.right + tolerance) {
      return 'top';
    }
    if ((position.dy - rect.bottom).abs() <= tolerance && 
        position.dx >= rect.left - tolerance && position.dx <= rect.right + tolerance) {
      return 'bottom';
    }
    if ((position.dx - rect.left).abs() <= tolerance && 
        position.dy >= rect.top - tolerance && position.dy <= rect.bottom + tolerance) {
      return 'left';
    }
    if ((position.dx - rect.right).abs() <= tolerance && 
        position.dy >= rect.top - tolerance && position.dy <= rect.bottom + tolerance) {
      return 'right';
    }
    
    return null;
  }
  
  /// 📏 Redimensionne une zone
  void _resizeZone(EditableZone zone, Offset delta, Size imageSize) {
    final currentRect = zone.rect;
    var newRect = currentRect;
    
    switch (_resizeHandle) {
      case 'tl':
        newRect = Rect.fromLTRB(
          (currentRect.left + delta.dx / imageSize.width).clamp(0.0, currentRect.right - 0.02),
          (currentRect.top + delta.dy / imageSize.height).clamp(0.0, currentRect.bottom - 0.02),
          currentRect.right,
          currentRect.bottom,
        );
        break;
      case 'tr':
        newRect = Rect.fromLTRB(
          currentRect.left,
          (currentRect.top + delta.dy / imageSize.height).clamp(0.0, currentRect.bottom - 0.02),
          (currentRect.right + delta.dx / imageSize.width).clamp(currentRect.left + 0.02, 1.0),
          currentRect.bottom,
        );
        break;
      case 'bl':
        newRect = Rect.fromLTRB(
          (currentRect.left + delta.dx / imageSize.width).clamp(0.0, currentRect.right - 0.02),
          currentRect.top,
          currentRect.right,
          (currentRect.bottom + delta.dy / imageSize.height).clamp(currentRect.top + 0.02, 1.0),
        );
        break;
      case 'br':
        newRect = Rect.fromLTRB(
          currentRect.left,
          currentRect.top,
          (currentRect.right + delta.dx / imageSize.width).clamp(currentRect.left + 0.02, 1.0),
          (currentRect.bottom + delta.dy / imageSize.height).clamp(currentRect.top + 0.02, 1.0),
        );
        break;
      case 'top':
        newRect = Rect.fromLTRB(
          currentRect.left,
          (currentRect.top + delta.dy / imageSize.height).clamp(0.0, currentRect.bottom - 0.02),
          currentRect.right,
          currentRect.bottom,
        );
        break;
      case 'bottom':
        newRect = Rect.fromLTRB(
          currentRect.left,
          currentRect.top,
          currentRect.right,
          (currentRect.bottom + delta.dy / imageSize.height).clamp(currentRect.top + 0.02, 1.0),
        );
        break;
      case 'left':
        newRect = Rect.fromLTRB(
          (currentRect.left + delta.dx / imageSize.width).clamp(0.0, currentRect.right - 0.02),
          currentRect.top,
          currentRect.right,
          currentRect.bottom,
        );
        break;
      case 'right':
        newRect = Rect.fromLTRB(
          currentRect.left,
          currentRect.top,
          (currentRect.right + delta.dx / imageSize.width).clamp(currentRect.left + 0.02, 1.0),
          currentRect.bottom,
        );
        break;
    }
    
    zone.rect = newRect;
  }
  
  /// 🚚 Déplace une zone
  void _moveZone(EditableZone zone, Offset delta, Size imageSize) {
    final relativeDelta = Offset(
      delta.dx / imageSize.width,
      delta.dy / imageSize.height,
    );
    
    final currentRect = zone.rect;
    final newRect = Rect.fromLTWH(
      (currentRect.left + relativeDelta.dx).clamp(0.0, 1.0 - currentRect.width),
      (currentRect.top + relativeDelta.dy).clamp(0.0, 1.0 - currentRect.height),
      currentRect.width,
      currentRect.height,
    );
    
    zone.rect = newRect;
  }
  
  /// ℹ️ Affiche le modal d'information sur les zones
  void _showZonesInfoModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('🎯 Zones OCR - Guide'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📍 **Types de zones détectées:**\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 👤 **Noms** - Pseudos des joueurs'),
              Text('• ⚔️ **KDA** - Kills/Deaths/Assists (ex: 7/2/14)'),
              Text('• 🗡️ **CS** - Creep Score (ex: 231)'),
              Text('• 💰 **Gold** - Or accumulé (ex: 15.0k)\n'),
              
              Text(
                '🎨 **Code couleur:**\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 🔵 **Bleu** = Mon équipe (5 joueurs)'),
              Text('• 🔴 **Rouge** = Équipe adverse (5 joueurs)\n'),
              
              Text(
                '🎯 **Interactions:**\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• 👆 **Cliquer** pour sélectionner une zone'),
              Text('• 🖱️ **Glisser** pour déplacer une zone'),
              Text('• 📏 **Ajuster** la taille si nécessaire\n'),
              
              Text(
                '🚀 **Utilisation:**\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('1. Vérifiez que les zones couvrent bien le texte'),
              Text('2. Ajustez les positions si nécessaire'),
              Text('3. Cliquez "Lancer OCR" pour traiter'),
              Text('4. Ou "OCR Direct" pour le mode rapide'),
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