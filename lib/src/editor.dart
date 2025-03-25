import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:untitled100/html_editor.dart';

class Editor extends StatefulWidget {
  final IHtmlEditorController? controller;
  final void Function(IHtmlEditorController controller)? onControllerCreated;
  final String? html;
  final double minHeight;
  final double maxHeight;
  final bool readOnly;
  final void Function(String content)? onContentChanged;
  final EditorColors? editorColors;
  final ThemeData? theme;

  const Editor({
    this.html,
    this.minHeight = 120,
    this.maxHeight = 300,
    required this.readOnly,
    this.controller,
    this.onControllerCreated,
    this.onContentChanged,
    this.editorColors,
    this.theme,
    super.key,
  });

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  late final IHtmlEditorController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  late final ScrollController _editorScrollController;
  late final StreamSubscription? _keyboardSubscription;
  late final KeyboardVisibilityController _keyboardVisibilityController;

  final GlobalKey editorKey = GlobalKey();

  @override
  void initState() {
    _editorScrollController = ScrollController();
    _controller = widget.controller ??
        HtmlEditorController(
            externalHtml: widget.html,
            onContentChanged: widget.onContentChanged);
    _controller.quillController.readOnly = widget.readOnly;
    _keyboardVisibilityController = KeyboardVisibilityController();
    widget.onControllerCreated?.call(_controller);

    _keyboardSubscription =
        _keyboardVisibilityController.onChange.listen(_onKeyboardVisible);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    _keyboardSubscription?.cancel();
    super.dispose();
  }

  void _onKeyboardVisible(bool isVisible) {
    if (isVisible && editorKey.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isWidgetPartiallyVisible(editorKey)) {
          _scrollToEditor();
        }
      });
    }
  }

  void _scrollToEditor() {
    final context = editorKey.currentContext;
    if (context == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final editorPosition = renderBox.localToGlobal(Offset.zero).dy;

    final targetOffset = editorPosition - (screenHeight - keyboardHeight - 16);

    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.35,
    );
  }

  bool isWidgetPartiallyVisible(GlobalKey key) {
    final RenderObject? renderObject = key.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final RenderAbstractViewport viewport =
          RenderAbstractViewport.of(renderObject);
      final RevealedOffset offset =
          viewport.getOffsetToReveal(renderObject, 0.5);

      return offset.offset < 50;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: (widget.theme ?? Theme.of(context)).copyWith(
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
        ),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey)),
            child: Column(
              children: [
                IgnorePointer(
                  ignoring: _controller.quillController.readOnly,
                  child: QuillSimpleToolbar(
                    key: editorKey,
                    controller: _controller.quillController,
                    config: QuillSimpleToolbarConfig(
                      customButtons: [
                        QuillToolbarCustomButtonOptions(
                          icon: Icon(
                            Icons.attach_file,
                            color: widget.readOnly ? Colors.grey : null,
                          ),
                          onPressed: () async =>
                              await _controller.insertFileFromStorage(),
                        ),
                        QuillToolbarCustomButtonOptions(
                          icon: Icon(
                            Icons.image,
                            color: widget.readOnly ? Colors.grey : null,
                          ),
                          onPressed: () async =>
                              await ImagePickerDialog.showImagePickerDialog(
                                  context, _controller, widget.editorColors),
                        ),
                        QuillToolbarCustomButtonOptions(
                            icon: Icon(
                              Icons.format_align_justify_outlined,
                              color: widget.readOnly ? Colors.grey : null,
                            ),
                            onPressed: () async => MenuDialog.showAlignmentMenu(
                                context, _controller, widget.editorColors))
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
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          iconTheme: QuillIconTheme(
                            iconButtonUnselectedData: IconButtonData(
                                color: widget.readOnly
                                    ? Colors.grey
                                    : widget.editorColors?.iconColor),
                          ),
                        ),
                        linkStyle: QuillToolbarLinkStyleButtonOptions(
                            iconTheme: QuillIconTheme(
                                iconButtonUnselectedData: IconButtonData(
                                    color: widget.readOnly
                                        ? Colors.grey
                                        : widget.editorColors?.iconColor)),
                            dialogTheme: QuillDialogTheme(
                              dialogBackgroundColor:
                                  widget.editorColors?.backgroundColor,
                            )),
                      ),
                    ),
                  ),
                ),
                QuillEditor(
                  focusNode: _editorFocusNode,
                  scrollController: _editorScrollController,
                  controller: _controller.quillController,
                  config: QuillEditorConfig(
                    onLaunchUrl: (link) async =>
                        await _controller.openFileOrLink(link),
                    maxHeight: widget.maxHeight,
                    minHeight: widget.minHeight,
                    placeholder: 'Напишите что-нибудь...',
                    customStyles:
                        EditorStyles.getInstance(context, widget.theme),
                    padding: const EdgeInsets.all(16),
                    embedBuilders: [
                      ...FlutterQuillEmbeds.editorBuilders(
                        imageEmbedConfig: QuillEditorImageEmbedConfig(
                            imageProviderBuilder:
                                _controller.imageProviderBuilder,
                            onImageClicked: (imageUrl) {
                              if (!_controller.quillController.readOnly) {
                                ImagePickerDialog.showDeletionImageDialog(
                                    context,
                                    imageUrl,
                                    _controller,
                                    widget.editorColors);
                              }
                            }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
