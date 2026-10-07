import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lineup.dart';
import '../models/player.dart';
import '../services/pdf_service.dart';
import '../services/share_image.dart';
import '../services/web_io.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../util/format.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key, required this.onShowPreview});

  final VoidCallback onShowPreview;

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  final _scroller = _DragAutoScroller();

  @override
  void dispose() {
    _scroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final attendance = _AttendanceCard(
          maxHeight: wide ? 520 : 320,
          collapsible: !wide,
        );
        const result = _ResultArea();
        return _AutoScrollScope(
          scroller: _scroller,
          child: ListView(
            key: _scroller.viewportKey,
            controller: _scroller.controller,
            padding: const EdgeInsets.all(16),
            children: [
              const _Toolbar(),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 300, child: attendance),
                    const SizedBox(width: 16),
                    const Expanded(child: result),
                  ],
                )
              else ...[
                attendance,
                const SizedBox(height: 16),
                result,
              ],
            ],
          ),
        );
      },
    );
  }
}

/// 휴대폰에서 선수를 끌어 화면 위/아래 가장자리에 가져가면 목록을 자동으로 스크롤한다.
class _DragAutoScroller {
  final controller = ScrollController();
  final viewportKey = GlobalKey();
  Timer? _timer;
  double? _pointerY;

  static const _edge = 80.0;
  static const _maxStep = 14.0;

  void update(Offset globalPosition) {
    _pointerY = globalPosition.dy;
    _timer ??= Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _pointerY = null;
  }

  void _tick() {
    final box = viewportKey.currentContext?.findRenderObject() as RenderBox?;
    final y = _pointerY;
    if (box == null || y == null || !controller.hasClients) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final bottom = top + box.size.height;
    double step = 0;
    if (y < top + _edge) {
      step = -_maxStep * ((top + _edge - y) / _edge).clamp(0.2, 1.0);
    } else if (y > bottom - _edge) {
      step = _maxStep * ((y - (bottom - _edge)) / _edge).clamp(0.2, 1.0);
    }
    if (step == 0) return;
    final pos = controller.position;
    final next = (pos.pixels + step).clamp(
      pos.minScrollExtent,
      pos.maxScrollExtent,
    );
    if (next != pos.pixels) controller.jumpTo(next);
  }

  void dispose() {
    stop();
    controller.dispose();
  }
}

class _AutoScrollScope extends InheritedWidget {
  const _AutoScrollScope({required this.scroller, required super.child});

  final _DragAutoScroller scroller;

  static _DragAutoScroller? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AutoScrollScope>()?.scroller;

  @override
  bool updateShouldNotify(_AutoScrollScope oldWidget) =>
      scroller != oldWidget.scroller;
}

void _snack(BuildContext context, String msg) => ScaffoldMessenger.of(context)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(content: Text(msg)));

String _fileBase(Lineup l) => 'futsal_teams_${l.dateKey}';

// ---------------------------------------------------------------------------
// 상단 도구 막대

class _Toolbar extends StatelessWidget {
  const _Toolbar();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lineup = state.lineup;
    final locked = state.locked;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          key: const Key('datePicker'),
          onPressed: () => _pickDate(context, state),
          icon: const Icon(Icons.event),
          label: Text('경기일 ${formatKoreanDate(lineup.date)}'),
        ),
        SegmentedButton<int>(
          key: const Key('teamCount'),
          segments: [
            for (final n in teamCountOptions)
              ButtonSegment(value: n, label: Text('$n팀')),
          ],
          selected: {lineup.teamCount},
          showSelectedIcon: false,
          onSelectionChanged: locked
              ? null
              : (s) => state.setTeamCount(s.first),
        ),
        SegmentedButton<BuildMode>(
          key: const Key('buildMode'),
          segments: [
            for (final m in BuildMode.values)
              ButtonSegment(value: m, label: Text(m.label)),
          ],
          selected: {lineup.mode},
          showSelectedIcon: false,
          onSelectionChanged: locked ? null : (s) => state.setMode(s.first),
        ),
        OutlinedButton(
          key: const Key('load'),
          onPressed: () => _load(context, state),
          child: const Text('불러오기'),
        ),
        FilledButton(
          key: const Key('build'),
          onPressed: locked || state.plan == null ? null : state.build,
          child: Text(lineup.hasTeams && !locked ? '다시 구성' : '팀 구성'),
        ),
        if (!locked)
          OutlinedButton(
            key: const Key('confirm'),
            onPressed: lineup.hasTeams ? () => _confirm(context, state) : null,
            child: const Text('팀 확정'),
          )
        else
          OutlinedButton.icon(
            key: const Key('unlock'),
            onPressed: state.unlock,
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text('수정'),
          ),
        OutlinedButton(
          key: const Key('print'),
          onPressed: locked ? () => _print(context, state) : null,
          child: const Text('출력'),
        ),
        OutlinedButton(
          key: const Key('share'),
          onPressed: locked ? () => _share(context, state) : null,
          child: const Text('공유'),
        ),
      ],
    );
  }

  Future<void> _pickDate(BuildContext context, AppState state) async {
    final d = await showDatePicker(
      context: context,
      initialDate: state.lineup.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: '경기 날짜 선택',
    );
    if (d != null) state.selectDate(d);
  }

  Future<void> _confirm(BuildContext context, AppState state) async {
    final invalid = state.invalidTeams;
    if (invalid.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('확정할 수 없습니다'),
          content: Text(
            '${invalid.join(', ')}의 인원이 $minTeamSize~$maxTeamSize명이 아닙니다.\n선수를 옮겨 인원을 맞춰 주세요.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }
    if (!state.confirm()) return;
    final json = const JsonEncoder.withIndent('  ')
        .convert(state.lineup.toJson());
    final name = '${_fileBase(state.lineup)}.json';
    // await 전에 바로 호출해야 아이폰 Safari가 공유 시트를 허용한다.
    final saving = saveFile(
      Uint8List.fromList(utf8.encode(json)),
      name,
      'application/json',
    );
    _snack(context, '팀을 확정했습니다. $name 파일로 저장합니다.');
    await saving;
  }

  Future<void> _load(BuildContext context, AppState state) async {
    try {
      final text = await pickTextFile();
      if (text == null) return;
      final lineup = Lineup.fromJson(
        (jsonDecode(text) as Map).cast<String, dynamic>(),
      );
      final added = state.importLineup(lineup);
      if (!context.mounted) return;
      _snack(
        context,
        '${formatKoreanDate(lineup.date)} 편성을 불러왔습니다.'
        '${added > 0 ? ' 명단에 없던 선수 $added명을 추가했습니다.' : ''}',
      );
    } catch (_) {
      if (context.mounted) {
        _snack(context, '파일을 읽을 수 없습니다. 이 앱에서 저장한 JSON 파일인지 확인해 주세요.');
      }
    }
  }

  Future<void> _print(BuildContext context, AppState state) async {
    final bytes = await buildLineupPdf(state.lineup);
    final name = '${_fileBase(state.lineup)}.pdf';
    if (!context.mounted) return;
    if (!isIOS) {
      downloadBytes(bytes, name, 'application/pdf');
      _snack(context, '$name 파일로 저장했습니다.');
      return;
    }
    // 아이폰은 PDF를 만드는 동안 버튼 누름이 만료되므로, 한 번 더 눌러 공유 시트를 연다.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PDF가 준비되었습니다'),
        content: Text('[저장/공유]를 누른 뒤 "파일에 저장"이나 프린트를 고르세요.\n$name'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
          FilledButton(
            key: const Key('savePdf'),
            onPressed: () {
              saveFile(bytes, name, 'application/pdf');
              Navigator.pop(ctx);
            },
            child: const Text('저장/공유'),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, AppState state) async {
    final png = await buildShareImage(state.lineup);
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) =>
          _ShareDialog(png: png, fileName: '${_fileBase(state.lineup)}.png'),
    );
  }
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.png, required this.fileName});

  final Uint8List png;
  final String fileName;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  String _message = '';

  Future<void> _shareSheet() async {
    final ok = await shareFile(widget.png, widget.fileName, 'image/png');
    if (!ok && mounted) {
      setState(() => _message = '공유 메뉴를 열 수 없습니다. [복사]를 이용하세요.');
    }
  }

  Future<void> _copy() async {
    final r = await copyPng(widget.png, widget.fileName);
    setState(
      () => _message = switch (r) {
        ShareImageResult.copied => '복사했습니다. 카카오톡 대화창 등에 붙여 넣으세요.',
        ShareImageResult.shared => '공유 메뉴로 보냈습니다.',
        ShareImageResult.unsupported =>
          '이 브라우저는 이미지 복사를 지원하지 않습니다. [이미지 저장]을 이용하세요.',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('팀 명단 공유'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(widget.png, key: const Key('shareImage')),
              ),
              const SizedBox(height: 10),
              Text(
                _message,
                key: const Key('shareMessage'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
      actions: isIOS
          ? [
              // 아이폰: 공유 시트에서 카카오톡 전송, "이미지 저장"(사진 앱)을 모두 고를 수 있다.
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
              OutlinedButton(onPressed: _copy, child: const Text('복사')),
              FilledButton(
                key: const Key('shareSheet'),
                onPressed: _shareSheet,
                child: const Text('공유/저장'),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
              OutlinedButton(
                onPressed: () {
                  downloadBytes(widget.png, widget.fileName, 'image/png');
                  setState(() => _message = '${widget.fileName} 파일로 저장했습니다.');
                },
                child: const Text('이미지 저장'),
              ),
              FilledButton(onPressed: _copy, child: const Text('이미지 복사')),
            ],
    );
  }
}

// ---------------------------------------------------------------------------
// 참석 체크

class _AttendanceCard extends StatefulWidget {
  const _AttendanceCard({required this.maxHeight, required this.collapsible});

  final double maxHeight;

  /// 휴대폰처럼 좁은 화면에서는 명단을 접을 수 있다. 팀이 구성되면 자동으로 접힌다.
  final bool collapsible;

  @override
  State<_AttendanceCard> createState() => _AttendanceCardState();
}

class _AttendanceCardState extends State<_AttendanceCard> {
  /// 사용자가 직접 펼치거나 접은 상태. null이면 팀 구성 여부에 따라 자동.
  bool? _expanded;
  bool _hadTeams = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final players = state.players;
    final allOn =
        players.isNotEmpty &&
        players.every((p) => state.lineup.attendees.contains(p.id));
    final maxHeight = widget.maxHeight;
    final hasTeams = state.lineup.hasTeams;
    if (hasTeams != _hadTeams) {
      _hadTeams = hasTeams;
      _expanded = null; // 팀이 생기거나 없어지면 자동 상태로 되돌린다
    }
    final expanded = !widget.collapsible || (_expanded ?? !hasTeams);

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const Key('attendanceHeader'),
                    onTap: widget.collapsible
                        ? () => setState(() => _expanded = !expanded)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            '참석 체크 ${state.attendingPlayers.length}/${players.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (widget.collapsible)
                            Icon(
                              expanded ? Icons.expand_less : Icons.expand_more,
                              color: scheme.onSurfaceVariant,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                TextButton(
                  key: const Key('toggleAll'),
                  onPressed: state.locked || players.isEmpty
                      ? null
                      : () => state.setAllAttending(!allOn),
                  child: Text(allOn ? '전체 해제' : '전체 선택'),
                ),
              ],
            ),
            if (players.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '[선수 관리] 탭에서 선수를 먼저 등록하세요.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
            if (expanded)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in players)
                      CheckboxListTile(
                        key: Key('attend-${p.name}'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: state.lineup.attendees.contains(p.id),
                        onChanged: state.locked
                            ? null
                            : (v) => state.setAttending(p, v ?? false),
                        title: Text(p.name),
                        secondary: Text(
                          '${p.total}점',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 편성 결과

class _ResultArea extends StatelessWidget {
  const _ResultArea();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lineup = state.lineup;
    final scheme = Theme.of(context).colorScheme;
    final n = state.attendingPlayers.length;
    final plan = state.plan;

    final String status;
    final bool bad = plan == null;
    if (plan == null) {
      status =
          '참석 $n명 · ${lineup.teamCount}팀 경기 불가 '
          '(최소 ${lineup.teamCount * minTeamSize}명 필요)';
    } else {
      status =
          '참석 $n명 → ${[for (var i = 0; i < plan.sizes.length; i++) '${teamName(i)} ${plan.sizes[i]}명'].join(' + ')}${plan.benchCount > 0 ? ' + 교체대기 ${plan.benchCount}명' : ''}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.locked)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '확정된 편성입니다. 편집하려면 [수정]을 누르세요.',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          key: const Key('status'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bad ? null : scheme.primaryContainer.withValues(alpha: .6),
            border: bad ? Border.all(color: scheme.error) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: bad ? scheme.error : null,
            ),
          ),
        ),
        if (lineup.hasTeams) ...[
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, c) {
              final cards = [
                for (var i = 0; i < lineup.teams.length; i++)
                  _TeamCard(index: i, team: lineup.teams[i]),
                if (lineup.bench.isNotEmpty || !state.locked)
                  const _BenchCard(),
              ];
              final cols = max(
                1,
                min(cards.length, (c.maxWidth / 220).floor()),
              );
              final w = (c.maxWidth - 12 * (cols - 1)) / cols;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards) SizedBox(width: w, child: card),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          if (!state.locked)
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: scheme.primary, width: 3),
                ),
              ),
              child: Text(
                '선수를 ${_touch ? '길게 눌러 ' : ''}끌어서 다른 팀의 빈 슬롯이나 교체대기로 옮길 수 있습니다. '
                '다른 선수 위에 놓으면 두 선수를 맞바꿉니다.',
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }
}

bool get _touch =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

class _TeamCard extends StatelessWidget {
  const _TeamCard({required this.index, required this.team});

  final int index;
  final Team team;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final color = teamColors[index];
    final scheme = Theme.of(context).colorScheme;
    final target = DropTarget.team(index);

    return _DropZone(
      target: target,
      color: color,
      child: Container(
        key: Key('team-$index'),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: color, width: 5),
            left: BorderSide(color: scheme.outlineVariant),
            right: BorderSide(color: scheme.outlineVariant),
            bottom: BorderSide(color: scheme.outlineVariant),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Text(
                    teamName(index),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${team.players.length}명 · 총점 ${team.total}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            if (!team.sizeValid)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: warnColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '팀 인원은 $minTeamSize~$maxTeamSize명이어야 합니다',
                      style: const TextStyle(color: warnColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  for (final p in team.players)
                    _PlayerTile(
                      player: p,
                      target: DropTarget.team(index, swapWith: p.id),
                    ),
                  if (!state.locked)
                    for (var s = 0; s < team.emptySlots; s++)
                      _EmptySlot(target: target, color: color),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  for (final s in Stat.values)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${team.sumOf(s)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            s.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchCard extends StatelessWidget {
  const _BenchCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final bench = state.lineup.bench;
    return _DropZone(
      target: const DropTarget.bench(),
      color: benchColor,
      child: Container(
        key: const Key('bench'),
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: const BorderSide(color: benchColor, width: 5),
            left: BorderSide(color: scheme.outlineVariant),
            right: BorderSide(color: scheme.outlineVariant),
            bottom: BorderSide(color: scheme.outlineVariant),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  const Text(
                    '교체대기',
                    style: TextStyle(
                      color: benchColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${bench.length}명',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  for (final p in bench)
                    _PlayerTile(
                      player: p,
                      target: DropTarget.bench(swapWith: p.id),
                    ),
                  if (bench.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '여기에 놓으면 교체대기로 이동합니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 전체를 놓기 영역으로 만든다. 빈 곳에 놓으면 빈 슬롯으로 이동.
class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.target,
    required this.color,
    required this.child,
  });

  final DropTarget target;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    if (state.locked) return child;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _applyMove(context, d.data, target),
      builder: (context, candidates, _) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: candidates.isNotEmpty
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: child,
      ),
    );
  }
}

void _applyMove(BuildContext context, String playerId, DropTarget target) {
  final r = context.read<AppState>().movePlayer(playerId, target);
  if (r == MoveResult.noSlot) {
    _snack(context, '빈 슬롯이 없습니다. 선수 위에 놓아 맞바꾸세요.');
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player, required this.target});

  final Player player;
  final DropTarget target;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;

    Widget tile({bool dragging = false, bool highlight = false}) => Container(
      key: dragging ? null : Key('player-${player.name}'),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.primaryContainer
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (!state.locked)
            Icon(
              Icons.drag_indicator,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          const SizedBox(width: 4),
          Expanded(child: Text(player.name, overflow: TextOverflow.ellipsis)),
          Text(
            '${player.total}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );

    if (state.locked) return tile();

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 200,
        child: Opacity(opacity: .9, child: tile(dragging: true)),
      ),
    );
    final child = DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != player.id,
      onAcceptWithDetails: (d) => _applyMove(context, d.data, target),
      builder: (context, candidates, _) =>
          tile(highlight: candidates.isNotEmpty),
    );
    final placeholder = Opacity(opacity: .35, child: tile(dragging: true));

    final scroller = _AutoScrollScope.of(context);
    void update(DragUpdateDetails d) => scroller?.update(d.globalPosition);
    void stop() => scroller?.stop();

    return _touch
        ? LongPressDraggable<String>(
            data: player.id,
            feedback: feedback,
            childWhenDragging: placeholder,
            delay: const Duration(milliseconds: 250),
            hapticFeedbackOnStart: true,
            onDragUpdate: update,
            onDragEnd: (_) => stop(),
            onDraggableCanceled: (_, _) => stop(),
            onDragCompleted: stop,
            child: child,
          )
        : Draggable<String>(
            data: player.id,
            feedback: feedback,
            childWhenDragging: placeholder,
            onDragUpdate: update,
            onDragEnd: (_) => stop(),
            onDraggableCanceled: (_, _) => stop(),
            onDragCompleted: stop,
            child: child,
          );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.target, required this.color});

  final DropTarget target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _applyMove(context, d.data, target),
      builder: (context, candidates, _) {
        final over = candidates.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(top: 4),
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: over ? color : scheme.outlineVariant,
              width: over ? 2 : 1.2,
            ),
          ),
          child: Text(
            '빈 슬롯',
            style: TextStyle(
              fontSize: 13,
              color: over ? color : scheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}
