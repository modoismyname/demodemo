import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/lineup.dart';
import '../models/player.dart';
import '../models/roster.dart';
import '../services/storage.dart';
import '../services/team_builder.dart';

/// 드래그 놓을 위치. [teamIndex]가 null이면 교체대기.
class DropTarget {
  const DropTarget.team(int this.teamIndex, {this.swapWith});
  const DropTarget.bench({this.swapWith}) : teamIndex = null;

  final int? teamIndex;

  /// 선수 위에 놓으면 그 선수와 맞바꾼다. null이면 빈 슬롯(또는 대기 명단)으로 이동.
  final String? swapWith;
}

enum MoveResult { moved, swapped, noSlot, ignored }

class RosterImportResult {
  const RosterImportResult({this.added = 0, this.updated = 0, this.removed = 0});
  final int added;
  final int updated;
  final int removed;
}

class AppState extends ChangeNotifier {
  AppState(this._storage, {Random? random, DateTime? today})
      : _random = random ?? Random(),
        players = _storage.loadPlayers(),
        lastBackupAt = _storage.loadLastBackup() {
    final now = today ?? DateTime.now();
    _openDate(DateTime(now.year, now.month, now.day));
  }

  final Storage _storage;
  final Random _random;
  static const _uuid = Uuid();

  final List<Player> players;
  late Lineup lineup;

  /// 마지막으로 명단을 백업한 시각. 한 번도 안 했으면 null.
  DateTime? lastBackupAt;

  // ---------------- 선수 관리 ----------------

  /// 같은 이름이 이미 있으면 false.
  bool addPlayer(String name) {
    final n = name.trim();
    if (n.isEmpty || _nameTaken(n)) return false;
    players.add(Player(id: _uuid.v4(), name: n));
    _savePlayers();
    return true;
  }

  bool renamePlayer(Player p, String name) {
    final n = name.trim();
    if (n.isEmpty || _nameTaken(n, except: p)) return false;
    p.name = n;
    _savePlayers();
    return true;
  }

  void setStat(Player p, Stat s, int level) {
    p.stats[s] = level.clamp(minLevel, maxLevel);
    _savePlayers();
  }

  void deletePlayer(Player p) {
    players.remove(p);
    if (!lineup.confirmed && lineup.attendees.remove(p.id)) {
      _clearTeams();
      _saveLineup();
    }
    _savePlayers();
  }

  // ---------------- 명단 백업/복원 ----------------

  /// 전체 명단을 백업 파일 내용으로 만든다. 마지막 백업 시각도 기록한다.
  RosterBackup exportRoster({DateTime? now}) {
    final at = now ?? DateTime.now();
    lastBackupAt = at;
    _storage.saveLastBackup(at);
    notifyListeners();
    return RosterBackup(players.map((p) => p.copy()).toList(), exportedAt: at);
  }

  /// 백업 파일의 명단을 불러온다.
  /// [replace]가 false면 합치기: 같은 선수(같은 ID, 없으면 같은 이름)는 파일 내용으로 갱신하고 새 선수는 추가.
  /// [replace]가 true면 현재 명단을 파일 명단으로 바꾼다.
  RosterImportResult importRoster(RosterBackup backup, {required bool replace}) {
    // 파일 안에서 이름이 겹치면 앞의 선수만 사용
    final seenNames = <String>{};
    final incoming = [
      for (final p in backup.players)
        if (p.name.trim().isNotEmpty && seenNames.add(p.name.trim()))
          (p.copy()..name = p.name.trim()),
    ];

    var added = 0, updated = 0, removed = 0;
    if (replace) {
      final incomingIds = {for (final p in incoming) p.id};
      final existingIds = {for (final p in players) p.id};
      removed = existingIds.difference(incomingIds).length;
      updated = incomingIds.intersection(existingIds).length;
      added = incoming.length - updated;
      players
        ..clear()
        ..addAll(incoming);
    } else {
      for (final p in incoming) {
        final i = players.indexWhere((e) => e.id == p.id);
        final j = i >= 0 ? i : players.indexWhere((e) => e.name == p.name);
        if (j >= 0) {
          final cur = players[j];
          // 이름을 바꿨을 때 다른 선수와 겹치면 기존 이름 유지
          if (!_nameTaken(p.name, except: cur)) cur.name = p.name;
          cur.stats.addAll(p.stats);
          updated++;
        } else {
          players.add(p);
          added++;
        }
      }
    }

    final ids = {for (final p in players) p.id};
    if (!lineup.confirmed) {
      final before = lineup.attendees.length;
      lineup.attendees.retainAll(ids);
      if (lineup.attendees.length != before) _clearTeams();
      _storage.saveLineup(lineup);
    }
    _savePlayers();
    return RosterImportResult(added: added, updated: updated, removed: removed);
  }

  bool _nameTaken(String n, {Player? except}) =>
      players.any((p) => p != except && p.name == n);

  void _savePlayers() {
    _storage.savePlayers(players);
    notifyListeners();
  }

  // ---------------- 경기 편성 ----------------

  bool get locked => lineup.confirmed;

  List<Player> get attendingPlayers =>
      players.where((p) => lineup.attendees.contains(p.id)).toList();

  TeamPlan? get plan => planTeams(attendingPlayers.length, lineup.teamCount);

  void selectDate(DateTime date) {
    _openDate(DateTime(date.year, date.month, date.day));
    notifyListeners();
  }

  void _openDate(DateTime date) {
    lineup = _storage.loadLineup(date) ?? Lineup(date: date);
  }

  void setTeamCount(int count) {
    if (locked || !teamCountOptions.contains(count)) return;
    lineup.teamCount = count;
    _clearTeams();
    _saveLineup();
  }

  void setMode(BuildMode mode) {
    if (locked) return;
    lineup.mode = mode;
    if (lineup.hasTeams && plan != null) {
      build();
    } else {
      _saveLineup();
    }
  }

  void setAttending(Player p, bool attending) {
    if (locked) return;
    attending ? lineup.attendees.add(p.id) : lineup.attendees.remove(p.id);
    _clearTeams();
    _saveLineup();
  }

  void setAllAttending(bool attending) {
    if (locked) return;
    lineup.attendees
      ..clear()
      ..addAll(attending ? players.map((p) => p.id) : const <String>[]);
    _clearTeams();
    _saveLineup();
  }

  /// 팀 구성. 경기 불가 인원이면 false.
  bool build() {
    if (locked || plan == null) return false;
    final result = buildTeams(
      attendingPlayers.map((p) => p.copy()).toList(),
      lineup.teamCount,
      lineup.mode,
      random: _random,
    );
    lineup
      ..teams = result.teams
      ..bench = result.bench;
    _saveLineup();
    return true;
  }

  MoveResult movePlayer(String playerId, DropTarget target) {
    if (locked || !lineup.hasTeams) return MoveResult.ignored;
    final from = _locate(playerId);
    if (from == null) return MoveResult.ignored;
    final src = _list(from.$1);
    final dst = _list(target.teamIndex);

    if (target.swapWith != null && target.swapWith != playerId) {
      final to = _locate(target.swapWith!);
      if (to == null) return MoveResult.ignored;
      final other = _list(to.$1);
      final tmp = src[from.$2];
      src[from.$2] = other[to.$2];
      other[to.$2] = tmp;
      _saveLineup();
      return MoveResult.swapped;
    }
    if (from.$1 == target.teamIndex) return MoveResult.ignored;
    if (target.teamIndex != null &&
        lineup.teams[target.teamIndex!].emptySlots == 0) {
      return MoveResult.noSlot;
    }
    dst.add(src.removeAt(from.$2));
    _saveLineup();
    return MoveResult.moved;
  }

  /// 팀 인원이 5~7명이 아닌 팀 이름 목록. 비어 있으면 확정 가능.
  List<String> get invalidTeams => [
        for (var i = 0; i < lineup.teams.length; i++)
          if (!lineup.teams[i].sizeValid) teamName(i),
      ];

  bool confirm() {
    if (locked || !lineup.hasTeams || invalidTeams.isNotEmpty) return false;
    lineup
      ..confirmed = true
      ..confirmedAt = DateTime.now();
    _saveLineup();
    return true;
  }

  /// 확정을 풀고 다시 편집한다.
  void unlock() {
    if (!locked) return;
    lineup.confirmed = false;
    _saveLineup();
  }

  /// JSON 파일에서 불러온 편성으로 교체한다. 해당 날짜로 이동한다.
  /// 명단에 없는 선수는 파일에 저장된 능력치로 명단에 추가한다. 추가한 인원 수를 돌려준다.
  int importLineup(Lineup imported) {
    final known = {for (final p in players) p.id};
    var added = 0;
    for (final p in [
      ...imported.teams.expand((t) => t.players),
      ...imported.bench,
    ]) {
      if (known.add(p.id)) {
        players.add(p.copy());
        added++;
      }
    }
    imported.attendees.retainAll(known);
    lineup = imported;
    if (added > 0) _storage.savePlayers(players);
    _saveLineup();
    return added;
  }

  (int?, int)? _locate(String id) {
    for (var t = 0; t < lineup.teams.length; t++) {
      final i = lineup.teams[t].players.indexWhere((p) => p.id == id);
      if (i >= 0) return (t, i);
    }
    final b = lineup.bench.indexWhere((p) => p.id == id);
    return b >= 0 ? (null, b) : null;
  }

  List<Player> _list(int? teamIndex) =>
      teamIndex == null ? lineup.bench : lineup.teams[teamIndex].players;

  void _clearTeams() {
    lineup
      ..teams = []
      ..bench = [];
  }

  void _saveLineup() {
    _storage.saveLineup(lineup);
    notifyListeners();
  }
}
