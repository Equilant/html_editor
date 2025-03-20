import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:untitled100/html_editor/html_editor_controller.dart';

import 'package:untitled100/html_editor/image_picker_dialog.dart';

class HtmlEditor extends StatefulWidget {
  const HtmlEditor({super.key});

  @override
  State<HtmlEditor> createState() => _HtmlEditorState();
}

class _HtmlEditorState extends State<HtmlEditor> {
  late final HtmlEditorController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  @override
  void initState() {
    _controller = HtmlEditorController(html: "<p>Hello, <b>world</b>!</p>");
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 330,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey)),
          child: Column(
            children: [
              QuillSimpleToolbar(
                controller: _controller.quillController,
                config: QuillSimpleToolbarConfig(
                  customButtons: [
                    QuillToolbarCustomButtonOptions(
                      icon: Icon(Icons.attach_file),
                      onPressed: () async =>
                          await _controller.insertFileFromStorage(),
                    ),
                    QuillToolbarCustomButtonOptions(
                      icon: Icon(Icons.image),
                      onPressed: () async =>
                          await ImagePickerDialog.showImagePickerDialog(
                              context, _controller),
                    ),
                  ],
                  toolbarIconAlignment: WrapAlignment.start,
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(
                    videoButtonOptions: null,
                    imageButtonOptions: null,
                  ),
                  showClipboardPaste: false,
                  showDividers: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showStrikeThrough: false,
                  showInlineCode: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showHeaderStyle: false,
                  showListNumbers: false,
                  showListBullets: false,
                  showListCheck: false,
                  showCodeBlock: false,
                  showQuote: false,
                  showIndent: false,
                  showRedo: false,
                  showSearchButton: false,
                  showClipboardCut: false,
                  showClipboardCopy: false,
                  buttonOptions: QuillSimpleToolbarButtonOptions(),
                ),
              ),
              QuillEditor(
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                controller: _controller.quillController,
                config: QuillEditorConfig(
                  onLaunchUrl: (link) {
                    _controller.openFileOrLink(link);
                  },
                  maxHeight: 200,
                  placeholder: 'Введите текст...',
                  padding: const EdgeInsets.all(16),
                  embedBuilders: [
                    ...FlutterQuillEmbeds.editorBuilders(
                      imageEmbedConfig: QuillEditorImageEmbedConfig(
                          imageProviderBuilder:
                              _controller.imageProviderBuilder,
                          onImageClicked: (imageUrl) {
                            ImagePickerDialog.showDeletionImageDialog(
                                context, imageUrl, _controller);
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ElevatedButton(
            onPressed: () {
              //_controller.replaceLocalFilesWithLinks();
              //_controller.replaceLocalImagesWithLinks();
              _controller.convertDeltaToHtml();
            },
            child: Text('send'))
      ],
    );
  }
}
