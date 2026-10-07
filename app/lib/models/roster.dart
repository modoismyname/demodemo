import 'player.dart';

/// 전체 선수 명단 백업 파일 (futsal_roster_YYYY-MM-DD.json).
class RosterBackup {
  const RosterBackup(this.players, {this.exportedAt});

  static const String type = 'futsal-roster';
  static const int schemaVersion = 1;

  final List<Player> players;
  final DateTime? exportedAt;

  Map<String, dynamic> toJson() => {
        'type': type,
        'schemaVersion': schemaVersion,
        'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory RosterBackup.fromJson(Map<String, dynamic> json) {
    if (json['type'] != type) {
      throw const FormatException('명단 백업 파일이 아닙니다.');
    }
    final version = json['schemaVersion'];
    if (version is! int || version > schemaVersion) {
      throw const FormatException('지원하지 않는 파일 형식입니다.');
    }
    return RosterBackup(
      [
        for (final p in (json['players'] as List? ?? const []))
          Player.fromJson((p as Map).cast<String, dynamic>()),
      ],
      exportedAt: DateTime.tryParse(json['exportedAt'] as String? ?? ''),
    );
  }
}
