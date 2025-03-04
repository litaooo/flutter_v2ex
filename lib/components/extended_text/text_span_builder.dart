import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:extended_text_library/extended_text_library.dart';

class MySpecialTextSpanBuilder extends SpecialTextSpanBuilder {
  MySpecialTextSpanBuilder({
    this.showAtBackground = false,
    this.controller,
  });

  /// whether show background for @somebody
  final bool showAtBackground;
  final TextEditingController? controller;

  @override
  SpecialText? createSpecialText(String flag,
      {TextStyle? textStyle,
      SpecialTextGestureTapCallback? onTap,
      int? index}) {
    if (flag == '') {
      return null;
    }

    ///index is end index of start flag, so text start index should be index-(flag.length-1)
    if (isStart(flag, AtText.flag)) {
      return AtText(textStyle, onTap,
          start: index! - (AtText.flag.length - 1),
          showAtBackground: showAtBackground,
          controller: controller);
    }
    return null;
  }
}

class AtText extends SpecialText {
  AtText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {this.showAtBackground = false, this.start, this.controller})
      : super(flag, ' ', textStyle, onTap: onTap);
  static const String flag = '@';
  final int? start;
  final TextEditingController? controller;

  /// whether show background for @somebody
  final bool showAtBackground;

  @override
  InlineSpan finishText() {
    final TextStyle? textStyle = this.textStyle?.copyWith(
        color: Theme.of(Get.context!).colorScheme.primary, fontSize: 16.0);

    final String atText = toString();

    return showAtBackground
        ? BackgroundTextSpan(
            background: Paint()
              ..color =
                  Theme.of(Get.context!).colorScheme.primary.withOpacity(0.15),
            text: atText,
            actualText: atText,
            start: start!,

            ///caret can move into special text
            deleteAll: true,
            style: textStyle,
            recognizer: (TapGestureRecognizer()
              ..onTap = () {
                if (onTap != null) {
                  onTap!(atText);
                }
              }))
        /// 点击@userName可直接删除  Text.rich与普通文本内容高度不一致
        // : ExtendedWidgetSpan(
        //     actualText: atText,
        //     start: start!,
        //     style: textStyle,
        //     child: GestureDetector(
        //       child: Text.rich(TextSpan(
        //         style: textStyle,
        //         children: [
        //           TextSpan(
        //               text: '@',
        //               style: TextStyle(
        //                   color:
        //                       Theme.of(Get.context!).colorScheme.onBackground)),
        //           TextSpan(text: atText.split('@')[1]),
        //         ],
        //       )),
        //       onTap: () {
        //         controller!.value = controller!.value.copyWith(
        //           text: controller!.text
        //               .replaceRange(start!, start! + atText.length, ''),
        //           selection: TextSelection.fromPosition(
        //             TextPosition(offset: start!),
        //           ),
        //         );
        //       },
        //     ),
        //     deleteAll: true,
        //   );
        : SpecialTextSpan(
            text: atText,
            actualText: atText,
            start: start!,
            style: textStyle,
            recognizer: (TapGestureRecognizer()
              ..onTap = () {
                if (onTap != null) {
                  onTap!(atText);
                }
              }),
          );
  }
}
