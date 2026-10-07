import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/player.dart';
import '../state/app_state.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _add() {
    final state = context.read<AppState>();
    final name = _name.text.trim();
    if (name.isEmpty) return;
    if (state.addPlayer(name)) {
      _name.clear();
    } else {
      _snack('이미 같은 이름의 선수가 있습니다.');
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _rename(Player p) async {
    final ctrl = TextEditingController(text: p.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('이름 수정'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: '이름'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('저장')),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || !mounted) return;
    if (!context.read<AppState>().renamePlayer(p, name)) {
      _snack('이름이 비어 있거나 이미 같은 이름의 선수가 있습니다.');
    }
  }

  Future<void> _delete(Player p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('선수 삭제'),
        content: Text('${p.name} 선수를 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) context.read<AppState>().deletePlayer(p);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final players = state.players;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 760;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(children: [
                const TextSpan(
                    text: '선수 목록 ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                TextSpan(
                    text: '${players.length}명',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  width: 160,
                  child: TextField(
                    key: const Key('newPlayerName'),
                    controller: _name,
                    decoration: const InputDecoration(
                        hintText: '이름 입력', isDense: true, border: OutlineInputBorder()),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const Key('addPlayer'),
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                  label: const Text('선수 추가'),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text('등록된 선수가 없습니다. 이름을 입력하고 [선수 추가]를 누르세요.',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ),
            ),
          if (players.isNotEmpty && wide) _header(context),
          for (final p in players)
            wide ? _wideRow(context, state, p) : _card(context, state, p),
          const SizedBox(height: 12),
          Text('능력치는 1·2·3을 누르면 바로 바뀌고 자동 저장됩니다. 새 선수는 모든 항목이 2로 시작합니다.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        ],
      );
    });
  }

  Widget _header(BuildContext context) {
    final style = TextStyle(
        fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(flex: 3, child: Text('이름', style: style)),
        for (final s in Stat.values)
          Expanded(flex: 2, child: Center(child: Text(s.label, style: style))),
        SizedBox(width: 48, child: Center(child: Text('합계', style: style))),
        const SizedBox(width: 96),
      ]),
    );
  }

  Widget _wideRow(BuildContext context, AppState state, Player p) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(
          flex: 3,
          child: Text(p.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis),
        ),
        for (final s in Stat.values)
          Expanded(
            flex: 2,
            child: Center(child: LevelSelector(player: p, stat: s, state: state)),
          ),
        SizedBox(width: 48, child: Center(child: _total(context, p))),
        SizedBox(width: 96, child: _actions(p)),
      ]),
    );
  }

  Widget _card(BuildContext context, AppState state, Player p) {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant))),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(p.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Text('합계 ', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          _total(context, p),
          _actions(p),
        ]),
        const SizedBox(height: 4),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final s in Stat.values)
              SizedBox(
                width: 150,
                child: Row(children: [
                  SizedBox(
                      width: 48,
                      child: Text(s.label,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant))),
                  LevelSelector(player: p, stat: s, state: state),
                ]),
              ),
          ],
        ),
      ]),
    );
  }

  Widget _total(BuildContext context, Player p) => Text('${p.total}',
      style: TextStyle(
          fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.primary));

  Widget _actions(Player p) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
              tooltip: '이름 수정',
              onPressed: () => _rename(p),
              icon: const Icon(Icons.edit_outlined, size: 20)),
          IconButton(
              tooltip: '삭제',
              onPressed: () => _delete(p),
              icon: Icon(Icons.delete_outline,
                  size: 20, color: Theme.of(context).colorScheme.error)),
        ],
      );
}

/// 1·2·3 레벨 선택 버튼.
class LevelSelector extends StatelessWidget {
  const LevelSelector(
      {super.key, required this.player, required this.stat, required this.state});

  final Player player;
  final Stat stat;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final current = player.stats[stat];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var v = minLevel; v <= maxLevel; v++)
          Semantics(
            button: true,
            selected: v == current,
            label: '${player.name} ${stat.label} $v',
            excludeSemantics: true,
            onTap: () => state.setStat(player, stat, v),
            child: InkWell(
              onTap: () => state.setStat(player, stat, v),
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                color: v == current ? scheme.primary : null,
                child: Text('$v',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: v == current ? FontWeight.w700 : FontWeight.w400,
                      color: v == current ? scheme.onPrimary : scheme.onSurface,
                    )),
              ),
            ),
          ),
      ]),
    );
  }
}
