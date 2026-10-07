import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

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
  Timer(const Duration(seconds: 5), () => web.URL.revokeObjectURL(url));
}

/// 파일 선택 창을 열고 고른 파일의 텍스트를 돌려준다. 취소하면 null.
Future<String?> pickTextFile({String accept = '.json,application/json'}) {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;
  input.onchange = (web.Event _) {
    final file = input.files?.item(0);
    if (file == null) {
      completer.complete(null);
      return;
    }
    file.text().toDart.then(
          (t) => completer.complete(t.toDart),
          onError: completer.completeError,
        );
  }.toJS;
  input.oncancel = (web.Event _) {
    if (!completer.isCompleted) completer.complete(null);
  }.toJS;
  input.click();
  return completer.future;
}

enum ShareImageResult { copied, shared, unsupported }

/// PNG 이미지를 클립보드에 복사한다. 안 되면 기기 공유 메뉴를 시도한다.
Future<ShareImageResult> copyOrSharePng(Uint8List png, String fileName) async {
  final blob = web.Blob([png.toJS].toJS, web.BlobPropertyBag(type: 'image/png'));
  try {
    final items = JSObject()..setProperty('image/png'.toJS, blob);
    await web.window.navigator.clipboard
        .write([web.ClipboardItem(items)].toJS)
        .toDart;
    return ShareImageResult.copied;
  } catch (_) {
    // 클립보드 이미지 복사를 지원하지 않는 브라우저
  }
  try {
    final file = web.File([png.toJS].toJS, fileName,
        web.FilePropertyBag(type: 'image/png'));
    final data = web.ShareData(files: [file].toJS);
    if (web.window.navigator.canShare(data)) {
      await web.window.navigator.share(data).toDart;
      return ShareImageResult.shared;
    }
  } catch (_) {
    // 공유 취소 또는 미지원
  }
  return ShareImageResult.unsupported;
}
