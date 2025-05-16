import 'package:flutter/material.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html_editor/editor.dart';
import 'package:html_editor/src/link_action_delegate.dart';
import 'package:html_editor/src/link_dialog.dart';
import 'package:html_editor/src/editor_embed_builder.dart';

class HtmlEditor extends StatefulWidget {
  final IHtmlEditorController? controller;
  final void Function(IHtmlEditorController controller)? onControllerCreated;
  final String? html;
  final double minHeight;
  final double maxHeight;
  final bool readOnly;
  final void Function(String content)? onContentChanged;
  final String storageUrl;

  const HtmlEditor({
    this.html,
    this.minHeight = 120,
    this.maxHeight = 300,
    required this.readOnly,
    this.controller,
    this.onControllerCreated,
    this.onContentChanged,
    required this.storageUrl,
    super.key,
  });

  @override
  State<HtmlEditor> createState() => _HtmlEditorState();
}

class _HtmlEditorState extends State<HtmlEditor> {
  late final IHtmlEditorController _controller;

  @override
  void initState() {
    AppTextStyle.init(
      screenWidth: WidgetsBinding
          .instance.platformDispatcher.views.first.physicalSize.width,
      pixelRatio: WidgetsBinding
          .instance.platformDispatcher.views.first.devicePixelRatio,
    );
    _controller = widget.controller ??
        HtmlEditorController(
          externalHtml: widget.html,
          onContentChanged: widget.onContentChanged,
          readOnly: widget.readOnly,
          onControllerCreated: widget.onControllerCreated,
          storageUrl: widget.storageUrl,
        );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditorTheme(
      brightness: Theme.of(context).brightness,
      child: Builder(builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: context.editorTheme.generalGray700,
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: context.editorTheme.bg,
            ),
            inputDecorationTheme: InputDecorationTheme(
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: context.editorTheme.gray800, width: 0.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.editorTheme.gray800,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(MaterialState.disabled)) {
                      return context.editorTheme.gray400;
                    }
                    return context.editorTheme.gray800;
                  },
                ),
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.editorTheme.generalBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  children: [
                    IgnorePointer(
                      ignoring: _controller.quillController.readOnly,
                      child: QuillSimpleToolbar(
                        controller: _controller.quillController,
                        config: QuillSimpleToolbarConfig(
                          customButtons: [
                            QuillToolbarCustomButtonOptions(
                              icon: SvgPicture.asset(
                                HtmlIcons.clipBold,
                                color: widget.readOnly
                                    ? context.editorTheme.gray500
                                    : context.editorTheme.generalGray700,
                              ),
                              onPressed: () async => await _controller
                                  .insertFileFromStorage(context),
                            ),
                            QuillToolbarCustomButtonOptions(
                              icon: SvgPicture.asset(
                                HtmlIcons.galleryBold,
                                color: widget.readOnly
                                    ? context.editorTheme.gray500
                                    : context.editorTheme.generalGray700,
                              ),
                              onPressed: () async =>
                                  await ImagePickerDialog.showImagePickerDialog(
                                context,
                                _controller,
                              ),
                            ),
                            QuillToolbarCustomButtonOptions(
                              icon: Icon(
                                key: _controller.alignmentIconKey,
                                Icons.format_align_justify_outlined,
                                color: widget.readOnly
                                    ? context.editorTheme.gray500
                                    : context.editorTheme.generalGray700,
                              ),
                              onPressed: () async =>
                                  MenuDialog.showAlignmentMenu(
                                context,
                                _controller,
                                _controller.alignmentIconKey,
                              ),
                            ),
                            QuillToolbarCustomButtonOptions(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _controller.isSubscriptMode
                                      ? context.editorTheme.generalGray800
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.subscript,
                                  color: widget.readOnly
                                      ? context.editorTheme.gray500
                                      : _controller.isSubscriptMode
                                          ? context.editorTheme.generalGray0
                                          : context.editorTheme.generalGray700,
                                ),
                              ),
                              onPressed: () {
                                _controller.toggleSubscriptMode();
                                setState(() {});
                              },
                            ),
                            QuillToolbarCustomButtonOptions(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _controller.isSuperscriptMode
                                      ? context.editorTheme.generalGray800
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.superscript,
                                  color: widget.readOnly
                                      ? context.editorTheme.gray500
                                      : _controller.isSuperscriptMode
                                          ? context.editorTheme.generalGray0
                                          : context.editorTheme.generalGray700,
                                ),
                              ),
                              onPressed: () {
                                _controller.toggleSuperscriptMode();
                                setState(() {});
                              },
                            ),
                            QuillToolbarCustomButtonOptions(
                              icon: Icon(
                                Icons.link,
                                color: widget.readOnly
                                    ? context.editorTheme.gray500
                                    : context.editorTheme.generalGray700,
                              ),
                              onPressed: () async =>
                                  await LinkDialog.showCustomLinkDialog(
                                      context, _controller.quillController),
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
                          showLink: false,
                          showSearchButton: false,
                          showClipboardCut: false,
                          showClipboardCopy: false,
                          showSubscript: false,
                          showSuperscript: false,
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            base: QuillToolbarBaseButtonOptions(
                              iconTheme: QuillIconTheme(
                                iconButtonSelectedData: IconButtonData(
                                    color: Colors.white,
                                    style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all<Color>(
                                                context.editorTheme
                                                    .generalGray800))),
                                iconButtonUnselectedData: IconButtonData(
                                  color: widget.readOnly
                                      ? context.editorTheme.gray500
                                      : context.editorTheme.generalGray700,
                                ),
                              ),
                            ),
                            linkStyle: QuillToolbarLinkStyleButtonOptions(
                              iconTheme: QuillIconTheme(
                                iconButtonUnselectedData: IconButtonData(
                                  color: widget.readOnly
                                      ? context.editorTheme.gray500
                                      : context.editorTheme.generalGray700,
                                ),
                              ),
                              dialogTheme: QuillDialogTheme(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                dialogBackgroundColor: context.editorTheme.bg,
                                labelTextStyle: AppTextStyle.textT14Regular
                                    .copyWith(
                                        color: context.editorTheme.gray800),
                                inputTextStyle:
                                    AppTextStyle.textT14Regular.copyWith(
                                  color: context.editorTheme.gray800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    QuillEditor.basic(
                      key: _controller.editorKey,
                      focusNode: _controller.focusNode,
                      scrollController: _controller.scrollController,
                      controller: _controller.quillController,
                      config: QuillEditorConfig(
                        linkActionPickerDelegate:
                            LinkActionDelegate.customLinkActionPickerDelegate,
                        onLaunchUrl: (link) async =>
                            await _controller.openFileOrLink(link),
                        maxHeight: widget.maxHeight,
                        minHeight: widget.minHeight,
                        placeholder: 'Напишите что-нибудь...',
                        customStyles: EditorStyles.getInstance(context),
                        padding: const EdgeInsets.all(16),
                        showCursor: !widget.readOnly,
                        embedBuilders: [
                          EditorEmbedBuilder(isSubscript: true),
                          EditorEmbedBuilder(isSubscript: false),
                          ...FlutterQuillEmbeds.editorBuilders(
                            imageEmbedConfig: QuillEditorImageEmbedConfig(
                              imageProviderBuilder:
                                  _controller.imageProviderBuilder,
                              // imageErrorWidgetBuilder: (context, _,__) =>
                              // Text('Не удалось загрузить картинку...'),
                              onImageClicked: (imageUrl) async {
                                if (!_controller.quillController.readOnly) {
                                  await ImagePickerDialog
                                      .showDeletionImageDialog(
                                    context,
                                    imageUrl,
                                    _controller,
                                  );
                                }
                              },
                            ),
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
      }),
    );
  }
}
