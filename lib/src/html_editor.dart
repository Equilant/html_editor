import 'package:flutter/material.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_svg/svg.dart';
import 'package:html_editor/editor.dart';
import 'package:html_editor/src/html_editor_controller.dart';
import 'package:html_editor/src/icons/html_icons.dart';

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
              cursorColor: context.theme.generalGray700,
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: context.theme.bg,
            ),
            inputDecorationTheme: InputDecorationTheme(
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: context.theme.gray800, width: 0.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: context.theme.gray800,
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(MaterialState.disabled)) {
                      return context.theme.gray400;
                    }
                    return context.theme.gray800;
                  },
                ),
              ),
            ),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.theme.generalBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: Column(
                  children: [
                    IgnorePointer(
                      ignoring: _controller.quillController.readOnly,
                      child: QuillSimpleToolbar(
                        key: _controller.editorKey,
                        controller: _controller.quillController,
                        config: QuillSimpleToolbarConfig(
                          customButtons: [
                            QuillToolbarCustomButtonOptions(
                              icon: SvgPicture.asset(
                                HtmlIcons.clipBold,
                                color: widget.readOnly
                                    ? context.theme.gray500
                                    : context.theme.generalGray700,
                              ),
                              onPressed: () async =>
                                  await _controller.insertFileFromStorage(),
                            ),
                            QuillToolbarCustomButtonOptions(
                              icon: SvgPicture.asset(
                                HtmlIcons.galleryBold,
                                color: widget.readOnly
                                    ? context.theme.gray500
                                    : context.theme.generalGray700,
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
                                    ? context.theme.gray500
                                    : context.theme.generalGray700,
                              ),
                              onPressed: () async =>
                                  MenuDialog.showAlignmentMenu(
                                context,
                                _controller,
                                _controller.alignmentIconKey,
                              ),
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
                          buttonOptions: QuillSimpleToolbarButtonOptions(
                            base: QuillToolbarBaseButtonOptions(
                              iconTheme: QuillIconTheme(
                                iconButtonSelectedData: IconButtonData(
                                    color: Colors.white,
                                    style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all<Color>(
                                                context.theme.generalGray800))),
                                iconButtonUnselectedData: IconButtonData(
                                  color: widget.readOnly
                                      ? context.theme.gray500
                                      : context.theme.generalGray700,
                                ),
                              ),
                            ),
                            linkStyle: QuillToolbarLinkStyleButtonOptions(
                              iconTheme: QuillIconTheme(
                                iconButtonUnselectedData: IconButtonData(
                                  color: widget.readOnly
                                      ? context.theme.gray500
                                      : context.theme.generalGray700,
                                ),
                              ),
                              dialogTheme: QuillDialogTheme(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                dialogBackgroundColor: context.theme.bg,
                                labelTextStyle: AppTextStyle.textT14Regular
                                    .copyWith(color: context.theme.gray800),
                                inputTextStyle:
                                    AppTextStyle.textT14Regular.copyWith(
                                  color: context.theme.gray800,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    QuillEditor(
                      focusNode: _controller.focusNode,
                      scrollController: _controller.scrollController,
                      controller: _controller.quillController,
                      config: QuillEditorConfig(
                        onLaunchUrl: (link) async =>
                            await _controller.openFileOrLink(link),
                        maxHeight: widget.maxHeight,
                        minHeight: widget.minHeight,
                        placeholder: 'Напишите что-нибудь...',
                        customStyles: EditorStyles.getInstance(context),
                        padding: const EdgeInsets.all(16),
                        embedBuilders: [
                          ...FlutterQuillEmbeds.editorBuilders(
                            imageEmbedConfig: QuillEditorImageEmbedConfig(
                              imageProviderBuilder:
                                  _controller.imageProviderBuilder,
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
