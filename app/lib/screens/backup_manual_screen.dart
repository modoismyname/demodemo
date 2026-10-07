import 'package:flutter/material.dart';

import '../widgets/credit_footer.dart';

/// 명단 백업/복원 사용법.
class BackupManualScreen extends StatelessWidget {
  const BackupManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('명단 백업/복원 사용법')),
      bottomNavigationBar: const CreditFooter(),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: const [
              _Section(
                icon: Icons.info_outline,
                title: '왜 백업해야 하나요?',
                body: [
                  _P('선수 명단과 능력치는 서버가 아니라 지금 쓰는 기기의 브라우저 안에만 저장됩니다.'),
                  _Bullet('브라우저 데이터를 지우거나 폰을 바꾸면 명단이 사라집니다.'),
                  _Bullet(
                    '아이폰 Safari는 7일 동안 열지 않은 사이트의 데이터를 지울 수 있습니다. 홈 화면에 추가해서 쓰면 이 규칙에서 제외됩니다.',
                  ),
                  _Bullet('폰, PC 등 기기끼리는 데이터가 자동으로 공유되지 않습니다.'),
                  _P('선수를 새로 등록하거나 능력치를 바꾼 뒤에는 [명단 백업]을 한 번 눌러 두세요.'),
                ],
              ),
              _Section(
                icon: Icons.save_alt,
                title: '백업하기',
                body: [
                  _Step(1, '[선수 관리] 탭에서 [명단 백업]을 누릅니다.'),
                  _Step(2, '기기에 따라 아래처럼 저장합니다.'),
                  _Device(
                    '아이폰',
                    '공유 시트가 열리면 "파일에 저장" → iCloud Drive 등 원하는 폴더 → [저장]. 카카오톡 "나와의 채팅"으로 보내 두어도 됩니다.',
                  ),
                  _Device(
                    '안드로이드',
                    '"다운로드" 폴더에 바로 저장됩니다. 내 파일 앱 → 다운로드에서 확인하세요.',
                  ),
                  _Device('PC', '브라우저의 다운로드 폴더에 저장됩니다.'),
                  _Step(
                    3,
                    '파일 이름은 futsal_roster_날짜.json 입니다. 버튼 옆에 "마지막 백업: 날짜"가 표시됩니다.',
                  ),
                ],
              ),
              _Section(
                icon: Icons.restore,
                title: '복원하기',
                body: [
                  _Step(1, '[선수 관리] 탭에서 [명단 복원]을 누릅니다.'),
                  _Step(2, '백업해 둔 futsal_roster_날짜.json 파일을 고릅니다.'),
                  _Step(3, '복원 방법을 고릅니다.'),
                  _Device(
                    '합치기',
                    '지금 명단은 그대로 둡니다. 같은 선수(같은 이름)는 파일의 능력치로 바꾸고, 파일에만 있는 선수는 추가합니다. 잘 모르겠으면 합치기를 고르세요.',
                  ),
                  _Device(
                    '바꾸기',
                    '지금 명단을 지우고 파일의 명단으로 바꿉니다. 파일에 없는 선수는 참석 체크에서도 빠집니다.',
                  ),
                  _Step(4, '"명단을 복원했습니다. 추가 n명 갱신 n명" 안내가 나오면 끝입니다.'),
                ],
              ),
              _Section(
                icon: Icons.phonelink,
                title: '다른 기기로 옮기기',
                body: [
                  _Step(1, '쓰던 기기에서 [명단 백업]을 합니다.'),
                  _Step(
                    2,
                    '파일을 새 기기로 보냅니다. 카카오톡 "나와의 채팅", 이메일, iCloud Drive, 구글 드라이브 등을 쓰면 됩니다.',
                  ),
                  _Step(
                    3,
                    '새 기기에서 앱을 열고 [선수 관리] → [명단 복원] → 파일 선택 → [합치기]를 누릅니다.',
                  ),
                ],
              ),
              _Section(
                icon: Icons.help_outline,
                title: '자주 묻는 질문',
                body: [
                  _QA(
                    '팀 확정 때 저장되는 파일과 무엇이 다른가요?',
                    '팀 확정 파일(futsal_teams_날짜.json)에는 그날 참석한 선수와 팀 편성만 들어 있고, [경기 편성] → [불러오기]로 엽니다. 명단 백업 파일(futsal_roster_날짜.json)에는 불참 선수까지 포함한 전체 명단이 들어 있고, [명단 복원]으로 엽니다.',
                  ),
                  _QA(
                    '파일을 잘못 고르면 어떻게 되나요?',
                    '명단이 바뀌지 않고 "명단 백업 파일을 읽을 수 없습니다"라는 안내만 나옵니다. 팀 확정 파일을 [명단 복원]에 넣거나, 명단 백업 파일을 [불러오기]에 넣어도 안내가 나옵니다.',
                  ),
                  _QA(
                    '아이폰에서 파일이 회색으로 보여서 고를 수 없어요.',
                    '"파일" 앱에서 파일이 iCloud에서 내려받아졌는지 확인하세요. 구름 아이콘이 있으면 한 번 눌러 내려받은 뒤 다시 고르세요.',
                  ),
                  _QA(
                    '백업은 얼마나 자주 하나요?',
                    '선수를 추가하거나 능력치를 바꿀 때마다 하는 것을 권장합니다. 새 파일이 생기므로 가장 최근 날짜의 파일로 복원하면 됩니다.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: scheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...body,
          ],
        ),
      ),
    );
  }
}

const _bodyStyle = TextStyle(fontSize: 14.5, height: 1.5);

class _P extends StatelessWidget {
  const _P(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text(text, style: _bodyStyle),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  ', style: _bodyStyle),
        Expanded(child: Text(text, style: _bodyStyle)),
      ],
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(right: 10, top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ),
          Expanded(child: Text(text, style: _bodyStyle)),
        ],
      ),
    );
  }
}

class _Device extends StatelessWidget {
  const _Device(this.label, this.text);
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 3, bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8, top: 1),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(child: Text(text, style: _bodyStyle)),
        ],
      ),
    );
  }
}

class _QA extends StatelessWidget {
  const _QA(this.q, this.a);
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Q. $q', style: _bodyStyle.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('A. $a', style: _bodyStyle),
      ],
    ),
  );
}
