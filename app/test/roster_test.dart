import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal_team_balancer/models/lineup.dart';
import 'package:futsal_team_balancer/models/player.dart';
import 'package:futsal_team_balancer/models/roster.dart';
import 'package:futsal_team_balancer/services/storage.dart';
import 'package:futsal_team_balancer/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> newState(List<String> names) async {
  SharedPreferences.setMockInitialValues({});
  final s = AppState(await Storage.open(), today: DateTime(2026, 10, 11));
  for (final n in names) {
    s.addPlayer(n);
  }
  return s;
}

/// 다른 기기로 옮긴 것처럼 JSON 문자열을 거쳐 되돌린다.
RosterBackup roundTrip(RosterBackup b) =>
    RosterBackup.fromJson(jsonDecode(jsonEncode(b.toJson())) as Map<String, dynamic>);

void main() {
  test('백업: 전체 명단과 능력치가 들어가고 마지막 백업 시각이 저장된다', () async {
    final s = await newState(['김민수', '이준호', '박지훈']);
    s.setStat(s.players[1], Stat.speed, 3);
    final b = roundTrip(s.exportRoster(now: DateTime(2026, 10, 7, 21)));
    expect(b.players.map((p) => p.name), ['김민수', '이준호', '박지훈']);
    expect(b.players[1].stats[Stat.speed], 3);
    expect(b.exportedAt, DateTime(2026, 10, 7, 21));

    final reopened = AppState(await Storage.open(), today: DateTime(2026, 10, 11));
    expect(reopened.lastBackupAt, DateTime(2026, 10, 7, 21));
  });

  test('빈 기기에 복원하면 명단이 그대로 생긴다', () async {
    final src = await newState(['김민수', '이준호']);
    src.setStat(src.players[0], Stat.skill, 1);
    final b = roundTrip(src.exportRoster());

    final dst = await newState([]);
    final r = dst.importRoster(b, replace: false);
    expect(r.added, 2);
    expect(dst.players.map((p) => p.name), ['김민수', '이준호']);
    expect(dst.players[0].stats[Stat.skill], 1);
    expect(dst.players[0].id, src.players[0].id);
  });

  test('합치기: 같은 선수는 갱신, 새 선수는 추가, 기존 선수는 유지', () async {
    final s = await newState(['김민수', '이준호']);
    final b = roundTrip(s.exportRoster());
    b.players[0].stats[Stat.condition] = 3; // 백업 이후 바뀐 능력치 (파일 쪽)

    s.addPlayer('최영진'); // 백업 이후 새로 등록
    final r = s.importRoster(
        RosterBackup([...b.players, Player(id: 'x', name: '박지훈')]),
        replace: false);
    expect(r.updated, 2);
    expect(r.added, 1);
    expect(s.players.map((p) => p.name), ['김민수', '이준호', '최영진', '박지훈']);
    expect(s.players[0].stats[Stat.condition], 3);
  });

  test('합치기: ID가 달라도 이름이 같으면 같은 선수로 본다', () async {
    final s = await newState(['김민수']);
    final r = s.importRoster(
        RosterBackup([Player(id: 'other', name: '김민수', stats: {Stat.speed: 1})]),
        replace: false);
    expect(r.updated, 1);
    expect(s.players.length, 1);
    expect(s.players.single.stats[Stat.speed], 1);
  });

  test('바꾸기: 파일에 없는 선수는 지우고 참석 체크와 편성도 정리한다', () async {
    final s = await newState(List.generate(12, (i) => '선수${i + 1}'));
    s.setAllAttending(true);
    s.build();
    final keep = roundTrip(RosterBackup(s.players.take(10).toList()));

    final r = s.importRoster(keep, replace: true);
    expect(r.removed, 2);
    expect(r.updated, 10);
    expect(r.added, 0);
    expect(s.players.length, 10);
    expect(s.lineup.attendees.length, 10);
    expect(s.lineup.hasTeams, isFalse); // 참석자가 바뀌어 편성 초기화
  });

  test('파일 안 중복 이름과 빈 이름은 무시한다', () async {
    final s = await newState([]);
    final r = s.importRoster(
        RosterBackup([
          Player(id: 'a', name: '김민수'),
          Player(id: 'b', name: '김민수'),
          Player(id: 'c', name: '  '),
        ]),
        replace: false);
    expect(r.added, 1);
    expect(s.players.single.id, 'a');
  });

  test('명단 백업 파일이 아니면 예외', () {
    expect(() => RosterBackup.fromJson({'schemaVersion': 1, 'matchDate': '2026-10-11'}),
        throwsFormatException);
    expect(
        () => RosterBackup.fromJson(
            {'type': RosterBackup.type, 'schemaVersion': 99, 'players': []}),
        throwsFormatException);
  });

  test('명단 백업 파일을 경기 편성 불러오기로 열면 안내 메시지', () async {
    final s = await newState(['김민수']);
    final json = s.exportRoster().toJson();
    expect(() => Lineup.fromJson(json),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('명단 복원'))));
  });
}
