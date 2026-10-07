import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/lineup.dart';
import '../models/player.dart';
import '../util/format.dart';
import 'fonts.dart';

/// 확정된 편성표를 A4 PDF로 만든다.
Future<Uint8List> buildLineupPdf(Lineup lineup) async {
  final regular = pw.Font.ttf(await rootBundle.load(regularFontAsset));
  final bold = pw.Font.ttf(await rootBundle.load(boldFontAsset));
  final doc = pw.Document(
    title: '풋살 팀 편성표 ${lineup.dateKey}',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );

  final headerStyle = pw.TextStyle(font: bold, fontSize: 10);
  const cellStyle = pw.TextStyle(fontSize: 10);

  pw.Widget teamTable(int index, Team team) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          color: PdfColors.grey300,
          child: pw.Text('${teamName(index)} (${team.players.length}명)',
              style: pw.TextStyle(font: bold, fontSize: 12)),
        ),
        pw.TableHelper.fromTextArray(
          headers: ['이름', ...Stat.values.map((s) => s.label), '합계'],
          data: [
            for (final p in team.players)
              [p.name, ...Stat.values.map((s) => '${p.stats[s]}'), '${p.total}'],
            ['팀 합계', ...Stat.values.map((s) => '${team.sumOf(s)}'), '${team.total}'],
          ],
          headerStyle: headerStyle,
          cellStyle: cellStyle,
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.center,
          cellAlignments: {0: pw.Alignment.centerLeft},
          columnWidths: {0: const pw.FlexColumnWidth(2)},
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => [
        pw.Center(
          child: pw.Text('풋살 팀 편성표',
              style: pw.TextStyle(font: bold, fontSize: 20)),
        ),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            '경기일 ${formatKoreanDate(lineup.date)} · ${lineup.mode.label} 편성',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 18),
        for (var i = 0; i < lineup.teams.length; i++)
          teamTable(i, lineup.teams[i]),
        if (lineup.bench.isNotEmpty)
          pw.RichText(
            text: pw.TextSpan(children: [
              pw.TextSpan(text: '교체대기: ', style: pw.TextStyle(font: bold)),
              pw.TextSpan(text: lineup.bench.map((p) => p.name).join(', ')),
            ]),
          ),
      ],
    ),
  );
  return doc.save();
}
