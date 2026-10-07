import 'package:flutter/material.dart';

import 'match_screen.dart';
import 'pdf_preview_screen.dart';
import 'players_screen.dart';
import '../widgets/credit_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _tabs = ['경기 편성', '선수 관리', 'PDF 미리보기'];

  void _goTo(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.sports_soccer),
        SizedBox(width: 8),
        Text('풋살 팀 밸런서', style: TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
    final tabButtons = [
      for (var i = 0; i < _tabs.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: TextButton(
            onPressed: () => _goTo(i),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(
                alpha: i == _tab ? 1 : .75,
              ),
              backgroundColor: i == _tab
                  ? Colors.white.withValues(alpha: .18)
                  : null,
              shape: const StadiumBorder(),
            ),
            child: Text(
              _tabs[i],
              style: TextStyle(
                fontWeight: i == _tab ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ),
    ];

    final body = IndexedStack(
      index: _tab,
      children: [
        MatchScreen(onShowPreview: () => _goTo(2)),
        const PlayersScreen(),
        const PdfPreviewScreen(),
      ],
    );

    return Scaffold(
      bottomNavigationBar: const CreditFooter(),
      appBar: AppBar(
        title: title,
        actions: wide ? [...tabButtons, const SizedBox(width: 12)] : null,
        bottom: wide
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: tabButtons),
                  ),
                ),
              ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: body,
        ),
      ),
    );
  }
}
