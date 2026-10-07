import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal_team_balancer/models/lineup.dart';
import 'package:futsal_team_balancer/models/player.dart';
import 'package:futsal_team_balancer/services/team_builder.dart';

List<Player> makePlayers(int n, {int seed = 1}) {
  final r = Random(seed);
  return [
    for (var i = 0; i < n; i++)
      Player(id: 'p$i', name: '선수$i', stats: {
        for (final s in Stat.values) s: 1 + r.nextInt(3),
      }),
  ];
}

void main() {
  group('planTeams', () {
    final cases = <(int, int, List<int>?, int)>[
      (9, 2, null, 0),
      (10, 2, [5, 5], 0),
      (11, 2, [6, 5], 0),
      (13, 2, [7, 6], 0),
      (14, 2, [7, 7], 0),
      (15, 2, [7, 7], 1),
      (18, 2, [7, 7], 4),
      (14, 3, null, 0),
      (15, 3, [5, 5, 5], 0),
      (16, 3, [6, 5, 5], 0),
      (18, 3, [6, 6, 6], 0),
      (20, 3, [7, 7, 6], 0),
      (21, 3, [7, 7, 7], 0),
      (23, 3, [7, 7, 7], 2),
    ];
    for (final (n, k, sizes, bench) in cases) {
      test('$n명 $k팀', () {
        final plan = planTeams(n, k);
        if (sizes == null) {
          expect(plan, isNull);
        } else {
          expect(plan!.sizes, sizes);
          expect(plan.benchCount, bench);
        }
      });
    }

    test('모든 경우 팀당 5~7명, 인원 차이 최대 1명', () {
      for (final k in teamCountOptions) {
        for (var n = 0; n <= 40; n++) {
          final plan = planTeams(n, k);
          if (n < 5 * k) {
            expect(plan, isNull);
            continue;
          }
          expect(plan!.sizes.length, k);
          expect(plan.sizes.every((s) => s >= 5 && s <= 7), isTrue);
          expect(plan.sizes.reduce(max) - plan.sizes.reduce(min), lessThanOrEqualTo(1));
          expect(plan.sizes.reduce((a, b) => a + b) + plan.benchCount, n);
        }
      }
    });
  });

  group('buildTeams', () {
    test('모든 참석자가 정확히 한 번씩 배정된다', () {
      for (final mode in BuildMode.values) {
        final ps = makePlayers(18);
        final r = buildTeams(ps, 2, mode, random: Random(3));
        final ids = [
          ...r.teams.expand((t) => t.players.map((p) => p.id)),
          ...r.bench.map((p) => p.id),
        ];
        expect(ids.toSet().length, 18);
        expect(ids.length, 18);
        expect(r.bench.length, 4);
        expect(r.teams.map((t) => t.players.length), [7, 7]);
        expect(r.teams.every((t) => t.capacity == 9), isTrue);
      }
    });

    test('전문화: A팀 최저 점수 >= B팀 최고 점수 >= C팀 최고 점수', () {
      final r = buildTeams(makePlayers(21, seed: 5), 3, BuildMode.tiered,
          random: Random(1));
      int minOf(Team t) => t.players.map((p) => p.total).reduce(min);
      int maxOf(Team t) => t.players.map((p) => p.total).reduce(max);
      expect(minOf(r.teams[0]), greaterThanOrEqualTo(maxOf(r.teams[1])));
      expect(minOf(r.teams[1]), greaterThanOrEqualTo(maxOf(r.teams[2])));
    });

    test('평준화: 팀 총점 차이가 작다 (같은 인원일 때 3점 이하)', () {
      for (var seed = 0; seed < 30; seed++) {
        final r = buildTeams(makePlayers(14, seed: seed), 2, BuildMode.balanced,
            random: Random(seed));
        final totals = r.teams.map((t) => t.total).toList();
        expect((totals[0] - totals[1]).abs(), lessThanOrEqualTo(3),
            reason: 'seed $seed: $totals');
      }
    });

    test('평준화가 전문화보다 균형 비용이 낮다', () {
      final ps = makePlayers(18, seed: 9);
      double cost(BuildMode m) => balanceCost(buildTeams(ps, 3, m, random: Random(2))
          .teams
          .map((t) => t.players)
          .toList());
      expect(cost(BuildMode.balanced), lessThan(cost(BuildMode.tiered)));
    });

    test('인원 부족이면 예외', () {
      expect(() => buildTeams(makePlayers(9), 2, BuildMode.balanced),
          throwsArgumentError);
    });
  });
}
