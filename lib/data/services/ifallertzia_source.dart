import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/quote.dart';
import '../models/taunt.dart';

/// Outcome of a dataset sync attempt, surfaced in Settings and the Taunt Vault.
enum SyncStatus { ok, offline, invalid, skipped }

class SyncResult {
  const SyncResult({
    required this.status,
    required this.message,
    this.count = 0,
    this.at,
  });

  final SyncStatus status;
  final String message;
  final int count;
  final DateTime? at;

  bool get isOk => status == SyncStatus.ok;

  static SyncResult skipped(String message) =>
      SyncResult(status: SyncStatus.skipped, message: message);
}

/// Downloads the taunt / quote datasets from the ifallertzia server (a hosted
/// JSON file).
///
/// Design rules:
/// * never throw — the repository always has a bundled fallback dataset,
/// * always time out (a hanging request must not freeze onboarding),
/// * validate the schema version before the data is allowed into the app.
class IfallertziaDatasetSource {
  IfallertziaDatasetSource({http.Client? client, this.timeout = const Duration(seconds: 12)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// Default dataset URL — the same JSON the CI workflow validates on every PR.
  static const String defaultTauntsUrl =
      'https://raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/taunts.json';

  static const String defaultQuotesUrl =
      'https://raw.githubusercontent.com/dastaanenajdik/Tauntbuddy/main/assets/data/quotes.json';

  /// The ifallertzia server also serves the dataset via a REST API which
  /// works for private sources when a token is supplied by the user.
  static const String supportedSchemaNote = 'taunts.json schemaVersion 1';

  Future<Map<String, dynamic>?> _getJson(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      final http.Response response = await _client
          .get(uri, headers: const <String, String>{'Accept': 'application/json'})
          .timeout(timeout);
      if (response.statusCode != 200) {
        debugPrint('TauntBuddy sync: HTTP ${response.statusCode} for $url');
        return null;
      }
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on TimeoutException {
      debugPrint('TauntBuddy sync: timeout for $url');
      return null;
    } on FormatException catch (e) {
      debugPrint('TauntBuddy sync: malformed JSON ($e)');
      return null;
    } catch (e) {
      debugPrint('TauntBuddy sync: network error ($e)');
      return null;
    }
  }

  /// Fetches and validates the taunt dataset.
  Future<(TauntDataset?, SyncResult)> fetchTaunts(String url) async {
    final String target = url.trim().isEmpty ? defaultTauntsUrl : url.trim();
    final Map<String, dynamic>? json = await _getJson(target);
    if (json == null) {
      return (
        null,
        SyncResult(
          status: SyncStatus.offline,
          message: 'Could not reach the ifallertzia server. Using the bundled taunt pack.',
          at: DateTime.now(),
        ),
      );
    }

    final int schema = (json['schemaVersion'] as num?)?.toInt() ?? 0;
    if (schema != 1) {
      return (
        null,
        SyncResult(
          status: SyncStatus.invalid,
          message: 'Unsupported dataset schema ($schema). Expected $supportedSchemaNote.',
          at: DateTime.now(),
        ),
      );
    }

    final TauntDataset dataset = TauntDataset.fromJson(json, source: TauntSource.remote);
    if (dataset.isEmpty) {
      return (
        null,
        SyncResult(
          status: SyncStatus.invalid,
          message: 'The dataset was reachable but contained no taunts.',
          at: DateTime.now(),
        ),
      );
    }

    return (
      dataset,
      SyncResult(
        status: SyncStatus.ok,
        message: 'Synced ${dataset.length} taunts from the ifallertzia server.',
        count: dataset.length,
        at: DateTime.now(),
      ),
    );
  }

  /// Fetches the daily-quote dataset. Quotes are decorative, so failures are
  /// silently tolerated by the caller.
  Future<(QuoteDataset?, SyncResult)> fetchQuotes(String url) async {
    final String target = url.trim().isEmpty ? defaultQuotesUrl : url.trim();
    final Map<String, dynamic>? json = await _getJson(target);
    if (json == null) {
      return (null, SyncResult(status: SyncStatus.offline, message: 'Quotes offline'));
    }
    final QuoteDataset dataset = QuoteDataset.fromJson(json, fromRemote: true);
    if (dataset.isEmpty) {
      return (null, SyncResult(status: SyncStatus.invalid, message: 'Empty quote file'));
    }
    return (
      dataset,
      SyncResult(
        status: SyncStatus.ok,
        message: 'Synced ${dataset.quotes.length} quotes',
        count: dataset.quotes.length,
        at: DateTime.now(),
      ),
    );
  }

  void dispose() => _client.close();
}
