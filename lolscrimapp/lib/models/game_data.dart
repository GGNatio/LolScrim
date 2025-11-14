/// Énumération des sorts d'invocateur de League of Legends
enum SummonerSpell {
  flash('Flash', '✦'),
  ignite('Ignite', '🔥'),
  heal('Heal', '💚'),
  ghost('Ghost', '👻'),
  teleport('Teleport', '🌀'),
  cleanse('Cleanse', '✨'),
  exhaust('Exhaust', '💨'),
  barrier('Barrier', '🛡️'),
  smite('Smite', '⚡'),
  clarity('Clarity', '💙'),
  mark('Mark/Dash', '❄️'),
  poro('Poro-Snax', '🐾'),
  none('Aucun', '');

  const SummonerSpell(this.name, this.emoji);
  final String name;
  final String emoji;

  String get displayName => emoji.isEmpty ? name : '$emoji $name';
}

/// Énumération des objets populaires de League of Legends
enum Item {
  // Objets de démarrage
  doransBlade('Doran\'s Blade', '🗡️'),
  doransRing('Doran\'s Ring', '💍'),
  doransShield('Doran\'s Shield', '🛡️'),
  
  // Bottes
  berserkersGreaves('Berserker\'s Greaves', '👢'),
  sorcerersShoes('Sorcerer\'s Shoes', '👠'),
  ninjaTabi('Plated Steelcaps', '🥾'),
  mercurysTreads('Mercury\'s Treads', '👟'),
  mobilityBoots('Boots of Mobility', '🏃'),
  
  // Objets AD
  infinityEdge('Infinity Edge', '⚔️'),
  kraken('Kraken Slayer', '🔱'),
  galeforce('Galeforce', '🌪️'),
  immortalShieldbow('Immortal Shieldbow', '🏹'),
  bloodthirster('The Bloodthirster', '🩸'),
  lordDominiksRegards('Lord Dominik\'s Regards', '👑'),
  
  // Objets AP
  liandrysAnguish('Liandry\'s Anguish', '🔥'),
  ludens('Luden\'s Tempest', '⚡'),
  everfrost('Everfrost', '❄️'),
  rocketbelt('Hextech Rocketbelt', '🚀'),
  rabadons('Rabadon\'s Deathcap', '🎩'),
  voidStaff('Void Staff', '🔮'),
  
  // Objets Tank
  sunfire('Sunfire Aegis', '☀️'),
  frostfire('Frostfire Gauntlet', '🧊'),
  chemtank('Turbo Chemtank', '⚗️'),
  thornmail('Thornmail', '🌹'),
  spiritVisage('Spirit Visage', '👻'),
  
  // Objets Support
  shurelyasReverie('Shurelya\'s Battlesong', '🎵'),
  locketOfIronSolari('Locket of the Iron Solari', '🌅'),
  imperialMandate('Imperial Mandate', '📜'),
  moonstone('Moonstone Renewer', '🌙'),
  
  // Objets de base
  bootsOfSpeed('Boots of Speed', '👠'),
  faerieCharm('Faerie Charm', '✨'),
  rejuvenationBead('Rejuvenation Bead', '💚'),
  giantsBelt('Giant\'s Belt', '🟤'),
  cloakOfAgility('Cloak of Agility', '💨'),
  blastingWand('Blasting Wand', '🔥'),
  sapphireCrystal('Sapphire Crystal', '💎'),
  rubyGem('Ruby Crystal', '❤️'),
  clothArmor('Cloth Armor', '🛡️'),
  chainVest('Chain Vest', '⛓️'),
  nullMagicMantle('Null-Magic Mantle', '🌀'),
  longSword('Long Sword', '🗡️'),
  pickaxe('Pickaxe', '⛏️'),
  bfSword('B. F. Sword', '⚔️'),
  daggerr('Dagger', '🗡️'),
  recurveBow('Recurve Bow', '🏹'),
  amplifyingTome('Amplifying Tome', '📚'),
  vampiricScepter('Vampiric Scepter', '🧛'),
  
  // Objets génériques
  guardiansAngel('Guardian Angel', '👼'),
  zhonyas('Zhonya\'s Hourglass', '⏳'),
  banshees('Banshee\'s Veil', '👻'),
  qss('Quicksilver Sash', '💫'),
  
  empty('', ''),
  none('Aucun objet', '');

  const Item(this.name, this.emoji);
  final String name;
  final String emoji;

  String get displayName => emoji.isEmpty ? name : '$emoji $name';
  
  /// Catégories d'objets pour le filtrage
  static List<Item> get boots => [
    berserkersGreaves, sorcerersShoes, ninjaTabi, mercurysTreads, mobilityBoots
  ];
  
  static List<Item> get adItems => [
    infinityEdge, kraken, galeforce, immortalShieldbow, bloodthirster, lordDominiksRegards
  ];
  
  static List<Item> get apItems => [
    liandrysAnguish, ludens, everfrost, rocketbelt, rabadons, voidStaff
  ];
  
  static List<Item> get tankItems => [
    sunfire, frostfire, chemtank, thornmail, spiritVisage
  ];
  
  static List<Item> get supportItems => [
    shurelyasReverie, locketOfIronSolari, imperialMandate, moonstone
  ];
  
  static List<Item> get allItems => Item.values.where((item) => item != none).toList();
}

/// Classe représentant un build complet d'un joueur
class PlayerBuild {
  final List<Item> items;
  final Item? boots;
  final Item? trinket;

  const PlayerBuild({
    this.items = const [],
    this.boots,
    this.trinket,
  });

  /// Retourne une liste de tous les objets (items + bottes + trinket)
  List<Item> get allItems {
    final List<Item> result = List.from(items);
    if (boots != null && boots != Item.none) result.add(boots!);
    if (trinket != null && trinket != Item.none) result.add(trinket!);
    return result;
  }

  PlayerBuild copyWith({
    List<Item>? items,
    Item? boots,
    Item? trinket,
  }) {
    return PlayerBuild(
      items: items ?? this.items,
      boots: boots ?? this.boots,
      trinket: trinket ?? this.trinket,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items.map((item) => item.name).toList(),
      'boots': boots?.name,
      'trinket': trinket?.name,
    };
  }

  factory PlayerBuild.fromMap(Map<String, dynamic> map) {
    return PlayerBuild(
      items: (map['items'] as List<dynamic>?)
          ?.map((name) => Item.values.firstWhere(
                (item) => item.name == name,
                orElse: () => Item.none,
              ))
          .where((item) => item != Item.none)
          .toList() ?? [],
      boots: map['boots'] != null
          ? Item.values.firstWhere(
              (item) => item.name == map['boots'],
              orElse: () => Item.none,
            )
          : null,
      trinket: map['trinket'] != null
          ? Item.values.firstWhere(
              (item) => item.name == map['trinket'],
              orElse: () => Item.none,
            )
          : null,
    );
  }
}