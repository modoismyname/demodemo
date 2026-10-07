import 'player.dart';

enum BuildMode {
  balanced('평준화'),
  tiered('전문화');

  const BuildMode(this.label);
  final String label;
}

const int minTeamSize = 5;
const int maxTeamSize = 7;
const int emptySlotsPerTeam = 2;
const List<int> teamCountOptions = [2, 3];
const String teamLetters = 'ABC';

String teamName(int index) => '${teamLetters[index]}팀';

class Team {
  Team({required this.players, required this.capacity});

  final List<Player> players;

  /// 처음 배정된 인원 + 빈 슬롯 수. 드래그로 옮겨 넣을 수 있는 최대 인원.
  int capacity;

  int get emptySlots => (capacity - players.length).clamp(0, capacity);
  bool get sizeValid =>
      players.length >= minTeamSize && players.length <= maxTeamSize;
  int sumOf(Stat s) => players.fold(0, (a, p) => a + p.stats[s]!);
  int get total => players.fold(0, (a, p) => a + p.total);
}

/// 한 경기 날짜의 편성 상태. 확정되면 JSON 파일로 저장된다.
class Lineup {
  Lineup({
    required this.date,
    this.mode = BuildMode.balanced,
    this.teamCount = 2,
    Set<String>? attendees,
    List<Team>? teams,
    List<Player>? bench,
    this.confirmed = false,
    this.confirmedAt,
  })  : attendees = attendees ?? <String>{},
        teams = teams ?? [],
        bench = bench ?? [];

  final DateTime date;
  BuildMode mode;
  int teamCount;
  final Set<String> attendees;
  List<Team> teams;
  List<Player> bench;
  bool confirmed;
  DateTime? confirmedAt;

  bool get hasTeams => teams.isNotEmpty;

  static const int schemaVersion = 1;

  String get dateKey => formatDateKey(date);

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'matchDate': dateKey,
        'mode': mode.name,
        'teamCount': teamCount,
        'confirmed': confirmed,
        'confirmedAt': confirmedAt?.toIso8601String(),
        'attendees': attendees.toList(),
        'teams': [
          for (var i = 0; i < teams.length; i++)
            {
              'name': teamName(i),
              'capacity': teams[i].capacity,
              'players': teams[i].players.map((p) => p.toJson()).toList(),
              'totals': {
                for (final s in Stat.values) s.name: teams[i].sumOf(s),
                'sum': teams[i].total,
              },
            },
        ],
        'bench': bench.map((p) => p.toJson()).toList(),
      };

  factory Lineup.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! int || version > schemaVersion) {
      throw const FormatException('지원하지 않는 파일 형식입니다.');
    }
    List<Player> players(Object? list) => [
          for (final p in (list as List? ?? const []))
            Player.fromJson((p as Map).cast<String, dynamic>()),
        ];
    final teams = [
      for (final t in (json['teams'] as List? ?? const []))
        () {
          final m = (t as Map).cast<String, dynamic>();
          final ps = players(m['players']);
          return Team(
            players: ps,
            capacity: (m['capacity'] as num?)?.toInt() ??
                ps.length + emptySlotsPerTeam,
          );
        }(),
    ];
    final bench = players(json['bench']);
    final attendees = (json['attendees'] as List?)?.cast<String>().toSet() ??
        {for (final p in [...teams.expand((t) => t.players), ...bench]) p.id};
    final count = (json['teamCount'] as num?)?.toInt() ?? teams.length;
    return Lineup(
      date: parseDateKey(json['matchDate'] as String),
      mode: BuildMode.values.firstWhere((m) => m.name == json['mode'],
          orElse: () => BuildMode.balanced),
      teamCount: teamCountOptions.contains(count) ? count : 2,
      attendees: attendees,
      teams: teams,
      bench: bench,
      confirmed: json['confirmed'] as bool? ?? false,
      confirmedAt: DateTime.tryParse(json['confirmedAt'] as String? ?? ''),
    );
  }
}

String formatDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseDateKey(String s) {
  final d = DateTime.parse(s);
  return DateTime(d.year, d.month, d.day);
}
