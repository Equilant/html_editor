import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'dart:io' as io show File;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image/image.dart' as img;

enum HtmlAlignmentType {
  left('слева'),
  right('справа'),
  center('по центру'),
  justify('по ширине');

  final String title;

  const HtmlAlignmentType(this.title);
}

abstract interface class IHtmlEditorController {
  void dispose();

  QuillController get quillController;

  void convertDeltaToHtml();

  Future<void> insertFileFromStorage();

  Future<void> openFileOrLink(String url);

  Future<bool> replaceLocalFilesWithLinks();

  Future<bool> replaceLocalImagesWithLinks();

  Future<void> pickImage(ImageSource imageSource);

  ImageProvider<Object>? imageProviderBuilder(
      BuildContext context, String path);

  void deleteImage(String imageUrl);

  void setAlignment(HtmlAlignmentType align);

  GlobalKey get editorKey;

  FocusNode get focusNode;

  ScrollController get scrollController;

  Future<bool> replaceLocalMediaWithLinks();

  GlobalKey get alignmentIconKey;
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

  final String storageUrl;

  final GlobalKey _alignmentIconKey = GlobalKey();

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
    ));

    _editorKey = GlobalKey();
    _editorFocusNode = FocusNode();
    _editorScrollController = ScrollController();
    _controller.readOnly = readOnly ?? false;
    _keyboardVisibilityController = KeyboardVisibilityController();
    onControllerCreated?.call(this);

    _keyboardSubscription =
        _keyboardVisibilityController.onChange.listen(_onKeyboardVisible);

    if (externalHtml?.isNotEmpty ?? false) {
      String parsedHtml = convertHtml(externalHtml!);
      var delta = HtmlToDelta(
        shouldInsertANewLine: (_) => true,
      ).convert(parsedHtml);

      delta = fixDeltaSpacing(delta);
      _controller.document = Document.fromDelta(delta);
    }

    _controller.addListener(convertDeltaToHtml);
  }

  void _onKeyboardVisible(bool isVisible) {
    if (isVisible && _editorKey.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isWidgetVisible(_editorKey)) {
          _scrollToEditor();
        }
      });
    }
  }

  void _scrollToEditor() {
    final context = _editorKey.currentContext;
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
      alignment: 0.1,
    );
  }

  bool isWidgetVisible(GlobalKey key) {
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

  Delta fixDeltaSpacing(Delta delta) {
    Delta newDelta = Delta();
    for (var op in delta.toList()) {
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
      _controller.removeListener(convertDeltaToHtml);
      _controller.dispose();
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
  Future<void> insertFileFromStorage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final fileName = file.name;
      final filePath = file.path;

      if (filePath != null) {
        final directory = await getTemporaryDirectory();
        final newPath = path.join(directory.path, fileName);
        final localFile = await io.File(filePath).copy(newPath);

        final index = _controller.selection.baseOffset;

        _controller.document.insert(index, fileName);

        _controller.formatText(
          index,
          fileName.length,
          Attribute<String>(
              'link', AttributeScope.inline, 'file://${localFile.path}'),
        );
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
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: _getMediaType(mimeType),
      ))
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

    for (var op in delta.toList()) {
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

    for (var op in delta.toList()) {
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

    for (var op in delta.toList()) {
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
  Future<void> pickImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: imageSource);

    if (image != null) {
      final filePath = image.path;

      try {
        final directory = await getTemporaryDirectory();
        final newPath = path.join(directory.path, path.basename(filePath));

        final originalFile = io.File(filePath);
        if (!await originalFile.exists()) {
          debugPrint("Файл не найден: $filePath");
          return;
        }

        final localFile = await originalFile.copy(newPath);

        if (!await localFile.exists()) {
          debugPrint("Ошибка копирования файла: $newPath");
          return;
        }

        final localImagePath = 'file://${localFile.path}';

        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, BlockEmbed.image(localImagePath));

        _controller.updateSelection(
          TextSelection.collapsed(offset: index + 1),
          ChangeSource.local,
        );

        debugPrint("Изображение успешно вставлено: $localImagePath");
      } catch (e) {
        debugPrint("Ошибка вставки изображения: $e");
      }
    }
  }

  @override
  ImageProvider<Object>? imageProviderBuilder(
      BuildContext context, String path) {
    if (path.startsWith('file:/')) {
      String cleanedPath = removeFilePrefix(path);
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

    for (var op in delta.toList()) {
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
    final attribute = quill.Attribute.align;

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
    html = html.replaceAllMapped(RegExp(r'class="ql-align-(\w+)"'), (match) {
      return 'style="text-align: ${match.group(1)};"';
    });

    html = html.replaceAll(RegExp(r'<br>\s*</p>'), '</p>');

    return html;
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
}
