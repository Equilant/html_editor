import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:html_editor/src/permissions_dialog.dart';
import 'package:html_editor/src/subscript_embed.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image/image.dart' as img;
import 'package:collection/collection.dart';

enum HtmlAlignmentType { left, right, center, justify }

abstract interface class IHtmlEditorController {
  void dispose();

  QuillController get quillController;

  void convertDeltaToHtml();

  Future<void> insertFileFromStorage(BuildContext context);

  Future<void> openFileOrLink(String url);

  Future<bool> replaceLocalFilesWithLinks();

  Future<bool> replaceLocalImagesWithLinks();

  Future<void> pickImage(ImageSource imageSource, BuildContext context);

  ImageProvider<Object>? imageProviderBuilder(
    BuildContext context,
    String path,
  );

  void deleteImage(String imageUrl);

  void setAlignment(HtmlAlignmentType align);

  GlobalKey get editorKey;

  FocusNode get focusNode;

  ScrollController get scrollController;

  Future<bool> replaceLocalMediaWithLinks();

  GlobalKey get alignmentIconKey;

  Future<void> scrollToEditor();

  void toggleSubscriptMode();

  void toggleSuperscriptMode();

  bool get isSubscriptMode;

  bool get isSuperscriptMode;
}

class HtmlEditorController implements IHtmlEditorController {
  late final QuillController _controller;
  final String? externalHtml;
  String? internalHtml;

  final void Function(String content)? onContentChanged;

  late final FocusNode _editorFocusNode;
  late final ScrollController _editorScrollController;
  late final StreamSubscription? _keyboardSubscription;
  late final KeyboardVisibilityController _keyboardVisibilityController;

  late final GlobalKey _editorKey;
  final bool? readOnly;

  final void Function(IHtmlEditorController controller)? onControllerCreated;

  bool _shouldDispose = true;

  final GlobalKey _alignmentIconKey = GlobalKey();

  final String storageUrl;

  HtmlEditorController({
    this.externalHtml,
    this.onContentChanged,
    this.readOnly,
    this.onControllerCreated,
    required this.storageUrl,
  }) {
    _controller = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: onImagePasteHandler,
        ),
      ),
    );

    _editorKey = GlobalKey();
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
    _controller.readOnly = readOnly ?? false;
    _keyboardVisibilityController = KeyboardVisibilityController();
    onControllerCreated?.call(this);

    _keyboardSubscription =
        _keyboardVisibilityController.onChange.listen(_onKeyboardVisible);

    if (externalHtml?.isNotEmpty ?? false) {
      final String parsedHtml = convertHtml(externalHtml!);
      var delta = HtmlToDelta(
        shouldInsertANewLine: (_) => true,
      ).convert(parsedHtml);

      delta = fixDeltaSpacing(delta);
      _controller.document = Document.fromDelta(delta);
    }

    _controller.addListener(convertDeltaToHtml);

    _initSubSuperScriptListener();
  }

  StreamSubscription? _textSub;
  bool _isHandling = false;

  void _initSubSuperScriptListener() {
    _textSub = _controller.changes.listen((event) {
      final source = event.source;
      final change = event.change;

      if (_isHandling || source != ChangeSource.local) return;
      if (!_isSubscriptMode && !_isSuperscriptMode) return;
      if (change.isEmpty) return;

      final insertOp = change.operations.firstWhereOrNull(
        (op) =>
            op.key == 'insert' &&
            op.value is String &&
            (op.value as String).length == 1,
      );

      if (insertOp == null) return;

      final inserted = insertOp.value as String;
      final offset = _controller.selection.baseOffset;

      _isHandling = true;

      // Удаляем вставленный обычный символ
      _controller.replaceText(
        offset - 1,
        1,
        '',
        TextSelection.collapsed(offset: offset - 1),
      );

      // Вставляем embed с subscript или superscript
      final embed = _isSubscriptMode
          ? MyCustomBlockEmbed.subscript(inserted)
          : MyCustomBlockEmbed.superscript(inserted);

      _controller.replaceText(
        offset - 1,
        0,
        embed,
        TextSelection.collapsed(offset: offset),
      );

      _isHandling = false;
    });
  }

  bool _isSubscriptMode = false;
  bool _isSuperscriptMode = false;

  @override
  void toggleSubscriptMode() {
    _isSubscriptMode = !_isSubscriptMode;
    _isSuperscriptMode = false;
  }

  @override
  void toggleSuperscriptMode() {
    _isSuperscriptMode = !_isSuperscriptMode;
    _isSubscriptMode = false;
  }

  void _insertCustomEmbed(MyCustomBlockEmbed embed) {
    final index = _controller.selection.baseOffset;
    _controller.replaceText(index, 0, embed, _controller.selection);
  }

  bool isWidgetVisible(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return false;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    final offset = renderBox.localToGlobal(Offset.zero);
    final height = renderBox.size.height;

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final visibleBottom = screenHeight - keyboardHeight;

    return offset.dy + height <= visibleBottom;
  }

  @override
  Future<void> scrollToEditor() async {
    final context = _editorKey.currentContext;
    if (context == null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    await Future.delayed(const Duration(milliseconds: 100));

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final visibleHeight = screenHeight - keyboardHeight;

    final editorHeight = renderBox.size.height;
    final editorOffset = renderBox.localToGlobal(Offset.zero);

    if (editorHeight > visibleHeight) {
      await Scrollable.ensureVisible(
        context,
        alignment: 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      await Scrollable.ensureVisible(
        context,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onKeyboardVisible(bool isVisible) {
    if (!isVisible) return;

    _waitForKeyboardAndScroll();
  }

  void _waitForKeyboardAndScroll() async {
    final context = _editorKey.currentContext;

    if (context == null) return;

    await WidgetsBinding.instance.endOfFrame;

    scrollToEditor();
  }

  bool isWidgetCoveredByKeyboard(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return false;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    final editorOffset = renderBox.localToGlobal(Offset.zero);
    final editorHeight = renderBox.size.height;
    final editorBottom = editorOffset.dy + editorHeight;

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final visibleBottom = screenHeight - keyboardHeight;

    debugPrint(
        'editorBottom: $editorBottom, visibleBottom: $visibleBottom, keyboardHeight: $keyboardHeight');

    return editorBottom > visibleBottom;
  }

  Delta fixDeltaSpacing(Delta delta) {
    final Delta newDelta = Delta();
    for (final op in delta.toList()) {
      newDelta.push(op);
      if (op.data is String && (op.data as String).trim().isEmpty) {
        newDelta.push(Operation.insert('\n'));
      }
    }
    return newDelta;
  }

  @override
  void dispose() {
    if (_shouldDispose) {
      _controller
        ..removeListener(convertDeltaToHtml)
        ..dispose();
      _editorScrollController.dispose();
      _editorFocusNode.dispose();
      _keyboardSubscription?.cancel();
      _shouldDispose = false;
    }
  }

  Future<String> onImagePasteHandler(Uint8List imageBytes) async {
    final directory = await getTemporaryDirectory();

    final decodedImage = img.decodeImage(imageBytes);

    final encodedImage =
        decodedImage != null ? img.encodePng(decodedImage) : imageBytes;

    final fileName =
        'pasted_image_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = path.join(directory.path, fileName);

    final file = io.File(filePath);
    await file.writeAsBytes(encodedImage);

    return 'file://$filePath';
  }

  @override
  Future<void> insertFileFromStorage(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final fileName = file.name;
      final filePath = file.path;

      if (filePath != null) {
        final directory = await getTemporaryDirectory();
        final newPath = path.join(directory.path, fileName);
        final localFile = await io.File(filePath).copy(newPath);

        final index = _controller.selection.baseOffset;

        _controller.document.insert(index, '\n');

        _controller.document.insert(index + 1, fileName);

        _controller.formatText(
          index + 1,
          fileName.length,
          Attribute<String>(
            'link',
            AttributeScope.inline,
            'file://${localFile.path}',
          ),
        );

        _controller.document.insert(index + 1 + fileName.length, '\n');

        _controller.updateSelection(
          TextSelection.collapsed(offset: index + 2 + fileName.length),
          ChangeSource.local,
        );

        _editorFocusNode.unfocus();

        await Future.delayed(const Duration(milliseconds: 100));

        FocusScope.of(context).requestFocus(_editorFocusNode);
      }
    }
  }

  Future<String> uploadFileToServer(String localPath, bool isFile) async {
    final file = io.File(removeFilePrefix(localPath));

    final path = isFile ? 'file_upload/' : 'image_upload/';

    final uri = Uri.parse("$storageUrl$path");

    if (!file.existsSync()) return '';

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: _getMediaType(mimeType),
        ),
      )
      ..headers['Content-Type'] = mimeType;

    final response = await request.send();
    if (_defaultValidateStatus(response.statusCode)) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['link'];
    } else {
      throw Exception("Ошибка загрузки файла");
    }
  }

  MediaType _getMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return MediaType(parts[0], parts[1]);
    }
    return MediaType('application', 'octet-stream');
  }

  @override
  Future<bool> replaceLocalMediaWithLinks() async {
    _shouldDispose = false;
    final delta = _controller.document.toDelta();
    int index = 0;

    for (final op in delta.toList()) {
      final opLength = op.length ?? op.data.toString().length;

      if (op.data is Map && (op.data as Map).containsKey('image')) {
        final localPath = (op.data as Map)['image'];

        if (localPath.startsWith('file://')) {
          try {
            final uploadedUrl = await uploadFileToServer(localPath, false);

            _controller.replaceText(
              index,
              1,
              BlockEmbed.image(uploadedUrl),
              null,
            );
          } catch (e) {
            debugPrint("Ошибка загрузки изображения: $e");
            return false;
          }
        }
      } else if (op.attributes != null && op.attributes!['link'] != null) {
        final link = op.attributes!['link'];

        if (link.startsWith('file://')) {
          final filePath = link.replaceFirst('file://', '');

          try {
            final uploadedUrl = await uploadFileToServer(filePath, true);

            _controller.formatText(
              index,
              opLength,
              Attribute<String>('link', AttributeScope.inline, uploadedUrl),
            );
          } catch (e) {
            debugPrint("Ошибка загрузки файла: $e");
            return false;
          }
        }
      }

      index += opLength;
    }

    _shouldDispose = true;
    return true;
  }

  @override
  Future<bool> replaceLocalImagesWithLinks() async {
    _shouldDispose = false;
    final delta = _controller.document.toDelta();
    int index = 0;

    for (final op in delta.toList()) {
      if (op.data is Map && (op.data as Map).containsKey('image')) {
        final localPath = (op.data as Map)['image'];

        if (localPath.startsWith('file://')) {
          try {
            final uploadedUrl = await uploadFileToServer(localPath, false);

            _controller.replaceText(
              index,
              1,
              BlockEmbed.image(uploadedUrl),
              null,
            );
          } catch (e) {
            debugPrint("Ошибка загрузки изображения: $e");
            return false;
          }
        }
      }

      index += op.length ?? 0;
    }
    _shouldDispose = true;
    return true;
  }

  @override
  Future<bool> replaceLocalFilesWithLinks() async {
    _shouldDispose = false;
    final delta = _controller.document.toDelta();
    int currentOffset = 0;

    for (final op in delta.toList()) {
      final opLength = op.length ?? op.data.toString().length;

      if (op.attributes != null && op.attributes!['link'] != null) {
        final link = op.attributes!['link'];

        if (link.startsWith('file://')) {
          final filePath = link.replaceFirst('file://', '');

          try {
            final uploadedUrl = await uploadFileToServer(filePath, true);

            _controller.formatText(
              currentOffset,
              opLength,
              Attribute<String>('link', AttributeScope.inline, uploadedUrl),
            );
          } catch (e) {
            debugPrint("Ошибка загрузки файла: $e");
            return false;
          }
        }
      }
      currentOffset += opLength;
    }
    _shouldDispose = true;
    return true;
  }

  @override
  Future<void> openFileOrLink(String url) async {
    if (url.startsWith('https://') || url.startsWith('http://')) {
      if (url.startsWith('https://file://') ||
          url.startsWith('http://file://')) {
        final localPath = url.replaceFirst(RegExp(r'^https?://file://'), '');

        if (await io.File(localPath).exists()) {
          await OpenFile.open(localPath);
        } else {
          debugPrint("Файл не найден: $localPath");
        }
        return;
      }

      final encodedUrl = Uri.encodeFull(Uri.decodeFull(url));
      final uri = Uri.parse(encodedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    if (url.startsWith('file://')) {
      url = url.replaceFirst('file://', '');
    }

    if (await io.File(url).exists()) {
      await OpenFile.open(url);
    } else {
      debugPrint("Файл не найден: $url");
    }
  }

  @override
  QuillController get quillController => _controller;

  @override
  void convertDeltaToHtml() {
    final converter = QuillDeltaToHtmlConverter(
      _controller.document.toDelta().toJson(),
    );

    internalHtml = converter.convert();
    const emptyHtml = '<p><br/></p>';
    if (internalHtml == emptyHtml) {
      onContentChanged?.call('');
    } else {
      final html = convertHtml(internalHtml ?? '');
      onContentChanged?.call(html);
    }
  }

  @override
  Future<void> pickImage(ImageSource imageSource, BuildContext context) async {
    final permission = imageSource == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final status = await permission.request();

    if (status.isPermanentlyDenied) {
      await PermissionsDialog.showPermissionDialog(context);
      return;
    }

    if (status.isGranted) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: imageSource);

      if (image != null) {
        try {
          final bytes = await image.readAsBytes();

          if (bytes.isEmpty) {
            debugPrint("Получен пустой файл изображения");
            return;
          }

          final directory = await getTemporaryDirectory();
          final newPath = path.join(directory.path, path.basename(image.path));
          final file = await io.File(newPath).writeAsBytes(bytes);

          final localImagePath = 'file://${file.path}';

          final index = _controller.selection.baseOffset;

          _controller.document.insert(index, '\n');
          _controller.document
              .insert(index + 1, BlockEmbed.image(localImagePath));
          _controller.document.insert(index + 2, '\n');

          _controller.updateSelection(
            TextSelection.collapsed(offset: index + 3),
            ChangeSource.local,
          );

          debugPrint("Изображение успешно вставлено: $localImagePath");
        } catch (e) {
          debugPrint("Ошибка вставки изображения: $e");
        }
      }
    }
  }

  @override
  ImageProvider<Object>? imageProviderBuilder(
    BuildContext context,
    String path,
  ) {
    if (path.startsWith('file:/')) {
      final String cleanedPath = removeFilePrefix(path);
      return FileImage(io.File(cleanedPath));
    }
    return null;
  }

  String removeFilePrefix(String path) {
    if (path.startsWith('file://')) {
      return path.replaceFirst('file://', '');
    }
    return path;
  }

  @override
  void deleteImage(String imageUrl) {
    final delta = _controller.document.toDelta();
    int index = 0;

    for (final op in delta.toList()) {
      if (op.data is Map && (op.data as Map).containsKey('image')) {
        final localPath = (op.data as Map)['image'];

        if (localPath == imageUrl) {
          try {
            _controller.replaceText(
              index,
              1,
              '',
              TextSelection.collapsed(offset: index),
            );
            return;
          } catch (e) {
            debugPrint("Ошибка удаления изображения: $e");
          }
        }
      }

      index += op.length ?? 0;
    }
  }

  @override
  void setAlignment(HtmlAlignmentType align) {
    const attribute = quill.Attribute.align;

    _controller.formatSelection(
      align == HtmlAlignmentType.left
          ? quill.Attribute.clone(attribute, null)
          : quill.Attribute.fromKeyValue('align', align.name),
    );
  }

  @override
  GlobalKey<State<StatefulWidget>> get editorKey => _editorKey;

  @override
  FocusNode get focusNode => _editorFocusNode;

  @override
  ScrollController get scrollController => _editorScrollController;

  String convertHtml(String html) {
    final parsedHtml =
        html.replaceAllMapped(RegExp(r'class="ql-align-(\w+)"'), (match) {
      return 'style="text-align: ${match.group(1)};"';
    });

    final updatedHtml = parsedHtml.replaceAll(RegExp(r'<br>\s*</p>'), '</p>');

    return updatedHtml;
  }

  bool _defaultValidateStatus(int? status) {
    try {
      return status != null && status >= 200 && status < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  GlobalKey<State<StatefulWidget>> get alignmentIconKey => _alignmentIconKey;

  @override
  bool get isSubscriptMode => _isSubscriptMode;

  @override
  bool get isSuperscriptMode => _isSuperscriptMode;
}
