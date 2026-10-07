import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/lineup.dart';
import '../models/player.dart';

/// 브라우저 로컬 저장소에 선수 명단과 날짜별 편성을 보관한다.
class Storage {
  Storage(this._prefs);

  static const _playersKey = 'players.v1';
  static const _lineupPrefix = 'lineup.v1.';
  static const _lastBackupKey = 'rosterBackupAt.v1';

  final SharedPreferences _prefs;

  static Future<Storage> open() async =>
      Storage(await SharedPreferences.getInstance());

  List<Player> loadPlayers() {
    final raw = _prefs.getString(_playersKey);
    if (raw == null) return [];
    try {
      return [
        for (final p in jsonDecode(raw) as List)
          Player.fromJson((p as Map).cast<String, dynamic>()),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> savePlayers(List<Player> players) => _prefs.setString(
      _playersKey, jsonEncode(players.map((p) => p.toJson()).toList()));

  DateTime? loadLastBackup() =>
      DateTime.tryParse(_prefs.getString(_lastBackupKey) ?? '');

  Future<void> saveLastBackup(DateTime at) =>
      _prefs.setString(_lastBackupKey, at.toIso8601String());

  Lineup? loadLineup(DateTime date) {
    final raw = _prefs.getString(_lineupPrefix + formatDateKey(date));
    if (raw == null) return null;
    try {
      return Lineup.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLineup(Lineup lineup) => _prefs.setString(
      _lineupPrefix + lineup.dateKey, jsonEncode(lineup.toJson()));
}
