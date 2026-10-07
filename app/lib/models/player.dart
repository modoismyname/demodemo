/// 능력치 항목. 순서는 화면, PDF, JSON에서 모두 동일하게 사용한다.
enum Stat {
  stamina('활동량'),
  speed('스피드'),
  skill('개인기'),
  teamwork('협동력'),
  condition('컨디션');

  const Stat(this.label);
  final String label;
}

const int minLevel = 1;
const int maxLevel = 3;
const int defaultLevel = 2;

class Player {
  Player({required this.id, required this.name, Map<Stat, int>? stats})
      : stats = {for (final s in Stat.values) s: stats?[s] ?? defaultLevel};

  final String id;
  String name;
  final Map<Stat, int> stats;

  int get total => stats.values.fold(0, (a, b) => a + b);

  Player copy() => Player(id: id, name: name, stats: Map.of(stats));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stats': {for (final s in Stat.values) s.name: stats[s]},
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    final raw = (json['stats'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      stats: {
        for (final s in Stat.values)
          s: ((raw[s.name] as num?)?.toInt() ?? defaultLevel)
              .clamp(minLevel, maxLevel),
      },
    );
  }
}
