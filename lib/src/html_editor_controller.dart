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
import 'dart:io' as io show Directory, File;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

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

  Future<void> replaceLocalFilesWithLinks();

  Future<void> replaceLocalImagesWithLinks();

  Future<void> pickImage(ImageSource imageSource);

  ImageProvider<Object>? imageProviderBuilder(
      BuildContext context, String path);

  void deleteImage(String imageUrl);

  void setAlignment(HtmlAlignmentType align);

  GlobalKey get editorKey;

  FocusNode get focusNode;

  ScrollController get scrollController;
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

  HtmlEditorController({
    this.externalHtml,
    this.onContentChanged,
    this.readOnly,
    this.onControllerCreated,
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
      var delta = HtmlToDelta(
        shouldInsertANewLine: (_) => true,
      ).convert(externalHtml!);

      delta = fixDeltaSpacing(delta);
      _controller.document = Document.fromDelta(delta);
    }

    _controller.addListener(convertDeltaToHtml);
  }

  void _onKeyboardVisible(bool isVisible) {
    if (isVisible && _editorKey.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isWidgetPartiallyVisible(_editorKey)) {
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
      _editorKey.currentState?.dispose();
      _shouldDispose = false;
    }
  }

  Future<String> onImagePasteHandler(Uint8List imageBytes) async {
    // Получаем директорию для хранения
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'pasted_image_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = path.join(directory.path, fileName);

    // Сохраняем изображение в локальное хранилище
    final file = io.File(filePath);
    await file.writeAsBytes(imageBytes);

    // Вставляем локальный путь в редактор (он будет заменен позже)
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
        // Перемещаем файл в локальную папку приложения
        final directory = await getTemporaryDirectory();
        final newPath = path.join(directory.path, fileName);
        final localFile = await io.File(filePath).copy(newPath);

        final index = _controller.selection.baseOffset;

        // Вставляем название файла
        _controller.document.insert(index, fileName);

        // Форматируем вставленный текст как ссылку (локальный путь)
        _controller.formatText(
          index,
          fileName.length,
          Attribute<String>(
              'link', AttributeScope.inline, 'file://${localFile.path}'),
        );
      }
    }
  }

  Future<String> uploadFileToServer(String localPath) async {
    final file = io.File(removeFilePrefix(localPath));
    final uri = Uri.parse(
        "https://local.dev.k8s.umschool.dev/froala_editor/file_upload/");

    if (!file.existsSync()) {
      return '';
    }

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: _getMediaType(mimeType),
      ))
      //..headers['Content-Disposition'] = 'inline; filename="${path.basename(file.path)}"'; // Важно!
      ..headers['Content-Type'] = mimeType;

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);
      return json['link']; // URL загруженного файла
    } else {
      throw Exception("Ошибка загрузки файла");
    }
  }

  // Функция преобразует MIME-тип в формат MediaType для http.MultipartFile
  MediaType _getMediaType(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return MediaType(parts[0], parts[1]);
    }
    return MediaType('application', 'octet-stream');
  }

  @override
  Future<void> replaceLocalImagesWithLinks() async {
    _shouldDispose = false;
    final delta = _controller.document.toDelta();
    int index = 0;

    for (var op in delta.toList()) {
      if (op.data is Map && (op.data as Map).containsKey('image')) {
        final localPath = (op.data as Map)['image'];

        if (localPath.startsWith('file://')) {
          // Локальный путь (без 'file://')
          try {
            final uploadedUrl = await uploadFileToServer(localPath);

            // Заменяем локальный путь на ссылку в редакторе
            _controller.replaceText(
              index,
              1, // Заменяем 1 элемент
              BlockEmbed.image(uploadedUrl), // Передаем корректный объект
              null,
            );
          } catch (e) {
            debugPrint("Ошибка загрузки изображения: $e");
          }
        }
      }

      // Увеличиваем index на длину текущей операции
      index += op.length ?? 0;
    }
    _shouldDispose = true;
    //convertDeltaToHtml();
  }

  @override
  Future<void> replaceLocalFilesWithLinks() async {
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
            final uploadedUrl = await uploadFileToServer(filePath);

            // Обновляем ссылку в редакторе
            _controller.formatText(
              currentOffset,
              opLength,
              Attribute<String>('link', AttributeScope.inline, uploadedUrl),
            );
          } catch (e) {
            debugPrint("Ошибка загрузки файла: $e");
          }
        }
      }

      // Увеличиваем текущую позицию на длину операции
      currentOffset += opLength;
    }
    //convertDeltaToHtml();
    _shouldDispose = true;
  }

  @override
  Future<void> openFileOrLink(String url) async {
    if (url.startsWith('https://') || url.startsWith('http://')) {
      // Проверяем, является ли это ссылкой на локальный файл
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

      // Декодируем URL (убираем лишние кодировки)
      final decodedUrl = Uri.decodeFull(url);
      // Заменяем пробелы на %20 вручную
      // Обычная веб-ссылка
      final uri = Uri.parse(decodedUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // Если путь сразу начинается с `file://`, убираем префикс
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
      onContentChanged?.call(internalHtml ?? '');
    }
    print(internalHtml);
  }

  // @override
  // Future<void> pickFile() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //
  //   if (image != null) await _insertImageIntoEditor(File(image.path));
  //
  // }
  //
  // Future<void> _insertImageIntoEditor(File file) async {
  //   final uploadedUrl = await uploadImage(file); // Загружаем файл и получаем URL
  //   final index = _controller.selection.baseOffset;
  //
  //   _controller.document.insert(index, BlockEmbed.image(uploadedUrl));
  // }

  @override
  Future<void> pickImage(ImageSource imageSource) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: imageSource);

    if (image != null) {
      final filePath = image.path;

      try {
        // Получаем директорию для хранения
        final directory = await getTemporaryDirectory();
        final newPath = path.join(directory.path, path.basename(filePath));

        //  Проверяем, существует ли исходный файл
        final originalFile = io.File(filePath);
        if (!await originalFile.exists()) {
          debugPrint("Файл не найден: $filePath");
          return;
        }

        // Копируем файл в локальное хранилище
        final localFile = await originalFile.copy(newPath);

        //  Проверяем, скопировался ли файл
        if (!await localFile.exists()) {
          debugPrint("Ошибка копирования файла: $newPath");
          return;
        }

        // Формируем корректный путь
        final localImagePath = 'file://${localFile.path}';

        // Вставляем картинку в редактор
        final index = _controller.selection.baseOffset;
        _controller.document.insert(index, BlockEmbed.image(localImagePath));

        // Уведомляем редактор об изменениях
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

        // Проверяем, что путь совпадает с тем, который хотим удалить
        if (localPath == imageUrl) {
          try {
            _controller.replaceText(
              index,
              1,
              '',
              TextSelection.collapsed(offset: index),
            );
            return; // Выходим из цикла, удалив нужную картинку
          } catch (e) {
            debugPrint("Ошибка удаления изображения: $e");
          }
        }
      }

      // Увеличиваем index на длину текущей операции
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
}
