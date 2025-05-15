import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class SubSuperScriptEmbedBuilder extends EmbedBuilder {
  final bool isSubscript;

  SubSuperScriptEmbedBuilder({required this.isSubscript});

  @override
  String get key => isSubscript ? 'subscript' : 'superscript';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final text = embedContext.node.value.data;
    final style =  const TextStyle(fontSize: 16);

    return Transform.translate(
      offset: Offset(0, isSubscript ? 4 : -4),
      child: Text(
        text,
        style: style.copyWith(fontSize: style.fontSize! * 0.8),
      ),
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(
      child: widget,
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
    );
  }

  @override
  bool get expanded => false;

  @override
  String toPlainText(Embed node) {
    return node.value.data;
  }
}



class MyCustomBlockEmbed extends BlockEmbed {
  MyCustomBlockEmbed(String type, String data)
      : super(type, data);

  static MyCustomBlockEmbed subscript(String data) =>
      MyCustomBlockEmbed('subscript', data);

  static MyCustomBlockEmbed superscript(String data) =>
      MyCustomBlockEmbed('superscript', data);
}

