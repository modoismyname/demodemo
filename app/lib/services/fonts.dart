import 'package:flutter/services.dart';

const String appFont = 'NotoSansKR';
const String boldFont = 'NotoSansKRBold';
const String regularFontAsset = 'assets/fonts/NotoSansKR-Regular.ttf';
const String boldFontAsset = 'assets/fonts/NotoSansKR-Bold.ttf';

Future<void>? _boldLoading;

/// 굵은 글꼴은 용량이 커서 공유 이미지를 처음 만들 때만 불러온다.
Future<void> ensureBoldFont() => _boldLoading ??= (FontLoader(boldFont)
      ..addFont(rootBundle.load(boldFontAsset)))
    .load();
