
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ingredient_model.dart';

class IngredientResolverService {
  // ═══════════════════════════════════════════════════════════════════════════
  //  HARDCODED ASSET BASELINE (fallback when storage list fails)
  // ═══════════════════════════════════════════════════════════════════════════
  static final Set<String> _hardcodedAssets = {
    "sogan.png", "tazesogan.png", "domates.png", "salca.png", "zeytinyagi.png",
    "tuz.png", "su.png", "kapyabiber.png", "pulbiber.png", "kurutulmusbiber.png",
    "kimyon.png", "kekik.png", "sumak.png", "tarcin.png", "karanfil.png",
    "zerdecal.png", "zencefil.png", "vanilya.png", "baharat.png", "pirinc.png",
    "bulgur.png", "arpasehriye.png", "kurufasulye.png", "fasulye.png", "nohut.png",
    "mercimek.png", "yesilmercimek.png", "tavuk.png", "kiyma.png", "kirmiziet.png",
    "balik.png", "somon.png", "tonbaligi.png", "yogurt.png", "sut.png",
    "peynir.png", "kasar.png", "yumurta.png", "patlican.png", "kabak.png",
    "havuc.png", "morhavuc.png", "kereviz.png", "ispanak.png", "semizotu.png",
    "mantar.png", "marul.png", "morlahana.png", "lahana.png", "brokoli.png",
    "karnibahar.png", "pirasa.png", "salatalik.png", "patates.png", "balkabagi.png",
    "maydanoz.png", "dereotu.png", "nane.png", "tazenane.png", "feslegen.png",
    "biberiye.png", "defneyapragi.png", "avokado.png", "limon.png", "kurukayisi.png",
    "kuruuzum.png", "zeytin.png", "yesilzeytin.png", "yulaf.png", "un.png",
    "seker.png", "susam.png", "bal.png",
    "terayag.png", "sarmisak.png", "kakoa.png", "makrna.png",
    "roka.png", "pancar.png", "pazi.png", "bamya.png", "borulce.png",
    "bezelye.png", "barbunya.png", "kinoa.png", "kuskus.png", "irmik.png",
    "tahin.png", "pekmez.png", "nareksisi.png", "nar.png", "portakal.png",
    "greyfrut.png", "seftali.png", "cilek.png", "visne.png", "yabanmersini.png",
    "armut.png", "ananas.png", "ayva.png", "yesilelma.png",
    "badem.png", "filebadem.png", "ceviz.png", "findik.png", "fistik.png",
    "kaju.png", "kuruyemis.png", "incir.png", "hurma.png",
    "bittercikolata.png", "chia.png", "cajun.png",
    "adacayi.png", "yenibahar.png", "yildizanason.png", "isot.png",
    "kori.png", "kisnis.png", "karabiber.png",
    "krema.png", "kaymak.png", "rokfor.png",
    "ketcap.png", "panko.png", "pastirma.png", "lavas.png", "iskembe.png",
    "keten.png", "karabugday.png", "bugday.png", "kabartmatozu.png",
    "kornisontursu.png", "hashas.png", "ceridomates.png",
    "bruksellahanasi.png", "enginar.png",
  };

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIVE ASSET SET + NORMALIZED ASSET INDEX
  // ═══════════════════════════════════════════════════════════════════════════
  static Set<String> _availableAssets = {};
  static bool _isInitialized = false;

  /// normalizedKey -> actual filename (e.g. "zeytinyagi" -> "zeytinyagi.png")
  static Map<String, String> _assetIndex = {};

  static Future<void> init() async {
    if (_isInitialized) return;

    _availableAssets = Set.from(_hardcodedAssets);
    _isInitialized = true;

    try {
      final objects = await Supabase.instance.client.storage
          .from('recipe-assets')
          .list(path: 'ingredients');

      final fetched = objects.map((e) => e.name.toLowerCase()).toSet();
      if (fetched.isNotEmpty) {
        _availableAssets = fetched;
        debugPrint('IngredientResolverService: Loaded ${fetched.length} assets from live storage.');
      } else {
        debugPrint('IngredientResolverService: Storage list returned empty. Using hardcoded baseline.');
      }
    } catch (e) {
      debugPrint('IngredientResolverService: Error fetching storage assets (using baseline fallback): $e');
    }

    // Build normalized asset index from whatever set we have
    _buildAssetIndex();
  }

  static void _buildAssetIndex() {
    _assetIndex = {};
    for (final fileName in _availableAssets) {
      // Strip extension to get the raw key
      final key = fileName.replaceAll(RegExp(r'\.(png|jpg|jpeg|webp)$'), '');
      _assetIndex[key] = fileName;
    }
    debugPrint('IngredientResolverService: Built asset index with ${_assetIndex.length} entries.');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  NORMALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Normalize Turkish text: lowercase, strip diacritics, remove punctuation.
  /// Preserves spaces between words.
  static String _normalizeTurkishKeepSpaces(String text) {
    String s = text.toLowerCase().trim();
    s = s.replaceAll('ç', 'c')
         .replaceAll('ğ', 'g')
         .replaceAll('ı', 'i')
         .replaceAll('ö', 'o')
         .replaceAll('ş', 's')
         .replaceAll('ü', 'u')
         .replaceAll('â', 'a')
         .replaceAll('î', 'i')
         .replaceAll('û', 'u');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s.trim();
  }



  // Public alias kept for backward compatibility
  static String normalizeTurkish(String text) => _normalizeTurkishKeepSpaces(text);

  // ═══════════════════════════════════════════════════════════════════════════
  //  CLEANING: remove quantities, units, prep words, brand names, parens
  // ═══════════════════════════════════════════════════════════════════════════

  static const Set<String> _quantityUnits = {
    'adet', 'dis', 'gram', 'gr', 'g', 'kg', 'ml', 'litre', 'lt',
    'fincan', 'demet', 'tutam', 'kilogram', 'paket', 'dilim', 'avuc',
    'kase', 'damla', 'bardak', 'kasik', 'silme', 'tepeleme',
    'porsiyon', 'bag', 'bagi', 'yaprak', 'sap', 'dal', 'tane',
  };

  static const Set<String> _prepWords = {
    'dogranmis', 'rendelenmis', 'haslanmis', 'kavrulmus', 'firinlanmis',
    'kiymis', 'kiyilmis', 'ince', 'iri', 'kucuk', 'buyuk', 'kabuksuz',
    'ayiklanmis', 'yikanmis', 'kup', 'pismis', 'kurutulmus', 'sogutulmus',
    'eritilmis', 'cekilmis', 'ezilmis', 'yarim', 'ceyrek',
  };

  static const Set<String> _brandNames = {
    'sutas', 'pinar', 'icim', 'torku', 'sek', 'tat', 'tamek',
  };

  static const List<String> _multiWordUnits = [
    'yemek kasigi', 'tatli kasigi', 'cay kasigi', 'su bardagi',
    'cay bardagi', 'kahve fincani', 'goz karari', 'istege bagli',
    'aldigi kadar', 'bir tutam', 'ince kiyilmis', 'buyuk boy',
    'orta boy', 'kucuk boy',
  ];

  /// Strip quantities, units, prep words, brands, parentheses from ingredient text.
  /// Returns cleaned words as a list (still with spaces).
  static String _stripToCoreName(String text) {
    String s = _normalizeTurkishKeepSpaces(text);

    // Remove parenthetical content
    s = s.replaceAll(RegExp(r'\([^)]*\)'), ' ');

    // Remove numbers and fractions
    s = s.replaceAll(RegExp(r'[0-9]+[/.,]?[0-9]*'), ' ');

    // Remove multi-word units (must come before single-word)
    for (final mw in _multiWordUnits) {
      s = s.replaceAll(mw, ' ');
    }

    // Remove single-word units, prep words, and brand names
    final words = s.split(RegExp(r'\s+'));
    final filtered = words.where((w) =>
      w.isNotEmpty &&
      !_quantityUnits.contains(w) &&
      !_prepWords.contains(w) &&
      !_brandNames.contains(w)
    ).toList();

    return filtered.join(' ').trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  ALIAS MAP: normalized key -> normalized asset key (no .png)
  // ═══════════════════════════════════════════════════════════════════════════
  static const Map<String, String> _aliasMap = {
    // === YAĞ ===
    'zeytinyag': 'zeytinyagi',
    'zeytinyagi': 'zeytinyagi',
    'zeytin yagi': 'zeytinyagi',
    'sizma zeytinyagi': 'zeytinyagi',
    'sivi yag': 'yag',
    'siviyag': 'yag',
    'aycicegi yagi': 'yag',
    'aycicek yagi': 'yag',
    'ic yagi': 'yag',
    'tereyagi': 'terayag',
    'tereyag': 'terayag',

    // === BAL KABAĞI (prevent "bal" match) ===
    'bal kabagi': 'balkabagi',
    'balkabagi': 'balkabagi',

    // === DENİZ ÜRÜNLERİ ===
    'somon': 'somon',
    'somon fileto': 'somon',
    'mezgit': 'balik',
    'istavrit': 'balik',
    'palamut': 'balik',
    'levrek': 'balik',
    'cipura': 'balik',
    'hamsi': 'balik',
    'uskumru': 'balik',
    'karides': 'karides',
    'midye': 'midye',
    'misye': 'midye',
    'ahtapot': 'ahtapot',
    'kalamar': 'kalamar',
    'ton baligi': 'tonbaligi',

    // === SOSLAR ===
    'soya sosu': 'soyasoyu',
    'soya sos': 'soyasoyu',
    'soay sosu': 'soyasoyu',
    'soyasosu': 'soyasoyu',
    'hardal': 'hardal',
    'biber salcasi': 'salca',
    'domates salcasi': 'salca',
    'salca': 'salca',
    'nar eksisi': 'nareksisi',
    'ketcap': 'ketcap',
    'mayonez': 'mayonez',

    // === EKMEK / YUFKA / TAHIL ===
    'bayat ekmek': 'ekmek',
    'eksi mayali ekmek': 'ekmek',
    'ekmek': 'ekmek',
    'ramazan pidesi': 'pide',
    'pide': 'pide',
    'baklava yufkasi': 'yufka',
    'pismis yufka': 'yufka',
    'yufka': 'yufka',
    'ekmek kirintisi': 'panko',
    'panko': 'panko',
    'sehriye': 'arpasehriye',
    'arpa sehriye': 'arpasehriye',
    'arpasehriye': 'arpasehriye',
    'makarna': 'makrna',
    'pirinc': 'pirinc',
    'bulgur': 'bulgur',

    // === BAHARAT / OT ===
    'corek otu': 'corekotu',
    'corekotu': 'corekotu',
    'kuru reyhan': 'kurureyhan',
    'kurutulmus reyhan': 'kurureyhan',
    'reyhan': 'kurureyhan',
    'tarhun': 'tarhunotu',
    'tarhun otu': 'tarhunotu',
    'taze kisnis': 'kisnis',
    'kisnis': 'kisnis',
    'kakao': 'kakoa',
    'kakao tozu': 'kakoa',
    'masala': 'masala',
    'kanun baharati': 'kanunbaharati',

    // === SEBZE / MEYVE ===
    'kereviz sapi': 'kereviz',
    'pazi yapragi': 'pazi',
    'kultur mantari': 'mantar',
    'istiridye mantari': 'istiridyemantari',
    'mandalina suyu': 'mandalina',
    'limon suyu': 'limon',
    'icme suyu': 'su',
    'frenk sogani': 'tazesogan',
    'taze sogan': 'tazesogan',
    'ceri domates': 'ceridomates',
    'ceridomates': 'ceridomates',

    // === ET / SAKATAT ===
    'dana cigeri': 'ciger',
    'tavuk cigeri': 'ciger',
    'ciger': 'ciger',
    'dana eti': 'kirmiziet',
    'kusbasi dana eti': 'kirmiziet',
    'kiyma': 'kiyma',
    'sucuk': 'sucuk',
    'dogranmis sucuk': 'sucuk',
    'sucuk dilimi': 'sucuk',
    'sosis': 'sosis',
    'pastirma': 'pastirma',
    'tavuk': 'tavuk',

    // === KURUYEMİŞ ===
    'file badem': 'badem',
    'filebadem': 'filebadem',
    'muskat cevizi': 'muskatcevizi',
    'rendelenmis muskat cevizi': 'muskatcevizi',
    'kus uzumu': 'kusuzumu',
    'kusuzumu': 'kusuzumu',
    'kuru uzum': 'kuruuzum',
    'kuru kayisi': 'kurukayisi',
    'kayisi': 'kurukayisi',

    // === TUZ / ŞARAP ===
    'kaya tuzu': 'tuz',
    'deniz tuzu': 'tuz',
    'tuz': 'tuz',
    'kirmizi sarap': 'kirmizisarap',
    'beyaz sarap': 'beyazsarap',

    // === BİBER ===
    'carliston biber': 'yesilbiber',
    'carliston': 'yesilbiber',
    'yesil biber': 'yesilbiber',
    'yesil sivri biber': 'yesilbiber',
    'sivri biber': 'yesilbiber',
    'kirmizi biber': 'kapyabiber',
    'kapya biber': 'kapyabiber',
    'kirmizi kapya biber': 'kapyabiber',
    'dolmalik biber': 'dolmalikbiber',
    'dolmalik kirmizi biber': 'dolmalikbiber',
    'kaliforniya biberi': 'dolmalikbiber',
    'sari kaliforniya biberi': 'dolmalikbiber',
    'toz kirmizi biber': 'tozbiber',
    'kirmizi toz biber': 'tozbiber',
    'toz biber': 'tozbiber',
    'sili biberi': 'tozbiber',
    'chili biber': 'tozbiber',
    'pul biber': 'pulbiber',
    'kirmizi pul biber': 'pulbiber',

    // === ZEYTİN (must be separate from zeytinyağı) ===
    'zeytin': 'zeytin',
    'yesil zeytin': 'yesilzeytin',
    'yesil kokteyl zeytin': 'yesilzeytin',

    // === FISTIK / ÇEKİRDEK ===
    'dolmalik fistik': 'dolmalikfistik',
    'cam fistigi': 'dolmalikfistik',
    'fistik': 'fistik',
    'ceviz': 'ceviz',
    'badem': 'badem',
    'findik': 'findik',
    'kaju': 'kaju',
    'cekirdek ici': 'cekirdekici',

    // === SİRKE ===
    'sirke': 'sirke',
    'elma sirkesi': 'sirke',
    'uzum sirkesi': 'sirke',
    'beyaz sirke': 'sirke',

    // === PEYNİR / SÜT / KREMA ===
    'sivi krema': 'krema',
    'krema': 'krema',
    'suzme peynir': 'beyazpeynir',
    'beyaz peynir': 'beyazpeynir',
    'peynir': 'peynir',
    'yogurt': 'yogurt',
    'suzme yogurt': 'yogurt',
    'sut': 'sut',
    'ayran': 'ayran',

    // === KABARTICI / MAYA / NİŞASTA ===
    'karbonat': 'karbonat',
    'kabartma tozu': 'kabartmatozu',
    'maya': 'kurumaya',
    'kuru maya': 'kurumaya',
    'instant maya': 'kurumaya',
    'nisasta': 'nisasta',
    'misir nisastasi': 'nisasta',

    // === MISIR ===
    'misir gevregi': 'granola',
    'misir unu': 'misirunu',
    'misir': 'misir',
    'konserve misir': 'misir',

    // === DİĞER TEMEL MALZEMELER ===
    'bal': 'bal',
    'seker': 'seker',
    'su': 'su',
    'un': 'un',
    'yumurta': 'yumurta',
    'susam': 'susam',
    'sogan': 'sogan',
    'sarmisak': 'sarmisak',
    'domates': 'domates',
    'domates konservesi': 'domates',
    'patlican': 'patlican',
    'kabak': 'kabak',
    'ispanak': 'ispanak',
    'mantar': 'mantar',
    'nane': 'nane',
    'maydanoz': 'maydanoz',
    'dereotu': 'dereotu',
    'avokado': 'avokado',
    'limon': 'limon',
    'havuc': 'havuc',
    'patates': 'patates',
    'karabiber': 'karabiber',
    'kimyon': 'kimyon',
    'kekik': 'kekik',
    'elma': 'yesilelma',
    'muz': 'muz',
    'hindistan cevizi sekeri': 'hindistancevizisekeri',

    // === BAKLİYAT ===
    'mas fasulyesi': 'masfasulyesi',
    'fasulye': 'fasulye',
    'kuru fasulye': 'kurufasulye',
    'bezelye': 'bezelye',
    'sultani bezelye': 'bezelye',
    'kuskonmaz': 'kuskonmaz',
    'nohut': 'nohut',
    'mercimek': 'mercimek',

    // === MEYVE ===
    'ahududu': 'ahududu',
    'incir': 'incir',
    'hurma': 'hurma',
    'nar': 'nar',
    'portakal': 'portakal',
    'mandalina': 'mandalina',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  //  CONTROLLED CATEGORY FALLBACK
  // ═══════════════════════════════════════════════════════════════════════════
  static const Map<String, String> _categoryFallbacks = {
    // Poultry
    'tavuk': 'tavuk', 'baget': 'tavuk', 'hindi': 'tavuk', 'but': 'tavuk',

    // Fish (NOT karides, midye, kalamar, ahtapot)
    'balik': 'balik', 'levrek': 'balik', 'cipura': 'balik',
    'hamsi': 'balik', 'uskumru': 'balik', 'istavrit': 'balik', 'palamut': 'balik',

    // Red meat
    'dana': 'kirmiziet', 'kuzu': 'kirmiziet', 'biftek': 'kirmiziet',
    'bonfile': 'kirmiziet', 'antrikot': 'kirmiziet', 'kontrfile': 'kirmiziet',
    'nuar': 'kirmiziet', 'rosto': 'kirmiziet', 'kusbasi': 'kirmiziet',
    'pirzola': 'kirmiziet', 'incik': 'kirmiziet', 'kaburga': 'kirmiziet',
    'kavurma': 'kirmiziet',

    // Cheese
    'peynir': 'peynir', 'kasar': 'peynir', 'lor': 'peynir',
    'mozzarella': 'peynir', 'cheddar': 'peynir', 'labne': 'peynir',
    'krempeynir': 'peynir',

    // Berry
    'bogurtlen': 'cilek', 'frambuaz': 'cilek', 'karadut': 'cilek',

    // Spice/herb generic
    'baharat': 'baharat',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  //  SAFE FALLBACK FOR MISSING ASSETS
  // ═══════════════════════════════════════════════════════════════════════════
  static const Map<String, String> _missingAssetFallbacks = {
    'milfoy': 'yufka',
    'ahududu': 'cilek',
    'yag': 'terayag',
    'kirmizipulbiber': 'pulbiber',
    'tozbiber': 'pulbiber',
    'nisasta': 'un',
    'soyasoyu': 'soya',
    'yesilbiber': 'dolmalikbiber',
    'muskatcevizi': 'ceviz',
    'istiridyemantari': 'mantar',
    'masala': 'baharat',
    'kanunbaharati': 'baharat',
    'kirmizisarap': 'su',
    'beyazsarap': 'su',
    'tarhunotu': 'kekik',
    'kurureyhan': 'kekik',
    'corekotu': 'susam',
    'ciger': 'kirmiziet',
    'sosis': 'sucuk',
    'mirin': 'su',
    'sirke': 'su',
    'karbonat': 'kabartmatozu',
    'hindistancevizisekeri': 'seker',
    'soya': 'su',
    'hardal': 'ketcap',
    'granola': 'yulaf',
    'beyazpeynir': 'peynir',
    'pide': 'ekmek',
    'kurumaya': 'un',
    'cekirdekici': 'fistik',
    'misirunu': 'un',
    'dolmalikfistik': 'fistik',
    'mandalina': 'portakal',
  };

  // ═══════════════════════════════════════════════════════════════════════════
  //  MAIN RESOLVER
  // ═══════════════════════════════════════════════════════════════════════════

  /// Main resolver: raw ingredient name → Storage file name
  static String resolveIngredientFileName(String raw) {
    // 1. Clean: remove quantities, units, prep words, brands
    final coreName = _stripToCoreName(raw);

    // 2. Normalize with spaces (for n-gram) and without spaces (for asset key)
    final normSpaces = _normalizeTurkishKeepSpaces(coreName);
    final normKey = normSpaces.replaceAll(' ', '');
    final tokens = normSpaces.split(' ').where((t) => t.isNotEmpty).toList();

    String? resolvedAssetKey;
    String matchType = '';

    // ── STEP 1: Exact full-key match in asset index ──
    if (_assetIndex.containsKey(normKey)) {
      resolvedAssetKey = normKey;
      matchType = 'exact';
    }

    // ── STEP 2: Exact full-phrase alias match ──
    if (resolvedAssetKey == null && _aliasMap.containsKey(normSpaces)) {
      resolvedAssetKey = _aliasMap[normSpaces]!;
      matchType = 'alias';
    }
    // Also try without spaces in alias
    if (resolvedAssetKey == null && _aliasMap.containsKey(normKey)) {
      resolvedAssetKey = _aliasMap[normKey]!;
      matchType = 'alias';
    }

    // ── STEP 3: N-gram match (longest phrase first) ──
    if (resolvedAssetKey == null && tokens.length > 1) {
      resolvedAssetKey = _findNGramMatch(tokens);
      if (resolvedAssetKey != null) matchType = 'ngram';
    }

    // ── STEP 4: Single token match (longest token first, skip dangerous short words) ──
    if (resolvedAssetKey == null) {
      // Sort tokens by length descending to prefer longer/more specific tokens
      final sortedTokens = List<String>.from(tokens)..sort((a, b) => b.length.compareTo(a.length));
      for (final token in sortedTokens) {
        if (token.length < 2) continue; // Skip single chars

        // Check alias map first
        if (_aliasMap.containsKey(token)) {
          resolvedAssetKey = _aliasMap[token]!;
          matchType = 'token_alias';
          break;
        }
        // Then check asset index directly
        if (_assetIndex.containsKey(token)) {
          resolvedAssetKey = token;
          matchType = 'token_asset';
          break;
        }
      }
    }

    // ── STEP 5: Category fallback ──
    if (resolvedAssetKey == null) {
      for (final token in tokens) {
        if (_categoryFallbacks.containsKey(token)) {
          resolvedAssetKey = _categoryFallbacks[token]!;
          matchType = 'category_fallback';
          break;
        }
      }
      // Also try "et" as whole word
      if (resolvedAssetKey == null && tokens.contains('et')) {
        resolvedAssetKey = 'kirmiziet';
        matchType = 'category_fallback';
      }
    }

    // ── STEP 6: Resolve asset key to actual file ──
    String resolvedFile;
    bool fallbackUsed = false;

    if (resolvedAssetKey != null) {
      // Check if the resolved key exists in asset index
      if (_assetIndex.containsKey(resolvedAssetKey)) {
        resolvedFile = _assetIndex[resolvedAssetKey]!;
      } else {
        // Try missing asset fallback chain
        final fallbackKey = _findFallbackChain(resolvedAssetKey);
        if (fallbackKey != null && _assetIndex.containsKey(fallbackKey)) {
          resolvedFile = _assetIndex[fallbackKey]!;
          matchType = 'safe_fallback';
          fallbackUsed = true;
        } else {
          resolvedFile = 'default_ingredient.png';
          matchType = 'default';
          fallbackUsed = true;
        }
      }
    } else {
      resolvedFile = 'default_ingredient.png';
      matchType = 'default';
      fallbackUsed = true;
    }

    // Debug logging
    debugPrint('Ingredient image resolve:');
    debugPrint('- originalName: "$raw"');
    debugPrint('- cleanName: "$coreName"');
    debugPrint('- normalizedFullKey: "$normKey"');
    debugPrint('- tokens: $tokens');
    debugPrint('- matchedAliasKey: "${resolvedAssetKey ?? 'none'}"');
    debugPrint('- chosenAssetKey: "$resolvedFile"');
    debugPrint('- chosenAssetPath: "${buildIngredientImageUrl(resolvedFile)}"');
    debugPrint('- matchType: $matchType');
    debugPrint('- fallbackUsed: $fallbackUsed');
    debugPrint('- assetExists: ${_assetIndex.containsKey(resolvedAssetKey ?? '')}');

    return resolvedFile;
  }

  /// N-gram matching: for tokens [a, b, c] try "abc", "ab", "bc", "a", "b", "c"
  /// Always longest first. Checks both asset index and alias map.
  static String? _findNGramMatch(List<String> tokens) {
    final n = tokens.length;

    // From full length down to 2 (single tokens handled separately)
    for (int size = n; size >= 2; size--) {
      for (int start = 0; start <= n - size; start++) {
        final phraseTokens = tokens.sublist(start, start + size);
        final phraseWithSpaces = phraseTokens.join(' ');
        final phraseKey = phraseTokens.join('');

        // Check asset index with joined key
        if (_assetIndex.containsKey(phraseKey)) {
          return phraseKey;
        }

        // Check alias map with spaces
        if (_aliasMap.containsKey(phraseWithSpaces)) {
          return _aliasMap[phraseWithSpaces]!;
        }

        // Check alias map without spaces
        if (_aliasMap.containsKey(phraseKey)) {
          return _aliasMap[phraseKey]!;
        }
      }
    }

    return null;
  }

  /// Walk fallback chain to find existing asset
  static String? _findFallbackChain(String key) {
    String current = key;
    final visited = <String>{};

    while (_missingAssetFallbacks.containsKey(current) && !visited.contains(current)) {
      visited.add(current);
      current = _missingAssetFallbacks[current]!;
      if (_assetIndex.containsKey(current)) {
        return current;
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PUBLIC API (unchanged signatures)
  // ═══════════════════════════════════════════════════════════════════════════

  static String buildIngredientImageUrl(String fileName) {
    if (fileName == 'default_ingredient.png') {
      return 'default_ingredient.png';
    }
    return Supabase.instance.client.storage
        .from('recipe-assets')
        .getPublicUrl('ingredients/$fileName');
  }

  /// Entry point to process ingredients for display, taking exactly 6 items.
  static List<IngredientModel> getDisplayIngredients(Map<String, dynamic> rawRecipe, String fallbackTitle, String recipeId) {
    List<IngredientModel> parsed = parseIngredientsFromRecipe(rawRecipe);

    if (parsed.isEmpty) {
      parsed = _fallbackFromTitle(fallbackTitle);
    }

    List<IngredientModel> filtered = [];
    List<String> removedGroups = [];
    List<String> removedObjects = [];

    for (var ing in parsed) {
      final nameStr = ing.name;

      // [object Object] cleanup
      if (nameStr.contains('[object Object]') || nameStr.contains('object Object') || nameStr.contains('Object')) {
        removedObjects.add(nameStr);
        continue;
      }

      final nameLower = nameStr.toLowerCase().trim();

      if (isGroupLabel(nameLower)) {
        removedGroups.add(nameStr);
        continue;
      }
      if (nameStr.trim().isEmpty) continue;

      // Duplicate check based on resolved file name
      final fileName = resolveIngredientFileName(nameStr);
      if (filtered.any((e) => resolveIngredientFileName(e.name) == fileName)) continue;

      filtered.add(ing);
    }

    // Limit to 6
    final finalIngredients = filtered.take(6).toList();

    List<String> resolvedFilenames = [];
    List<String> storageUrls = [];

    // Populate the imageUrl for the widget
    for (int i = 0; i < finalIngredients.length; i++) {
      final fileName = resolveIngredientFileName(finalIngredients[i].name);
      final url = buildIngredientImageUrl(fileName);

      resolvedFilenames.add(fileName);
      storageUrls.add(url);

      // Update model with the correct resolved URL and cleaned display name
      finalIngredients[i] = finalIngredients[i].copyWith(
        name: cleanIngredientName(finalIngredients[i].name),
        imageUrl: url,
      );
    }

    if (finalIngredients.isEmpty) {
      finalIngredients.add(const IngredientModel(
        name: 'Malzeme bilgisi hazırlanıyor',
        amount: '',
        calories: 0,
      ));
    }

    debugPrint('RecipeShowScreen [DEBUG] recipe id: $recipeId');
    debugPrint('RecipeShowScreen [DEBUG] recipe title: $fallbackTitle');
    debugPrint('RecipeShowScreen [DEBUG] ingredients_text raw: ${rawRecipe['ingredients_text']}');
    debugPrint('RecipeShowScreen [DEBUG] parsed ingredients from ingredients_text: ${parsed.map((e) => e.name).toList()}');
    debugPrint('RecipeShowScreen [DEBUG] removed group labels: $removedGroups');
    debugPrint('RecipeShowScreen [DEBUG] removed object items: $removedObjects');
    debugPrint('RecipeShowScreen [DEBUG] final ingredients: ${finalIngredients.map((e) => e.name).toList()}');
    debugPrint('RecipeShowScreen [DEBUG] resolved image filenames: $resolvedFilenames');
    debugPrint('RecipeShowScreen [DEBUG] storage image urls: $storageUrls');

    return finalIngredients;
  }

  static List<IngredientModel> parseIngredientsFromRecipe(Map<String, dynamic> raw) {
    final textVal = raw['ingredients_text']?.toString() ?? '';
    if (textVal.isNotEmpty) {
      final parsed = parseIngredientsText(textVal);
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }
    return [];
  }

  static List<IngredientModel> parseIngredientsText(String text) {
    List<IngredientModel> result = [];
    final parts = text.split(',');
    for (var part in parts) {
      final cleaned = part.trim();
      if (cleaned.isNotEmpty && !cleaned.toLowerCase().contains('bulunamadı')) {
        result.add(IngredientModel(
          name: cleaned,
          amount: '1 porsiyon',
          calories: 0,
        ));
      }
    }
    return result;
  }

  static bool isGroupLabel(String textLower) {
    final t = textLower.trim();
    if (t.endsWith(' için') || t.contains(' için ') || t.endsWith(' icin') || t.contains(' icin ')) {
      return true;
    }
    final blockedPhrases = [
      'çorba için', 'salata için', 'köftesi için', 'terbiyesi için', 'sosu için',
      'sos için', 'üzeri için', 'iç harcı için', 'iç harç için', 'iç malzemesi için',
      'servis için', 'sunum için', 'hamuru için', 'kızartmak için', 'marine için',
      'marinasyon için', 'garnitür için', 'ara kat için', 'üzeri', 'içi için',
      'isteğe bağlı', 'malzemeler', 'ana malzemeler', 'harcı için', 'bulunamadı',
      'şerbeti için', 'sandviç için'
    ];
    for (var phrase in blockedPhrases) {
      if (t == phrase || t.contains(phrase)) return true;
    }
    return false;
  }

  static String cleanIngredientName(String raw) {
    String s = ' ${raw.toLowerCase().trim()} ';
    s = s.replaceAll(RegExp(r'\(.*?\)'), ' ');

    final multiWordPhrases = [
      'yemek kaşığı', 'tatlı kaşığı', 'çay kaşığı', 'su bardağı', 'çay bardağı',
      'yemek kasigi', 'tatli kasigi', 'cay kasigi', 'su bardagi', 'cay bardagi',
      'göz kararı', 'isteğe bağlı', 'aldığı kadar', 'bir tutam', 'ince kıyılmış',
      'büyük boy', 'orta boy', 'küçük boy', 'kahve fincanı', 'kahve fincani'
    ];

    s = s.replaceAll(RegExp(r'[0-9\.,/]+'), ' ');

    for (var m in multiWordPhrases) {
      s = s.replaceAll(' $m ', ' ');
    }

    final singleWordPhrases = {
      'adet', 'diş', 'gram', 'gr', 'g', 'kg', 'ml', 'litre',
      'yarım', 'çeyrek', 'doğranmış', 'rendelenmiş', 'haşlanmış',
      'kavrulmuş', 'fırınlanmış', 'fincan', 'demet', 'tutam',
      'kilogram', 'paket', 'dilim', 'avuç', 'kase', 'damla',
      'bardak', 'kaşık', 'kurutulmuş', 'silme', 'tepeleme',
      'ayıklanmış', 'yıkanmış', 'porsiyon', 'bağ', 'bag',
      'sütaş', 'sutas', 'pınar', 'pinar', 'içim', 'icim', 'torku', 'sek'
    };

    final words = s.split(RegExp(r'\s+'));
    final filteredWords = words.where((w) => w.isNotEmpty && !singleWordPhrases.contains(w)).toList();

    String finalName = filteredWords.join(' ').trim();
    if (finalName.isEmpty) return raw;

    return finalName[0].toUpperCase() + finalName.substring(1);
  }

  static List<IngredientModel> _fallbackFromTitle(String title) {
    final titleLower = title.toLowerCase();
    List<IngredientModel> fallback = [];

    final fallbackItems = {
      'avokado': 'Avokado',
      'peynir': 'Peynir',
      'domates': 'Domates',
      'tavuk': 'Tavuk',
      'mantar': 'Mantar',
      'patlıcan': 'Patlıcan',
      'patlican': 'Patlıcan',
      'pirinç': 'Pirinç',
      'pirinc': 'Pirinç',
      'soğan': 'Soğan',
      'sogan': 'Soğan',
      'sarımsak': 'Sarımsak',
      'sarimsak': 'Sarımsak',
      'kabak': 'Kabak',
      'havuç': 'Havuç',
      'havuc': 'Havuç',
      'patates': 'Patates',
      'ıspanak': 'Ispanak',
      'ispanak': 'Ispanak',
      'somon': 'Somon',
      'balık': 'Balık',
      'balik': 'Balık',
      'tereyağı': 'Tereyağı',
      'tereyag': 'Tereyağı',
      'zeytinyağı': 'Zeytinyağı',
      'zeytinyagi': 'Zeytinyağı',
    };

    fallbackItems.forEach((keyword, displayName) {
      if (titleLower.contains(keyword)) {
        if (!fallback.any((e) => e.name.toLowerCase() == displayName.toLowerCase())) {
          fallback.add(IngredientModel(name: displayName, amount: '1 porsiyon', calories: 0));
        }
      }
    });

    return fallback;
  }
}
