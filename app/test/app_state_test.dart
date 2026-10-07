import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal_team_balancer/models/lineup.dart';
import 'package:futsal_team_balancer/models/player.dart';
import 'package:futsal_team_balancer/services/storage.dart';
import 'package:futsal_team_balancer/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> newState({int players = 0}) async {
  SharedPreferences.setMockInitialValues({});
  final s = AppState(await Storage.open(),
      random: Random(1), today: DateTime(2026, 10, 11));
  for (var i = 0; i < players; i++) {
    s.addPlayer('선수${i + 1}');
  }
  return s;
}

void main() {
  test('선수 추가, 중복 이름 거부, 능력치 저장 후 다시 열면 유지', () async {
    final s = await newState();
    expect(s.addPlayer('김민수'), isTrue);
    expect(s.addPlayer(' 김민수 '), isFalse);
    expect(s.addPlayer('  '), isFalse);
    s.setStat(s.players.first, Stat.speed, 3);
    s.setStat(s.players.first, Stat.skill, 9); // 범위 밖은 3으로 제한

    final reopened = AppState(await Storage.open(), today: DateTime(2026, 10, 11));
    expect(reopened.players.single.name, '김민수');
    expect(reopened.players.single.stats[Stat.speed], 3);
    expect(reopened.players.single.stats[Stat.skill], 3);
    expect(reopened.players.single.total, 2 + 3 + 3 + 2 + 2);
  });

  test('참석 9명이면 2팀 구성 불가, 10명이면 가능, 3팀은 15명부터', () async {
    final s = await newState(players: 15);
    for (final p in s.players.take(9)) {
      s.setAttending(p, true);
    }
    expect(s.plan, isNull);
    expect(s.build(), isFalse);
    s.setAttending(s.players[9], true);
    expect(s.build(), isTrue);
    expect(s.lineup.teams.map((t) => t.players.length), [5, 5]);

    s.setTeamCount(3);
    expect(s.lineup.hasTeams, isFalse); // 팀 수를 바꾸면 편성 초기화
    expect(s.plan, isNull);
    s.setAllAttending(true);
    expect(s.plan!.sizes, [5, 5, 5]);
  });

  test('드래그 이동: 빈 슬롯 이동, 맞바꾸기, 슬롯 없음, 교체대기', () async {
    final s = await newState(players: 16);
    s.setAllAttending(true);
    s.build(); // 7 + 7 + 대기 2
    final a = s.lineup.teams[0], b = s.lineup.teams[1];
    expect(a.emptySlots, 2);

    final mover = a.players.first.id;
    expect(s.movePlayer(mover, const DropTarget.team(1)), MoveResult.moved);
    expect(a.players.length, 6);
    expect(b.players.length, 8);
    expect(a.emptySlots, 3);
    expect(b.emptySlots, 1);
    expect(s.invalidTeams, ['B팀']);
    expect(s.confirm(), isFalse);

    // B팀을 9명(정원)으로 채운 뒤 하나 더 넣으면 슬롯 없음
    expect(s.movePlayer(a.players.first.id, const DropTarget.team(1)), MoveResult.moved);
    expect(s.movePlayer(a.players.first.id, const DropTarget.team(1)), MoveResult.noSlot);

    // 맞바꾸기
    final x = a.players.first.id, y = b.players.first.id;
    expect(s.movePlayer(x, DropTarget.team(1, swapWith: y)), MoveResult.swapped);
    expect(a.players.first.id, y);
    expect(b.players.first.id, x);

    // 교체대기로 이동
    final benchBefore = s.lineup.bench.length;
    expect(s.movePlayer(b.players.last.id, const DropTarget.bench()), MoveResult.moved);
    expect(s.lineup.bench.length, benchBefore + 1);
  });

  test('확정 후 잠금, 수정으로 해제, JSON 저장과 불러오기', () async {
    final s = await newState(players: 14);
    s.setAllAttending(true);
    s.build();
    expect(s.confirm(), isTrue);
    expect(s.locked, isTrue);
    expect(s.build(), isFalse);
    s.setTeamCount(3);
    expect(s.lineup.teamCount, 2);

    final json = jsonEncode(s.lineup.toJson());
    s.unlock();
    expect(s.locked, isFalse);

    // 다른 기기(빈 명단)에서 불러오기
    final other = await newState();
    final added = other.importLineup(
        Lineup.fromJson(jsonDecode(json) as Map<String, dynamic>));
    expect(added, 14);
    expect(other.lineup.dateKey, '2026-10-11');
    expect(other.locked, isTrue);
    expect(other.lineup.teams.map((t) => t.players.length), [7, 7]);
    expect(other.attendingPlayers.length, 14);
    other.unlock();
    expect(other.build(), isTrue); // 재편집 가능
  });

  test('날짜별 편성은 따로 보관된다', () async {
    final s = await newState(players: 12);
    s.setAllAttending(true);
    s.build();
    s.selectDate(DateTime(2026, 10, 18));
    expect(s.lineup.attendees, isEmpty);
    expect(s.lineup.hasTeams, isFalse);
    s.selectDate(DateTime(2026, 10, 11));
    expect(s.lineup.attendees.length, 12);
    expect(s.lineup.teams.map((t) => t.players.length), [6, 6]);
  });

  test('잘못된 JSON은 예외', () {
    expect(() => Lineup.fromJson({'schemaVersion': 99}), throwsFormatException);
    expect(() => Lineup.fromJson({'foo': 1}), throwsFormatException);
  });
}
