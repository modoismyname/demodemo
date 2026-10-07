import 'dart:math';

import '../models/lineup.dart';
import '../models/player.dart';

/// 참석 인원과 팀 수로 정한 팀별 인원.
class TeamPlan {
  const TeamPlan(this.sizes, this.benchCount);
  final List<int> sizes;
  final int benchCount;
}

/// 팀 수 [teamCount]로 [attendeeCount]명을 나눈다.
/// 팀당 5~7명이며 인원 차이는 최대 1명, 7명을 넘는 인원은 교체대기.
/// 인원이 모자라면 null(경기 불가).
TeamPlan? planTeams(int attendeeCount, int teamCount) {
  if (attendeeCount < minTeamSize * teamCount) return null;
  final onTeams = min(attendeeCount, maxTeamSize * teamCount);
  final base = onTeams ~/ teamCount;
  final extra = onTeams % teamCount;
  return TeamPlan(
    [for (var i = 0; i < teamCount; i++) base + (i < extra ? 1 : 0)],
    attendeeCount - onTeams,
  );
}

class BuildResult {
  const BuildResult(this.teams, this.bench);
  final List<Team> teams;
  final List<Player> bench;
}

/// 교체대기를 무작위로 뽑은 뒤 [mode]에 따라 팀을 편성한다.
BuildResult buildTeams(
  List<Player> attendees,
  int teamCount,
  BuildMode mode, {
  Random? random,
}) {
  final plan = planTeams(attendees.length, teamCount);
  if (plan == null) {
    throw ArgumentError('참석 인원이 부족합니다.');
  }
  final rnd = random ?? Random();
  final pool = [...attendees]..shuffle(rnd);
  final bench = pool.sublist(0, plan.benchCount);
  final playing = pool.sublist(plan.benchCount);
  // 섞은 뒤 안정 정렬하므로 점수가 같은 선수끼리는 매번 순서가 달라진다.
  _stableSortByTotalDesc(playing);

  final groups = switch (mode) {
    BuildMode.balanced => _balanced(playing, plan.sizes),
    BuildMode.tiered => _tiered(playing, plan.sizes),
  };
  return BuildResult(
    [
      for (var i = 0; i < groups.length; i++)
        Team(players: groups[i], capacity: plan.sizes[i] + emptySlotsPerTeam),
    ],
    bench,
  );
}

void _stableSortByTotalDesc(List<Player> list) {
  final indexed = [for (var i = 0; i < list.length; i++) (i, list[i])];
  indexed.sort((a, b) {
    final c = b.$2.total.compareTo(a.$2.total);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  for (var i = 0; i < list.length; i++) {
    list[i] = indexed[i].$2;
  }
}

/// 전문화: 점수 높은 선수부터 A팀, 그다음 B팀 순서로 채운다.
List<List<Player>> _tiered(List<Player> sorted, List<int> sizes) {
  final groups = <List<Player>>[];
  var i = 0;
  for (final size in sizes) {
    groups.add(sorted.sublist(i, i + size));
    i += size;
  }
  return groups;
}

/// 평준화: 스네이크 드래프트로 1차 배정 후, 비용이 줄어드는 동안 선수를 맞바꾼다.
List<List<Player>> _balanced(List<Player> sorted, List<int> sizes) {
  final k = sizes.length;
  final groups = [for (var i = 0; i < k; i++) <Player>[]];
  var forward = true;
  var idx = 0;
  while (idx < sorted.length) {
    final order = forward
        ? [for (var t = 0; t < k; t++) t]
        : [for (var t = k - 1; t >= 0; t--) t];
    for (final t in order) {
      if (idx >= sorted.length) break;
      if (groups[t].length < sizes[t]) groups[t].add(sorted[idx++]);
    }
    forward = !forward;
  }

  var improved = true;
  var guard = 0;
  while (improved && guard++ < 200) {
    improved = false;
    for (var a = 0; a < k; a++) {
      for (var b = a + 1; b < k; b++) {
        for (var i = 0; i < groups[a].length; i++) {
          for (var j = 0; j < groups[b].length; j++) {
            final before = balanceCost(groups);
            _swap(groups, a, i, b, j);
            if (balanceCost(groups) < before - 1e-9) {
              improved = true;
            } else {
              _swap(groups, a, i, b, j);
            }
          }
        }
      }
    }
  }
  return groups;
}

void _swap(List<List<Player>> g, int a, int i, int b, int j) {
  final tmp = g[a][i];
  g[a][i] = g[b][j];
  g[b][j] = tmp;
}

/// 평준화 비용. 팀 총점 차이를 가장 크게 반영하고, 항목별 1인당 평균 차이도 더한다.
/// 인원이 다른 팀(예: 6명 vs 5명)도 비교할 수 있도록 1인당 평균으로 계산한다.
double balanceCost(List<List<Player>> groups) {
  double spread(Iterable<double> v) => v.reduce(max) - v.reduce(min);
  double avg(List<Player> g, int Function(Player) f) =>
      g.isEmpty ? 0 : g.fold<int>(0, (a, p) => a + f(p)) / g.length;

  var cost = spread(groups.map((g) => avg(g, (p) => p.total))) * 10;
  for (final s in Stat.values) {
    cost += spread(groups.map((g) => avg(g, (p) => p.stats[s]!)));
  }
  return cost;
}
