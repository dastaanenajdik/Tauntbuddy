import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/taunt.dart';
import '../services/ifallertzia_source.dart';
import '../services/storage_service.dart';

/// Owns the taunt dataset: bundled asset → optional ifallertzia server
/// sync → in-memory rotation memory.
///
/// The app must never be left without taunts, so there are three safety nets:
/// 1. `assets/data/taunts.json` (the canonical dataset, validated by CI),
/// 2. the last successful ifallertzia server download cached in preferences,
/// 3. [_emergencyPack] compiled into the binary.
class TauntRepository {
  TauntRepository({
    required IfallertziaDatasetSource source,
    required StorageService storage,
  })  : _source = source,
        _storage = storage;

  final IfallertziaDatasetSource _source;
  final StorageService _storage;

  TauntDataset _dataset = TauntDataset.empty;
  Set<String> _favourites = <String>{};
  Set<String> _seen = <String>{};
  SyncResult _lastSync = SyncResult.skipped('Not synced yet.');
  bool _loaded = false;

  TauntDataset get dataset => _dataset;
  List<Taunt> get all => _dataset.all;
  int get count => _dataset.length;
  Set<String> get favouriteIds => _favourites;
  Set<String> get seenIds => _seen;
  SyncResult get lastSync => _lastSync;
  bool get isLoaded => _loaded;
  String? get updatedAt => _dataset.updatedAt;

  List<Taunt> get favourites =>
      all.where((Taunt t) => _favourites.contains(t.id)).toList(growable: false);

  List<TauntPack> get packs => _dataset.packs;

  /// Taunts compiled into the app as the final safety net.
  static const List<Taunt> _emergencyPack = <Taunt>[
    Taunt(
      id: 'tb-emergency-001',
      text: 'Assignment pending hai aur tu Instagram pe active. Wah, priorities! 😭',
      category: 'procrastination',
      trigger: TauntTrigger.idle,
      severity: 2,
      tags: <String>['assignment'],
    ),
    Taunt(
      id: 'tb-emergency-002',
      text: 'Deadline kal hai. Tera "kal karunga" finally kab aayega? 💀',
      category: 'procrastination',
      trigger: TauntTrigger.goalMissed,
      severity: 3,
      tags: <String>['deadline'],
    ),
    Taunt(
      id: 'tb-emergency-003',
      text: 'Focus score 0 minute. Hamster bhi tujhse zyada focused hai. 🐹',
      category: 'focus',
      trigger: TauntTrigger.sessionEnd,
      severity: 2,
      tags: <String>['ekagra'],
    ),
    Taunt(
      id: 'tb-emergency-004',
      text: 'Streak marne wali hai. Ek session bacha le, hero ban ja. 🔥',
      category: 'streak',
      trigger: TauntTrigger.streakLost,
      severity: 3,
      tags: <String>['streak'],
    ),
  ];

  /// Loads the bundled dataset and any cached remote dataset. Idempotent.
  Future<void> load() async {
    if (_loaded) return;
    _favourites = _storage.readFavouriteTaunts();
    _seen = _storage.readSeenTaunts();

    TauntDataset bundled = TauntDataset.empty;
    try {
      final String raw = await rootBundle.loadString('assets/data/taunts.json');
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        bundled = TauntDataset.fromJson(decoded, source: TauntSource.bundled);
      }
    } catch (e) {
      debugPrint('TauntBuddy: bundled taunt asset unavailable ($e)');
    }

    final Map<String, dynamic>? cached = _storage.readTauntCache();
    TauntDataset? cachedDataset;
    if (cached != null) {
      final TauntDataset parsed = TauntDataset.fromJson(cached, source: TauntSource.remote);
      if (!parsed.isEmpty) cachedDataset = parsed;
    }

    if (cachedDataset != null && cachedDataset.length >= bundled.length) {
      _dataset = cachedDataset;
    } else if (!bundled.isEmpty) {
      _dataset = bundled;
    } else if (cachedDataset != null) {
      _dataset = cachedDataset;
    } else {
      _dataset = const TauntDataset(
        schemaVersion: 1,
        packs: <TauntPack>[
          TauntPack(
            id: 'emergency',
            title: 'Emergency Hamster',
            description: 'Compiled-in fallback taunts.',
            taunts: _emergencyPack,
          ),
        ],
      );
    }

    _loaded = true;
    _lastSync = cachedDataset != null
        ? SyncResult(
            status: SyncStatus.ok,
            message: 'Using the last synced dataset (${cachedDataset.length} taunts).',
            count: cachedDataset.length,
          )
        : SyncResult.skipped('Using the bundled taunt pack (${_dataset.length} taunts).');
  }

  /// Downloads the dataset from the ifallertzia server. Returns a human-readable result.
  Future<SyncResult> syncFromIfallertzia(String url) async {
    final (TauntDataset?, SyncResult) result = await _source.fetchTaunts(url);
    final TauntDataset? remote = result.$1;
    _lastSync = result.$2;

    if (remote != null) {
      _dataset = remote;
      await _storage.writeTauntCache(_rawJsonOf(remote));
      await _storage.writeSeenTaunts(<String>{}); // new content deserves a fresh rotation
      _seen = <String>{};
    }
    return _lastSync;
  }

  /// Re-serialises the in-memory dataset for the offline cache.
  Map<String, dynamic> _rawJsonOf(TauntDataset dataset) => <String, dynamic>{
        'schemaVersion': dataset.schemaVersion,
        'updatedAt': dataset.updatedAt,
        'packs': dataset.packs
            .map((TauntPack pack) => <String, dynamic>{
                  'id': pack.id,
                  'title': pack.title,
                  'description': pack.description,
                  'taunts': pack.taunts.map((Taunt t) => t.toJson()).toList(growable: false),
                })
            .toList(growable: false),
      };

  /// Next taunt for a trigger set, honouring the severity cap and rotation.
  Taunt? next({
    List<TauntTrigger> triggers = const <TauntTrigger>[TauntTrigger.idle],
    int maxSeverity = 3,
    bool markSeen = true,
  }) {
    final Taunt? picked = _dataset.pick(
      triggers: triggers,
      maxSeverity: maxSeverity,
      excludeIds: _seen,
    );
    if (picked != null && markSeen) {
      _seen = <String>{..._seen, picked.id};
      unawaitedWrite(_storage.writeSeenTaunts(_seen));
    }
    return picked;
  }

  /// Fire-and-forget persistence helper.
  void unawaitedWrite(Future<void> future) {
    future.catchError((Object e) {
      debugPrint('TauntBuddy: background write failed ($e)');
    });
  }

  void toggleFavourite(String id) {
    if (_favourites.contains(id)) {
      _favourites = <String>{..._favourites}..remove(id);
    } else {
      _favourites = <String>{..._favourites, id};
    }
    unawaitedWrite(_storage.writeFavouriteTaunts(_favourites));
  }

  bool isFavourite(String id) => _favourites.contains(id);

  /// Taunts grouped by trigger for the vault filter chips.
  Map<TauntTrigger, List<Taunt>> groupedByTrigger() {
    final Map<TauntTrigger, List<Taunt>> grouped = <TauntTrigger, List<Taunt>>{};
    for (final Taunt taunt in all) {
      grouped.putIfAbsent(taunt.trigger, () => <Taunt>[]).add(taunt);
    }
    return grouped;
  }
}
