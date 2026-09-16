import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/catalog.dart';
import '../models/quote.dart';
import '../services/github_source.dart';
import '../services/storage_service.dart';

/// Loads the bundled catalog (`assets/data/seed_catalog.json`) and the daily
/// quotes, then keeps them fresh through the same GitHub sync path as taunts.
class CatalogRepository {
  CatalogRepository({
    required GithubDatasetSource source,
    required StorageService storage,
  })  : _source = source,
        _storage = storage;

  final GithubDatasetSource _source;
  final StorageService _storage;

  SeedCatalog _catalog = SeedCatalog.empty;
  QuoteDataset _quotes = const QuoteDataset(quotes: Quote.fallback);
  bool _loaded = false;

  SeedCatalog get catalog => _catalog;
  QuoteDataset get quotes => _quotes;
  bool get isLoaded => _loaded;

  bool get isEmpty => _catalog == SeedCatalog.empty;

  Future<void> load() async {
    if (_loaded) return;
    _catalog = await _loadCatalog();
    _quotes = await _loadQuotes();
    _loaded = true;
  }

  Future<SeedCatalog> _loadCatalog() async {
    try {
      final String raw = await rootBundle.loadString('assets/data/seed_catalog.json');
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final SeedCatalog parsed = SeedCatalog.fromJson(decoded);
        if (parsed.features.isNotEmpty) return parsed;
      }
    } catch (e) {
      debugPrint('TauntBuddy: seed catalog unavailable ($e)');
    }
    return SeedCatalog.fallback;
  }

  Future<QuoteDataset> _loadQuotes() async {
    try {
      final String raw = await rootBundle.loadString('assets/data/quotes.json');
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final QuoteDataset parsed = QuoteDataset.fromJson(decoded);
        if (!parsed.isEmpty) return parsed;
      }
    } catch (e) {
      debugPrint('TauntBuddy: bundled quotes unavailable ($e)');
    }

    final Map<String, dynamic>? cached = _storage.readQuoteCache();
    if (cached != null) {
      final QuoteDataset parsed = QuoteDataset.fromJson(cached, fromRemote: true);
      if (!parsed.isEmpty) return parsed;
    }
    return const QuoteDataset(quotes: Quote.fallback);
  }

  /// Refreshes quotes from GitHub (decorative — failures are non-fatal).
  Future<SyncResult> syncQuotes(String url) async {
    final (QuoteDataset?, SyncResult) result = await _source.fetchQuotes(url);
    final QuoteDataset? remote = result.$1;
    if (remote != null && !remote.isEmpty) {
      _quotes = remote;
      await _storage.writeQuoteCache(<String, dynamic>{
        'schemaVersion': 1,
        'updatedAt': remote.updatedAt,
        'quotes': remote.quotes.map((Quote q) => q.toJson()).toList(growable: false),
      });
    }
    return result.$2;
  }

  /// Today's deterministic quote.
  Quote get quoteOfTheDay => _quotes.forDay(DateTime.now());

  List<FeatureCard> get features => _catalog.features;
  List<BadgeDefinition> get badges => _catalog.badges;
  List<LevelDefinition> get levels => _catalog.levels;
  List<Course> get courses => _catalog.courses;
  List<StudyCircle> get circles => _catalog.circles;
  List<LeaderboardEntry> get leaderboard => _catalog.leaderboard;
  List<DhyanTechnique> get dhyanTechniques => _catalog.dhyanTechniques;
  List<PlannerTemplate> get plannerTemplates => _catalog.plannerTemplates;
  List<KavachProfile> get kavachProfiles => _catalog.kavachProfiles;
  List<TimelineBlock> get timelineBlocks => _catalog.timelineBlocks;

  FeatureCard? featureById(String id) {
    for (final FeatureCard feature in features) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  /// Which level the user is on for a given lifetime focus total.
  LevelDefinition levelFor(int focusMinutes) {
    LevelDefinition current = levels.isEmpty
        ? const LevelDefinition(level: 1, title: 'Soja Beta', minFocusMinutes: 0, accent: 'grey')
        : levels.first;
    for (final LevelDefinition level in levels) {
      if (focusMinutes >= level.minFocusMinutes) current = level;
    }
    return current;
  }

  LevelDefinition? nextLevelFor(int focusMinutes) {
    for (final LevelDefinition level in levels) {
      if (focusMinutes < level.minFocusMinutes) return level;
    }
    return null;
  }
}
