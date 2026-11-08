import 'dart:io';

import 'package:flutter/services.dart';

/// Вызывать из setUpAll: внутри testWidgets часы поддельные и загрузка зависает.
/// Подключает настоящие шрифты вместо тестового Ahem, чтобы раскладка совпадала с телефоном.
Future<void> loadTestFonts() async {
  // flutter_tester лежит внутри SDK: .../bin/cache/artifacts/engine/<платформа>/flutter_tester.
  final exe = Platform.resolvedExecutable.replaceAll(r'\', '/');
  final cache = exe.substring(0, exe.indexOf('/bin/cache/') + '/bin/cache'.length);
  final dir = '$cache/artifacts/material_fonts';
  Future<void> font(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(Future.value(ByteData.view(File('$dir/$f').readAsBytesSync().buffer)));
    }
    await l.load();
  }

  await font('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']);
  await font('MaterialIcons', ['materialicons-regular.otf']);
}
