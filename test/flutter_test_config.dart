import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  ScreenUtil.configure(
    data: const MediaQueryData(size: Size(800, 600)),
    designSize: const Size(800, 600),
    minTextAdapt: false,
    splitScreenMode: false,
  );
  await testMain();
}
