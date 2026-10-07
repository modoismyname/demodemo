import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../models/lineup.dart';
import '../theme.dart';
import '../util/format.dart';
import 'fonts.dart';

/// 팀별 명단(이름만)을 PNG 이미지로 그린다. 능력치와 점수는 넣지 않는다.
Future<Uint8List> buildShareImage(Lineup lineup) async {
  await ensureBoldFont();

  final groups = <(String, Color, List<String>)>[
    for (var i = 0; i < lineup.teams.length; i++)
      (
        teamName(i),
        teamColors[i],
        lineup.teams[i].players.map((p) => p.name).toList(),
      ),
    if (lineup.bench.isNotEmpty)
      ('교체대기', benchColor, lineup.bench.map((p) => p.name).toList()),
  ];

  const width = 720.0, pad = 32.0, gap = 20.0, headerH = 96.0;
  const rowH = 40.0, titleH = 52.0;
  final cols = min(groups.length, 2);
  final rows = (groups.length / cols).ceil();
  final maxNames = groups.map((g) => g.$3.length).reduce(max);
  final cardW = (width - pad * 2 - gap * (cols - 1)) / cols;
  final cardH = titleH + 20 + maxNames * rowH;
  final height = headerH + 24 + rows * (cardH + gap) + 12;

  const scale = 2.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);

  void text(String s, Offset at, double size,
      {Color color = const Color(0xFF1B1F1C),
      bool bold = false,
      double? alignRightAt}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: bold ? boldFont : appFont,
          fontSize: size,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRightAt != null ? alignRightAt - tp.width : at.dx;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
      Paint()..color = const Color(0xFFF4F6F4));
  canvas.drawRect(
      Rect.fromLTWH(0, 0, width, headerH), Paint()..color = brandGreen);
  text('풋살 팀 편성', const Offset(pad, 38), 28,
      color: const Color(0xFFFFFFFF), bold: true);
  text(formatKoreanDate(lineup.date), const Offset(pad, 74), 17,
      color: const Color(0xFFFFFFFF));

  for (var i = 0; i < groups.length; i++) {
    final (title, color, names) = groups[i];
    final x = pad + (i % cols) * (cardW + gap);
    final y = headerH + 24 + (i ~/ cols) * (cardH + gap);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, cardW, cardH), const Radius.circular(14)),
        Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, y, cardW, titleH),
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14)),
        Paint()..color = color);
    text(title, Offset(x + 18, y + titleH / 2), 22,
        color: const Color(0xFFFFFFFF), bold: true);
    text('${names.length}명', Offset(x, y + titleH / 2), 16,
        color: const Color(0xFFFFFFFF), alignRightAt: x + cardW - 18);
    for (var j = 0; j < names.length; j++) {
      text('${j + 1}. ${names[j]}',
          Offset(x + 22, y + titleH + 10 + rowH * (j + 0.5)), 19);
    }
  }

  final image = await recorder
      .endRecording()
      .toImage((width * scale).round(), (height * scale).round());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
