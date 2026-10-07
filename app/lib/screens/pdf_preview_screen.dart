import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lineup.dart';
import '../models/player.dart';
import '../state/app_state.dart';
import '../util/format.dart';

/// [출력] 버튼으로 만들어지는 PDF와 같은 내용을 화면에서 미리 보여 준다.
class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lineup = state.lineup;
    const ink = Color(0xFF111111);
    const border = BorderSide(color: Color(0xFF999999));

    Widget cell(String s, {bool head = false, bool left = false}) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Text(s,
              textAlign: left ? TextAlign.left : TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: ink,
                  fontWeight: head ? FontWeight.w700 : FontWeight.w400)),
        );

    Widget table(int i, Team t) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: const BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  border: Border(top: border, left: border, right: border)),
              child: Text('${teamName(i)} (${t.players.length}명)',
                  style: const TextStyle(
                      color: ink, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            Table(
              border: const TableBorder(
                  top: border,
                  bottom: border,
                  left: border,
                  right: border,
                  horizontalInside: border,
                  verticalInside: border),
              columnWidths: const {0: FlexColumnWidth(2)},
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFEEEEEE)),
                  children: [
                    cell('이름', head: true, left: true),
                    for (final s in Stat.values) cell(s.label, head: true),
                    cell('합계', head: true),
                  ],
                ),
                for (final p in t.players)
                  TableRow(children: [
                    cell(p.name, left: true),
                    for (final s in Stat.values) cell('${p.stats[s]}'),
                    cell('${p.total}'),
                  ]),
                TableRow(children: [
                  cell('팀 합계', head: true, left: true),
                  for (final s in Stat.values) cell('${t.sumOf(s)}', head: true),
                  cell('${t.total}', head: true),
                ]),
              ],
            ),
          ]),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(children: [
            AspectRatio(
              aspectRatio: 1 / 1.414,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 18, offset: Offset(0, 4)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Text('풋살 팀 편성표',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('경기일 ${formatKoreanDate(lineup.date)} · ${lineup.mode.label} 편성',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
                    const SizedBox(height: 18),
                    if (!state.locked)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Text('경기 편성 탭에서 [팀 구성] → [팀 확정]을 누르면\n여기에 편성표가 표시됩니다.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF777777))),
                      )
                    else ...[
                      for (var i = 0; i < lineup.teams.length; i++) table(i, lineup.teams[i]),
                      if (lineup.bench.isNotEmpty)
                        Text.rich(TextSpan(style: const TextStyle(color: ink, fontSize: 12), children: [
                          const TextSpan(text: '교체대기: ', style: TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: lineup.bench.map((p) => p.name).join(', ')),
                        ])),
                    ],
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('경기 편성 탭의 [출력] 버튼을 누르면 이 내용이 A4 PDF 파일로 저장됩니다.',
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ]),
        ),
      ),
    );
  }
}
