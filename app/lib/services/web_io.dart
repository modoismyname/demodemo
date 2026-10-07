import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// 아이폰/아이패드(Safari, 홈 화면 앱 포함) 여부.
/// iPadOS는 데스크톱 UA를 쓰므로 터치 지점 수로 구분한다.
final bool isIOS = () {
  final nav = web.window.navigator;
  final ua = nav.userAgent;
  return RegExp('iPhone|iPad|iPod').hasMatch(ua) ||
      (ua.contains('Macintosh') && nav.maxTouchPoints > 1);
}();

/// 브라우저에서 파일을 내려받는다.
void downloadBytes(Uint8List bytes, String fileName, String mimeType) {
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body!.append(a);
  a.click();
  a.remove();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}

web.File _file(Uint8List bytes, String fileName, String mimeType) =>
    web.File([bytes.toJS].toJS, fileName, web.FilePropertyBag(type: mimeType));

/// 기기 공유 메뉴(아이폰의 공유 시트)를 연다.
/// 반드시 버튼을 누른 직후 다른 await 없이 호출해야 Safari가 허용한다.
/// 공유 메뉴를 열 수 없으면 false. 사용자가 공유 메뉴를 닫은 경우도 true.
Future<bool> shareFile(Uint8List bytes, String fileName, String mimeType) async {
  final data = web.ShareData(files: [_file(bytes, fileName, mimeType)].toJS);
  try {
    if (!web.window.navigator.canShare(data)) return false;
  } catch (_) {
    return false; // canShare 미지원
  }
  try {
    await web.window.navigator.share(data).toDart;
    return true;
  } catch (e) {
    // AbortError = 사용자가 공유 메뉴를 닫음
    return e.toString().contains('AbortError');
  }
}

/// 파일 저장. 아이폰에서는 공유 시트로 열어 "파일에 저장"을 고르게 하고,
/// 그 밖에는 바로 내려받는다.
Future<void> saveFile(Uint8List bytes, String fileName, String mimeType) async {
  if (isIOS && await shareFile(bytes, fileName, mimeType)) return;
  downloadBytes(bytes, fileName, mimeType);
}

/// 파일 선택 창을 열고 고른 파일의 텍스트를 돌려준다. 취소하면 null.
Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..style.display = 'none';
  // 아이폰은 accept=".json"이면 JSON 파일이 회색으로 비활성화되는 경우가 있어 필터를 두지 않는다.
  if (!isIOS) input.accept = '.json,application/json';
  web.document.body!.append(input);

  void finish(String? text) {
    if (!completer.isCompleted) completer.complete(text);
    input.remove();
  }

  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      finish(null);
      return;
    }
    file.text().toDart.then((t) => finish(t.toDart), onError: (Object e) {
      if (!completer.isCompleted) completer.completeError(e);
      input.remove();
    });
  }.toJS;
  input.oncancel = (web.Event _) {
    finish(null);
  }.toJS;
  input.click();
  return completer.future;
}

enum ShareImageResult { copied, shared, unsupported }

/// PNG 이미지를 클립보드에 복사한다. 안 되면 기기 공유 메뉴를 시도한다.
Future<ShareImageResult> copyPng(Uint8List png, String fileName) async {
  try {
    final blob =
        web.Blob([png.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
    final items = JSObject()..setProperty('image/png'.toJS, blob);
    await web.window.navigator.clipboard
        .write([web.ClipboardItem(items)].toJS)
        .toDart;
    return ShareImageResult.copied;
  } catch (_) {
    // 클립보드 이미지 복사를 지원하지 않는 브라우저
  }
  return await shareFile(png, fileName, 'image/png')
      ? ShareImageResult.shared
      : ShareImageResult.unsupported;
}
