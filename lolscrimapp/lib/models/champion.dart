/// Énumération des rôles de League of Legends
enum Role {
  top('Top'),
  jungle('Jungle'),
  mid('Mid'),
  adc('ADC'),
  support('Support');

  const Role(this.displayName);
  final String displayName;
}

/// Modèle représentant un champion de League of Legends
class Champion {
  final String id;
  final String name;
  final String role;
  final String? imageUrl;
  
  /// Récupère le rôle primaire comme enum
  Role get primaryRole {
    switch (role.toLowerCase()) {
      case 'top':
        return Role.top;
      case 'jungle':
        return Role.jungle;
      case 'mid':
        return Role.mid;
      case 'adc':
        return Role.adc;
      case 'support':
        return Role.support;
      default:
        return Role.mid; // Par défaut
    }
  }

  const Champion({
    required this.id,
    required this.name,
    required this.role,
    this.imageUrl,
  });

  /// Crée une instance Champion à partir d'une Map
  factory Champion.fromMap(Map<String, dynamic> map) {
    return Champion(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      imageUrl: map['image_url'] as String?,
    );
  }

  /// Convertit l'instance Champion en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'image_url': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Champion && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Champion(id: $id, name: $name, role: $role)';
}

/// Liste complète de tous les champions League of Legends (170 champions - Mise à jour Nov 2024)
class Champions {
  static const List<Champion> all = [
    // A
    Champion(id: 'aatrox', name: 'Aatrox', role: 'Top', imageUrl: 'AatroxSquare.png'),
    Champion(id: 'ahri', name: 'Ahri', role: 'Mid', imageUrl: 'AhriSquare.png'),
    Champion(id: 'akali', name: 'Akali', role: 'Mid', imageUrl: 'AkaliSquare.png'),
    Champion(id: 'akshan', name: 'Akshan', role: 'ADC', imageUrl: 'AkshanSquare.png'),
    Champion(id: 'alistar', name: 'Alistar', role: 'Support', imageUrl: 'AlistarSquare.png'),
    Champion(id: 'ambessa', name: 'Ambessa', role: 'Top'),  // Nouveau - pas d'image disponible
    Champion(id: 'amumu', name: 'Ammu', role: 'Jungle', imageUrl: 'AmumuSquare.png'),
    Champion(id: 'anivia', name: 'Anivia', role: 'Mid', imageUrl: 'AniviaSquare.png'),
    Champion(id: 'annie', name: 'Annie', role: 'Mid', imageUrl: 'AnnieSquare.png'),
    Champion(id: 'aphelios', name: 'Aphelios', role: 'ADC', imageUrl: 'ApheliosSquare.png'),
    Champion(id: 'ashe', name: 'Ashe', role: 'ADC', imageUrl: 'AsheSquare.png'),
    Champion(id: 'aurelion_sol', name: 'Aurelion Sol', role: 'Mid', imageUrl: 'Aurelion_SolSquare.png'),
    Champion(id: 'aurora', name: 'Aurora', role: 'Mid'),  // Nouveau - pas d'image disponible
    Champion(id: 'azir', name: 'Azir', role: 'Mid', imageUrl: 'AzirSquare.png'),
    
    // B
    Champion(id: 'bard', name: 'Bard', role: 'Support', imageUrl: 'BardSquare.png'),
    Champion(id: 'belveth', name: "Bel'Veth", role: 'Jungle'),  // Nouveau - pas d'image disponible
    Champion(id: 'blitzcrank', name: 'Blitzcrank', role: 'Support', imageUrl: 'BlitzcrankSquare.png'),
    Champion(id: 'brand', name: 'Brand', role: 'Mid', imageUrl: 'BrandSquare.png'),
    Champion(id: 'braum', name: 'Braum', role: 'Support', imageUrl: 'BraumSquare.png'),
    Champion(id: 'briar', name: 'Briar', role: 'Jungle'),  // Nouveau - pas d'image disponible
    
    // C
    Champion(id: 'caitlyn', name: 'Caitlyn', role: 'ADC', imageUrl: 'CaitlynSquare.png'),
    Champion(id: 'camille', name: 'Camille', role: 'Top', imageUrl: 'CamilleSquare.png'),
    Champion(id: 'cassiopeia', name: 'Cassiopeia', role: 'Mid', imageUrl: 'CassiopeiaSquare.png'),
    Champion(id: 'chogath', name: "Cho'Gath", role: 'Top', imageUrl: 'Cho%27GathSquare.png'),
    Champion(id: 'corki', name: 'Corki', role: 'Mid', imageUrl: 'CorkiSquare.png'),
    
    // D
    Champion(id: 'darius', name: 'Darius', role: 'Top', imageUrl: 'DariusSquare.png'),
    Champion(id: 'diana', name: 'Diana', role: 'Jungle', imageUrl: 'DianaSquare.png'),
    Champion(id: 'dr_mundo', name: 'Dr. Mundo', role: 'Top', imageUrl: 'Dr._MundoSquare.png'),
    Champion(id: 'draven', name: 'Draven', role: 'ADC', imageUrl: 'DravenSquare.png'),
    
    // E
    Champion(id: 'ekko', name: 'Ekko', role: 'Mid', imageUrl: 'EkkoSquare.png'),
    Champion(id: 'elise', name: 'Elise', role: 'Jungle', imageUrl: 'EliseSquare.png'),
    Champion(id: 'evelynn', name: 'Evelynn', role: 'Jungle', imageUrl: 'EvelynnSquare.png'),
    Champion(id: 'ezreal', name: 'Ezreal', role: 'ADC', imageUrl: 'EzrealSquare.png'),
    
    // F
    Champion(id: 'fiddlesticks', name: 'Fiddlesticks', role: 'Jungle', imageUrl: 'FiddlesticksSquare.png'),
    Champion(id: 'fiora', name: 'Fiora', role: 'Top', imageUrl: 'FioraSquare.png'),
    Champion(id: 'fizz', name: 'Fizz', role: 'Mid', imageUrl: 'FizzSquare.png'),
    
    // G
    Champion(id: 'galio', name: 'Galio', role: 'Mid', imageUrl: 'GalioSquare.png'),
    Champion(id: 'gangplank', name: 'Gangplank', role: 'Top', imageUrl: 'GangplankSquare.png'),
    Champion(id: 'garen', name: 'Garen', role: 'Top', imageUrl: 'GarenSquare.png'),
    Champion(id: 'gnar', name: 'Gnar', role: 'Top', imageUrl: 'GnarSquare.png'),
    Champion(id: 'gragas', name: 'Gragas', role: 'Jungle', imageUrl: 'GragasSquare.png'),
    Champion(id: 'graves', name: 'Graves', role: 'Jungle', imageUrl: 'GravesSquare.png'),
    Champion(id: 'gwen', name: 'Gwen', role: 'Top', imageUrl: 'GwenSquare.png'),
    
    // H
    Champion(id: 'hecarim', name: 'Hecarim', role: 'Jungle', imageUrl: 'HecarimSquare.png'),
    Champion(id: 'heimerdinger', name: 'Heimerdinger', role: 'Mid', imageUrl: 'HeimerdingerSquare.png'),
    Champion(id: 'hwei', name: 'Hwei', role: 'Mid'),  // Nouveau - pas d'image disponible
    
    // I
    Champion(id: 'illaoi', name: 'Illaoi', role: 'Top', imageUrl: 'IllaoiSquare.png'),
    Champion(id: 'irelia', name: 'Irelia', role: 'Top', imageUrl: 'IreliaSquare.png'),
    Champion(id: 'ivern', name: 'Ivern', role: 'Jungle', imageUrl: 'IvernSquare.png'),
    
    // J
    Champion(id: 'janna', name: 'Janna', role: 'Support', imageUrl: 'JannaSquare.png'),
    Champion(id: 'jarvan_iv', name: 'Jarvan IV', role: 'Jungle', imageUrl: 'Jarvan_IVSquare.png'),
    Champion(id: 'jax', name: 'Jax', role: 'Top', imageUrl: 'JaxSquare.png'),
    Champion(id: 'jayce', name: 'Jayce', role: 'Top', imageUrl: 'JayceSquare.png'),
    Champion(id: 'jhin', name: 'Jhin', role: 'ADC', imageUrl: 'JhinSquare.png'),
    Champion(id: 'jinx', name: 'Jinx', role: 'ADC', imageUrl: 'JinxSquare.png'),
    
    // K
    Champion(id: 'ksante', name: "K'Sante", role: 'Top'),  // Nouveau - pas d'image disponible
    Champion(id: 'kaisa', name: "Kai'Sa", role: 'ADC', imageUrl: 'Kai%27SaSquare.png'),
    Champion(id: 'kalista', name: 'Kalista', role: 'ADC', imageUrl: 'KalistaSquare.png'),
    Champion(id: 'karma', name: 'Karma', role: 'Support', imageUrl: 'KarmaSquare.png'),
    Champion(id: 'karthus', name: 'Karthus', role: 'Jungle', imageUrl: 'KarthusSquare.png'),
    Champion(id: 'kassadin', name: 'Kassadin', role: 'Mid', imageUrl: 'KassadinSquare.png'),
    Champion(id: 'katarina', name: 'Katarina', role: 'Mid', imageUrl: 'KatarinaSquare.png'),
    Champion(id: 'kayle', name: 'Kayle', role: 'Top', imageUrl: 'KayleSquare.png'),
    Champion(id: 'kayn', name: 'Kayn', role: 'Jungle', imageUrl: 'KaynSquare.png'),
    Champion(id: 'kennen', name: 'Kennen', role: 'Top', imageUrl: 'KennenSquare.png'),
    Champion(id: 'khazix', name: "Kha'Zix", role: 'Jungle', imageUrl: 'Kha%27ZixSquare.png'),
    Champion(id: 'kindred', name: 'Kindred', role: 'Jungle', imageUrl: 'KindredSquare.png'),
    Champion(id: 'kled', name: 'Kled', role: 'Top', imageUrl: 'KledSquare.png'),
    Champion(id: 'kogmaw', name: "Kog'Maw", role: 'ADC', imageUrl: 'KogMawSquare.png'),
    
    // L
    Champion(id: 'leblanc', name: 'LeBlanc', role: 'Mid', imageUrl: 'LeBlancSquare.png'),
    Champion(id: 'leesin', name: 'Lee Sin', role: 'Jungle', imageUrl: 'Lee_SinSquare.png'),
    Champion(id: 'leona', name: 'Leona', role: 'Support', imageUrl: 'LeonaSquare.png'),
    Champion(id: 'lillia', name: 'Lillia', role: 'Jungle', imageUrl: 'LilliaSquare.png'),
    Champion(id: 'lissandra', name: 'Lissandra', role: 'Mid', imageUrl: 'LissandraSquare.png'),
    Champion(id: 'lucian', name: 'Lucian', role: 'ADC', imageUrl: 'LucianSquare.png'),
    Champion(id: 'lulu', name: 'Lulu', role: 'Support', imageUrl: 'LuluSquare.png'),
    Champion(id: 'lux', name: 'Lux', role: 'Mid', imageUrl: 'LuxSquare.png'),
    
    // M
    Champion(id: 'malphite', name: 'Malphite', role: 'Top', imageUrl: 'MalphiteSquare.png'),
    Champion(id: 'malzahar', name: 'Malzahar', role: 'Mid', imageUrl: 'MalzaharSquare.png'),
    Champion(id: 'maokai', name: 'Maokai', role: 'Top', imageUrl: 'MaokaiSquare.png'),
    Champion(id: 'master_yi', name: 'Master Yi', role: 'Jungle', imageUrl: 'Master_YiSquare.png'),
    Champion(id: 'mel', name: 'Mel', role: 'Mid'),  // Nouveau - pas d'image disponible
    Champion(id: 'milio', name: 'Milio', role: 'Support'),  // Nouveau - pas d'image disponible
    Champion(id: 'miss_fortune', name: 'Miss Fortune', role: 'ADC', imageUrl: 'MissFortuneSquare.png'),
    Champion(id: 'mordekaiser', name: 'Mordekaiser', role: 'Top', imageUrl: 'MordekaiserSquare.png'),
    Champion(id: 'morgana', name: 'Morgana', role: 'Support', imageUrl: 'MorganaSquare.png'),
    
    // N
    Champion(id: 'naafiri', name: 'Naafiri', role: 'Mid'),  // Nouveau - pas d'image disponible
    Champion(id: 'nami', name: 'Nami', role: 'Support', imageUrl: 'NamiSquare.png'),
    Champion(id: 'nasus', name: 'Nasus', role: 'Top', imageUrl: 'NasusSquare.png'),
    Champion(id: 'nautilus', name: 'Nautilus', role: 'Support', imageUrl: 'NautilusSquare.png'),
    Champion(id: 'neeko', name: 'Neeko', role: 'Mid', imageUrl: 'NeekoSquare.png'),
    Champion(id: 'nidalee', name: 'Nidalee', role: 'Jungle', imageUrl: 'NidaleeSquare.png'),
    Champion(id: 'nilah', name: 'Nilah', role: 'ADC'),  // Nouveau - pas d'image disponible
    Champion(id: 'nocturne', name: 'Nocturne', role: 'Jungle', imageUrl: 'NocturneSquare.png'),
    Champion(id: 'nunu', name: 'Nunu & Willump', role: 'Jungle', imageUrl: 'Nunu&WillumpSquare.png'),
    
    // O
    Champion(id: 'olaf', name: 'Olaf', role: 'Top', imageUrl: 'OlafSquare.png'),
    Champion(id: 'orianna', name: 'Orianna', role: 'Mid', imageUrl: 'OriannaSquare.png'),
    Champion(id: 'ornn', name: 'Ornn', role: 'Top', imageUrl: 'OrnnSquare.png'),
    
    // P
    Champion(id: 'pantheon', name: 'Pantheon', role: 'Top', imageUrl: 'PantheonSquare.png'),
    Champion(id: 'poppy', name: 'Poppy', role: 'Top', imageUrl: 'PoppySquare.png'),
    Champion(id: 'pyke', name: 'Pyke', role: 'Support', imageUrl: 'PykeSquare.png'),
    
    // Q
    Champion(id: 'qiyana', name: 'Qiyana', role: 'Mid', imageUrl: 'QiyanaSquare.png'),
    Champion(id: 'quinn', name: 'Quinn', role: 'Top', imageUrl: 'QuinnSquare.png'),
    
    // R
    Champion(id: 'rakan', name: 'Rakan', role: 'Support', imageUrl: 'RakanSquare.png'),
    Champion(id: 'rammus', name: 'Rammus', role: 'Jungle', imageUrl: 'RammusSquare.png'),
    Champion(id: 'reksai', name: "Rek'Sai", role: 'Jungle', imageUrl: 'RekSaiSquare.png'),
    Champion(id: 'rell', name: 'Rell', role: 'Support', imageUrl: 'Rell.png'),
    Champion(id: 'renata', name: 'Renata Glasc', role: 'Support'),  // Nouveau - pas d'image disponible
    Champion(id: 'renekton', name: 'Renekton', role: 'Top', imageUrl: 'RenektonSquare.png'),
    Champion(id: 'rengar', name: 'Rengar', role: 'Jungle', imageUrl: 'RengarSquare.png'),
    Champion(id: 'riven', name: 'Riven', role: 'Top', imageUrl: 'RivenSquare.png'),
    Champion(id: 'rumble', name: 'Rumble', role: 'Top', imageUrl: 'RumbleSquare.png'),
    Champion(id: 'ryze', name: 'Ryze', role: 'Mid', imageUrl: 'RyzeSquare.png'),
    
    // S
    Champion(id: 'samira', name: 'Samira', role: 'ADC', imageUrl: 'SamiraSquare.png'),
    Champion(id: 'sejuani', name: 'Sejuani', role: 'Jungle', imageUrl: 'SejuaniSquare.png'),
    Champion(id: 'senna', name: 'Senna', role: 'Support', imageUrl: 'SennaSquare.png'),
    Champion(id: 'seraphine', name: 'Seraphine', role: 'Support', imageUrl: 'SeraphineSquare.png'),
    Champion(id: 'sett', name: 'Sett', role: 'Top', imageUrl: 'SettSquare.png'),
    Champion(id: 'shaco', name: 'Shaco', role: 'Jungle', imageUrl: 'ShacoSquare.png'),
    Champion(id: 'shen', name: 'Shen', role: 'Top', imageUrl: 'ShenSquare.png'),
    Champion(id: 'shyvana', name: 'Shyvana', role: 'Jungle', imageUrl: 'ShyvanaSquare.png'),
    Champion(id: 'singed', name: 'Singed', role: 'Top', imageUrl: 'SingedSquare.png'),
    Champion(id: 'sion', name: 'Sion', role: 'Top', imageUrl: 'SionSquare.png'),
    Champion(id: 'sivir', name: 'Sivir', role: 'ADC', imageUrl: 'SivirSquare.png'),
    Champion(id: 'skarner', name: 'Skarner', role: 'Jungle', imageUrl: 'SkarnerSquare.png'),
    Champion(id: 'smolder', name: 'Smolder', role: 'ADC'),  // Nouveau - pas d'image disponible
    Champion(id: 'sona', name: 'Sona', role: 'Support', imageUrl: 'SonaSquare.png'),
    Champion(id: 'soraka', name: 'Soraka', role: 'Support', imageUrl: 'SorakaSquare.png'),
    Champion(id: 'swain', name: 'Swain', role: 'Mid', imageUrl: 'SwainSquare.png'),
    Champion(id: 'sylas', name: 'Sylas', role: 'Mid', imageUrl: 'SylasSquare.png'),
    Champion(id: 'syndra', name: 'Syndra', role: 'Mid', imageUrl: 'SyndraSquare.png'),
    
    // T
    Champion(id: 'tahm_kench', name: 'Tahm Kench', role: 'Top', imageUrl: 'Tahm_KenchSquare.png'),
    Champion(id: 'taliyah', name: 'Taliyah', role: 'Jungle', imageUrl: 'TaliyahSquare.png'),
    Champion(id: 'talon', name: 'Talon', role: 'Mid', imageUrl: 'TalonSquare.png'),
    Champion(id: 'taric', name: 'Taric', role: 'Support', imageUrl: 'TaricSquare.png'),
    Champion(id: 'teemo', name: 'Teemo', role: 'Top', imageUrl: 'TeemoSquare.png'),
    Champion(id: 'thresh', name: 'Thresh', role: 'Support', imageUrl: 'ThreshSquare.png'),
    Champion(id: 'tristana', name: 'Tristana', role: 'ADC', imageUrl: 'TristanaSquare.png'),
    Champion(id: 'trundle', name: 'Trundle', role: 'Top', imageUrl: 'TrundleSquare.png'),
    Champion(id: 'tryndamere', name: 'Tryndamere', role: 'Top', imageUrl: 'TryndamereSquare.png'),
    Champion(id: 'twisted_fate', name: 'Twisted Fate', role: 'Mid', imageUrl: 'Twisted_FateSquare.png'),
    Champion(id: 'twitch', name: 'Twitch', role: 'ADC', imageUrl: 'TwitchSquare.png'),
    
    // U
    Champion(id: 'udyr', name: 'Udyr', role: 'Jungle', imageUrl: 'UdyrSquare.png'),
    Champion(id: 'urgot', name: 'Urgot', role: 'Top', imageUrl: 'UrgotSquare.png'),
    
    // V
    Champion(id: 'varus', name: 'Varus', role: 'ADC', imageUrl: 'VarusSquare.png'),
    Champion(id: 'vayne', name: 'Vayne', role: 'ADC', imageUrl: 'VayneSquare.png'),
    Champion(id: 'veigar', name: 'Veigar', role: 'Mid', imageUrl: 'VeigarSquare.png'),
    Champion(id: 'velkoz', name: "Vel'Koz", role: 'Mid', imageUrl: 'VelKozSquare.png'),
    Champion(id: 'vex', name: 'Vex', role: 'Mid'),  // Nouveau - pas d'image disponible
    Champion(id: 'vi', name: 'Vi', role: 'Jungle', imageUrl: 'ViSquare.png'),
    Champion(id: 'viego', name: 'Viego', role: 'Jungle', imageUrl: 'ViegoSquare.png'),
    Champion(id: 'viktor', name: 'Viktor', role: 'Mid', imageUrl: 'ViktorSquare.png'),
    Champion(id: 'vladimir', name: 'Vladimir', role: 'Mid', imageUrl: 'VladimirSquare.png'),
    Champion(id: 'volibear', name: 'Volibear', role: 'Top', imageUrl: 'VolibearSquare.png'),
    
    // W
    Champion(id: 'warwick', name: 'Warwick', role: 'Jungle', imageUrl: 'WarwickSquare.png'),
    Champion(id: 'wukong', name: 'Wukong', role: 'Jungle', imageUrl: 'WukongSquare.png'),
    
    // X
    Champion(id: 'xayah', name: 'Xayah', role: 'ADC', imageUrl: 'XayahSquare.png'),
    Champion(id: 'xerath', name: 'Xerath', role: 'Mid', imageUrl: 'XerathSquare.png'),
    Champion(id: 'xin_zhao', name: 'Xin Zhao', role: 'Jungle', imageUrl: 'Xin_ZhaoSquare.png'),
    
    // Y
    Champion(id: 'yasuo', name: 'Yasuo', role: 'Mid', imageUrl: 'YasuoSquare.png'),
    Champion(id: 'yone', name: 'Yone', role: 'Mid', imageUrl: 'YoneSquare.png'),
    Champion(id: 'yorick', name: 'Yorick', role: 'Top', imageUrl: 'YorickSquare.png'),
    Champion(id: 'yuumi', name: 'Yuumi', role: 'Support', imageUrl: 'YuumiSquare.png'),
    Champion(id: 'yunara', name: 'Yunara', role: 'ADC'),  // Nouveau - pas d'image disponible
    
    // Z
    Champion(id: 'zac', name: 'Zac', role: 'Jungle', imageUrl: 'ZacSquare.png'),
    Champion(id: 'zed', name: 'Zed', role: 'Mid', imageUrl: 'ZedSquare.png'),
    Champion(id: 'zeri', name: 'Zeri', role: 'ADC'),  // Nouveau - pas d'image disponible
    Champion(id: 'ziggs', name: 'Ziggs', role: 'Mid', imageUrl: 'ZiggsSquare.png'),
    Champion(id: 'zilean', name: 'Zilean', role: 'Support', imageUrl: 'ZileanSquare.png'),
    Champion(id: 'zoe', name: 'Zoe', role: 'Mid', imageUrl: 'ZoeSquare.png'),
    Champion(id: 'zyra', name: 'Zyra', role: 'Support', imageUrl: 'ZyraSquare.png'),
  ];

  /// Récupère tous les champions par rôle
  static List<Champion> getByRole(String role) {
    return all.where((champion) => champion.role == role).toList();
  }

  /// Récupère un champion par son ID
  static Champion? getById(String id) {
    try {
      return all.firstWhere((champion) => champion.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupère tous les rôles disponibles
  static List<String> get roles {
    return all.map((champion) => champion.role).toSet().toList()..sort();
  }

  /// Recherche des champions par nom
  static List<Champion> search(String query) {
    if (query.isEmpty) return all;
    final lowerQuery = query.toLowerCase();
    return all.where((champion) =>
      champion.name.toLowerCase().contains(lowerQuery) ||
      champion.role.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}