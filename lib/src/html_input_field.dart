import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:html_editor/editor.dart';

class HtmlInputField extends StatefulWidget {
  final TextEditingController? controller;
  final Function(String?)? onChanged;
  final Function()? onCleanTap;
  final String? label;
  final String? hint;
  final bool isLoading;
  final bool isMultiline;
  final bool showClearButton;
  final String? helpText;
  final String? errorText;
  final List<String>? autofillHints;
  final bool isError;
  final int? maxLines;
  final bool isObscureText;
  final Widget? prefixIcon;
  final Widget? suffixIconWidget;
  final List<TextInputFormatter>? textInputFormatter;
  final FocusNode? focusNode;
  final TextInputType? textInputType;
  final EdgeInsets? customContentPadding;
  final Color? fillColor;
  final void Function(PointerDownEvent)? onTapOutside;
  final TextStyle? hintStyle;
  final TextStyle? style;
  final Widget? additionalComponent;
  final bool enabled;
  final String? initialValue;
  final bool? isDense;
  final Color? borderColor;
  final ScrollController? scrollController;
  final TextStyle? labelStyle;
  final String? Function(String?)? validator;
  final int errorMaxLines;
  final bool enableInteractiveSelection;
  final TextCapitalization textCapitalization;
  final Function(bool hasFocus)? onFocusChanged;
  final Color? cursorColor;
  final InputBorder? focusedBorder;
  final BuildContext? context;

  const HtmlInputField({
    super.key,
    this.controller,
    this.showClearButton = true,
    this.isMultiline = false,
    this.onChanged,
    this.autofillHints,
    this.label,
    this.hint,
    this.isLoading = false,
    this.helpText,
    this.maxLines,
    this.suffixIconWidget,
    this.errorText,
    this.isError = false,
    this.isObscureText = false,
    this.prefixIcon,
    this.textInputFormatter,
    this.focusNode,
    this.textInputType,
    this.onCleanTap,
    this.customContentPadding,
    this.fillColor,
    this.onTapOutside,
    this.hintStyle,
    this.style,
    this.additionalComponent,
    this.enabled = true,
    this.initialValue,
    this.isDense,
    this.borderColor,
    this.scrollController,
    this.labelStyle,
    this.validator,
    this.errorMaxLines = 3,
    this.enableInteractiveSelection = true,
    this.textCapitalization = TextCapitalization.none,
    this.onFocusChanged,
    this.cursorColor,
    this.focusedBorder,
    this.context,
  });

  @override
  State<HtmlInputField> createState() => _HtmlInputFieldState();
}

class _HtmlInputFieldState extends State<HtmlInputField> {
  late final FocusNode focusNode;
  late final TextEditingController textEditingController;
  late final ScrollController scrollController;
  late bool _isObscureText;

  @override
  void initState() {
    textEditingController =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    scrollController = widget.scrollController ?? ScrollController();
    focusNode = widget.focusNode ?? FocusNode();
    _isObscureText = widget.isObscureText;

    if (mounted) {
      focusNode.addListener(() {
        setState(() {
          widget.onFocusChanged?.call(focusNode.hasFocus);
        });
      });
      textEditingController.addListener(() {
        setState(() {});
      });
    }

    super.initState();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) focusNode.dispose();
    if (widget.controller == null) textEditingController.dispose();
    if (widget.scrollController == null) scrollController.dispose();
    super.dispose();
  }

  bool get showClearButton =>
      widget.showClearButton && textEditingController.text.isNotEmpty;

  @override
  Widget build(BuildContext buildContext) {
    final context = widget.context ?? buildContext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) _buildLabel(context),
        if (widget.additionalComponent != null)
          Row(
            children: [
              Flexible(
                child: SizedBox(
                  width: double.maxFinite,
                  child: _buildTextField(context),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              widget.additionalComponent!,
            ],
          )
        else
          _buildTextField(context),
      ],
    );
  }

  Widget _buildLabel(BuildContext context) {
    return Text(
      widget.label ?? '',
      style: widget.labelStyle ?? AppTextStyle.headlineH18Regular,
    );
  }

  Color _getColorElem(BuildContext context) {
    Color colorElem = context.editorTheme.gray0;
    if (focusNode.hasFocus && !widget.isError) {
      colorElem = context.editorTheme.gray800;
    } else if (widget.isError) {
      colorElem = context.editorTheme.red500;
    } else {
      colorElem = context.editorTheme.bg;
    }
    return colorElem;
  }

  InputBorder _getInputBorder(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      borderSide:
          BorderSide(color: widget.borderColor ?? _getColorElem(context)),
    );
  }

  Widget _buildTextField(BuildContext context) {
    return TextFormField(
      scrollController: scrollController,
      autofillHints: widget.autofillHints,
      controller: textEditingController,
      focusNode: focusNode,
      onTapOutside: widget.onTapOutside,
      obscureText: _isObscureText,
      cursorColor: widget.cursorColor,
      minLines: 1,
      textCapitalization: widget.textCapitalization,
      maxLines: widget.maxLines ?? (widget.isMultiline ? null : 1),
      style: widget.style ??
          AppTextStyle.headlineH18Regular.copyWith(
            color: widget.enabled
                ? context.editorTheme.gray800
                : context.editorTheme.gray800.withValues(alpha: 0.6),
          ),
      enabled: widget.enabled,
      keyboardType: widget.textInputType ?? TextInputType.text,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      contextMenuBuilder: widget.enableInteractiveSelection
          ? (context, editableTextState) {
              final buttonItems = editableTextState.contextMenuButtonItems;
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: buttonItems,
              );
            }
          : null,
      decoration: InputDecoration(
        prefixIcon: widget.prefixIcon,
        errorMaxLines: widget.errorMaxLines,
        contentPadding: widget.customContentPadding ??
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 19,
            ),
        counterText: '',
        border: _getInputBorder(context),
        enabledBorder: _getInputBorder(context),
        focusedBorder: widget.focusedBorder ?? _getInputBorder(context),
        disabledBorder: _getInputBorder(context),
        suffixIcon: _buildSuffixIcon(context),
        isDense: widget.isDense,
        filled: true,
        hintText: widget.hint,
        hintStyle: widget.hintStyle ??
            AppTextStyle.headlineH18Regular
                .copyWith(color: context.editorTheme.gray400),
        fillColor: widget.fillColor ?? context.editorTheme.gray50,
      ),
      inputFormatters: [
        if (widget.textInputFormatter != null) ...widget.textInputFormatter!,
      ],
      onChanged: (text) {
        if (widget.onChanged != null) {
          widget.onChanged!(text);
        }
      },
    );
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.suffixIconWidget == null &&
        !widget.isLoading &&
        !widget.isObscureText &&
        !showClearButton) {
      return null;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.suffixIconWidget != null) widget.suffixIconWidget!,
        if (widget.isLoading) _buildLoadingIcon(context),
        if (widget.enabled && showClearButton && !widget.isLoading)
          _buildCleanButton(context),
      ],
    );
  }

  Widget _buildLoadingIcon(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: CircularProgressIndicator.adaptive(),
    );
  }

  Widget _buildCleanButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onCleanButtonPressed,
        child: SvgPicture.asset(
          HtmlIcons.close,
          width: 24,
          height: 24,
          color: context.editorTheme.gray500,
        ),
      ),
    );
  }

  void onCleanButtonPressed() {
    textEditingController.clear();
    widget.onCleanTap?.call();
  }

  void onEyeButtonPressed() => setState(() {
        _isObscureText = !_isObscureText;
      });
}
