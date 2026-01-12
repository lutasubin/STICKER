import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_painter_v2/flutter_painter.dart';
import 'package:get/get.dart';

enum _TextEditorTab { text, stroke, shadow, background }

class TextEditScreen extends StatefulWidget {
  const TextEditScreen({super.key, required this.controller});

  final PainterController controller;

  @override
  State<TextEditScreen> createState() => _TextEditScreenState();
}

class _TextEditScreenState extends State<TextEditScreen> {
  final _textController = TextEditingController();
  final _textFocusNode = FocusNode();

  TextDrawable? _editingDrawable;
  bool _syncingFromSelection = false;

  VoidCallback? _pendingControllerMutation;
  bool _controllerMutationScheduled = false;

  Size? _canvasSize;

  _TextEditorTab _tab = _TextEditorTab.text;

  bool get _isTypingMode => _textFocusNode.hasFocus;

  // Minimal state to mimic the UI; wiring into selected drawable will be done next.
  String _selectedFont = 'Roboto';
  Color _textColor = Colors.white;
  Color _strokeColor = Colors.black;
  double _strokeWidth = 3;
  Color _shadowColor = Colors.black.withOpacity(0.35);
  double _shadowBlur = 2;
  // ignore: prefer_final_fields
  Offset _shadowOffset = const Offset(2, 2);
  Color _backgroundColor = Colors.transparent;
  double _opacity = 1.0;

  Set<ObjectDrawableAssist> get _defaultTextAssists =>
      ObjectDrawableAssist.values.toSet();

  static const _fonts = [
    'Roboto',
    'Risque',
    'Rockwell Condensed',
    'Satisfy',
    'Pacifico',
    'Segoe Script',
  ];

  static const _palette = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    widget.controller.addListener(_onControllerChanged);

    _textFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Do not auto-create/select text on entry.
      // User must press keyboard icon (to type) or tap T tab (to select existing).
    });
  }

  TextDrawable? _findFirstTextDrawable() {
    dynamic list;
    try {
      final value = (widget.controller as dynamic).value;
      list = (value as dynamic).drawables;
    } catch (_) {}
    list ??= () {
      try {
        return (widget.controller as dynamic).drawables;
      } catch (_) {
        return null;
      }
    }();
    list ??= () {
      try {
        return (widget.controller as dynamic).objectDrawables;
      } catch (_) {
        return null;
      }
    }();

    if (list is Iterable) {
      for (final d in list) {
        if (d is TextDrawable) return d;
      }
    }
    return null;
  }

  bool _containsDrawable(Object drawable) {
    dynamic list;
    try {
      final value = (widget.controller as dynamic).value;
      list = (value as dynamic).drawables;
    } catch (_) {}
    list ??= () {
      try {
        return (widget.controller as dynamic).drawables;
      } catch (_) {
        return null;
      }
    }();
    list ??= () {
      try {
        return (widget.controller as dynamic).objectDrawables;
      } catch (_) {
        return null;
      }
    }();

    if (list is Iterable) {
      for (final d in list) {
        if (identical(d, drawable)) return true;
      }
    }
    return false;
  }

  void _selectExistingTextIfAny() {
    final d = _findFirstTextDrawable();
    if (d != null) {
      widget.controller.selectObjectDrawable(d);
      _editingDrawable = d;
      if (_textController.text.isEmpty) {
        _textController.text = d.text;
      }
      return;
    }

    // If there is no text yet, create one and select it so handles appear.
    _ensureEditingDrawable();
  }

  void _deselectObject() {
    try {
      (widget.controller as dynamic).deselectObjectDrawable();
      return;
    } catch (_) {}
    try {
      (widget.controller as dynamic).selectObjectDrawable(null);
      return;
    } catch (_) {}
    try {
      (widget.controller as dynamic).selectedObjectDrawable = null;
      return;
    } catch (_) {}
  }

  double _readRotation(TextDrawable drawable) {
    final d = drawable as dynamic;
    dynamic v;
    try {
      v = d.rotation;
    } catch (_) {}
    v ??= () {
      try {
        return d.angle;
      } catch (_) {
        return null;
      }
    }();
    v ??= () {
      try {
        return d.rotationAngle;
      } catch (_) {
        return null;
      }
    }();
    if (v is num) return v.toDouble();
    return 0;
  }

  double _readScale(TextDrawable drawable) {
    final d = drawable as dynamic;
    dynamic v;
    try {
      v = d.scale;
    } catch (_) {}
    v ??= () {
      try {
        return d.scaling;
      } catch (_) {
        return null;
      }
    }();
    v ??= () {
      try {
        return d.zoom;
      } catch (_) {
        return null;
      }
    }();
    if (v is num) return v.toDouble();
    return 1;
  }

  Set<ObjectDrawableAssist> _readAssists(TextDrawable drawable) {
    final d = drawable as dynamic;
    dynamic v;
    try {
      v = d.assists;
    } catch (_) {
      v = null;
    }

    if (v is Set<ObjectDrawableAssist>) return v;
    if (v is Iterable) {
      final out = v.whereType<ObjectDrawableAssist>().toSet();
      return out.isEmpty ? _defaultTextAssists : out;
    }
    return _defaultTextAssists;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final selected = widget.controller.selectedObjectDrawable;
    if (selected is! TextDrawable) return;
    if (identical(selected, _editingDrawable)) return;

    _editingDrawable = selected;

    // While the user is typing, we frequently replace the selected drawable.
    // Syncing the controller text on every selection change would reset IME state
    // and make typing feel "rời rạc".
    if (_textFocusNode.hasFocus && _textController.text == selected.text) {
      return;
    }

    _syncingFromSelection = true;
    _textController.text = selected.text;
    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
    _syncingFromSelection = false;
  }

  void _enqueueControllerMutation(VoidCallback fn) {
    // If we're idle, apply immediately so UI feels responsive.
    // Otherwise defer to a post-frame callback to avoid "mutated during layout" assertions.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      fn();
      return;
    }

    _pendingControllerMutation = fn;
    if (_controllerMutationScheduled) return;
    _controllerMutationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controllerMutationScheduled = false;
      final f = _pendingControllerMutation;
      _pendingControllerMutation = null;

      if (f == null) return;
      if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        f();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((__) {
          if (!mounted) return;
          f();
        });
      }
    });
  }

  TextStyle _buildTextStyle() {
    // NOTE: This does NOT yet render fill+stroke simultaneously.
    // It is used as a first step to get the screen and workflows in place.
    return TextStyle(
      fontFamily: _selectedFont,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: _textColor.withOpacity(_opacity),
      shadows: [
        if (_shadowBlur > 0)
          Shadow(
            color: _shadowColor,
            offset: _shadowOffset,
            blurRadius: _shadowBlur,
          ),
      ],
      backgroundColor: _backgroundColor,
    );
  }

  void _ensureEditingDrawable({bool createNew = false}) {
    // Nếu createNew = true, luôn tạo text mới
    if (!createNew) {
      final selected = widget.controller.selectedObjectDrawable;
      if (selected is TextDrawable) {
        _editingDrawable = selected;
        if (_textController.text.isEmpty) {
          _textController.text = selected.text;
        }
        return;
      }

      if (_editingDrawable != null) {
        if (!_containsDrawable(_editingDrawable!)) {
          _editingDrawable = null;
        } else if (!_isTypingMode) {
          widget.controller.selectObjectDrawable(_editingDrawable!);
          return;
        } else {
          return;
        }
      }
    }

    // Tạo text mới
    final canvasSize = _canvasSize;
    // Vị trí mặc định: giữa canvas, nhưng offset một chút để tránh trùng với text cũ
    final existingTexts = _getAllTextDrawables();
    final offsetY =
        existingTexts.length * 40.0; // Offset theo số lượng text đã có
    final initialPosition =
        canvasSize == null
            ? Offset.zero
            : Offset(
              canvasSize.width / 2,
              (canvasSize.height / 2) +
                  offsetY -
                  (existingTexts.isNotEmpty ? 20 : 0),
            );

    final drawable = TextDrawable(
      text: _textController.text.isEmpty ? 'Text' : _textController.text,
      position: initialPosition,
      rotation: 0,
      scale: 1,
      style: _buildTextStyle(),
      direction: TextDirection.ltr,
      locked: false,
      hidden: false,
      assists: _defaultTextAssists,
    );

    widget.controller.addDrawables([drawable]);
    if (!_isTypingMode) {
      widget.controller.selectObjectDrawable(drawable);
    }
    _editingDrawable = drawable;

    // Nếu text controller rỗng, set text mặc định
    if (_textController.text.isEmpty) {
      _textController.text = 'Text';
      _textController.selection = TextSelection.collapsed(offset: 4);
    }
  }

  /// Lấy tất cả text drawables hiện có
  List<TextDrawable> _getAllTextDrawables() {
    dynamic list;
    try {
      final value = (widget.controller as dynamic).value;
      list = (value as dynamic).drawables;
    } catch (_) {}
    list ??= () {
      try {
        return (widget.controller as dynamic).drawables;
      } catch (_) {
        return null;
      }
    }();
    list ??= () {
      try {
        return (widget.controller as dynamic).objectDrawables;
      } catch (_) {
        return null;
      }
    }();

    if (list is Iterable) {
      return list.whereType<TextDrawable>().toList();
    }
    return [];
  }

  void _replaceEditingDrawable(TextDrawable next) {
    final prev = _editingDrawable;
    if (prev == null) {
      widget.controller.addDrawables([next]);
      if (!_isTypingMode) {
        widget.controller.selectObjectDrawable(next);
      } else {
        _deselectObject();
      }
      _editingDrawable = next;
      return;
    }

    var removed = false;
    try {
      // Different versions of flutter_painter_v2 expose slightly different APIs.
      (widget.controller as dynamic).removeDrawables([prev]);
      removed = true;
    } catch (_) {}

    if (!removed) {
      try {
        (widget.controller as dynamic).removeDrawable(prev);
        removed = true;
      } catch (_) {}
    }

    // Fallback: remove directly from whichever internal list exists.
    if (!removed) {
      try {
        final value = (widget.controller as dynamic).value;
        final list = (value as dynamic).drawables as List;
        removed = list.remove(prev);
        (widget.controller as dynamic).notifyListeners();
      } catch (_) {}
    }
    if (!removed) {
      try {
        final list = (widget.controller as dynamic).drawables as List;
        removed = list.remove(prev);
        (widget.controller as dynamic).notifyListeners();
      } catch (_) {}
    }
    if (!removed) {
      try {
        final list = (widget.controller as dynamic).objectDrawables as List;
        removed = list.remove(prev);
        (widget.controller as dynamic).notifyListeners();
      } catch (_) {}
    }

    widget.controller.addDrawables([next]);
    if (!_isTypingMode) {
      widget.controller.selectObjectDrawable(next);
    } else {
      _deselectObject();
    }
    _editingDrawable = next;
  }

  void _onTextChanged() {
    if (_syncingFromSelection) return;
    _enqueueControllerMutation(() {
      _ensureEditingDrawable();

      final prev = _editingDrawable;
      if (prev == null) return;

      final prevRotation = _readRotation(prev);
      final prevScale = _readScale(prev);

      final next = TextDrawable(
        text: _textController.text,
        position: prev.position,
        rotation: prevRotation,
        scale: prevScale,
        style: _buildTextStyle(),
        direction: prev.direction,
        locked: prev.locked,
        hidden: prev.hidden,
        assists: _readAssists(prev),
      );

      _replaceEditingDrawable(next);
    });
  }

  void _applyStyleToSelected() {
    _enqueueControllerMutation(() {
      _ensureEditingDrawable();
      final prev = _editingDrawable;
      if (prev == null) return;

      final prevRotation = _readRotation(prev);
      final prevScale = _readScale(prev);

      final next = TextDrawable(
        text: prev.text,
        position: prev.position,
        rotation: prevRotation,
        scale: prevScale,
        style: _buildTextStyle(),
        direction: prev.direction,
        locked: prev.locked,
        hidden: prev.hidden,
        assists: _readAssists(prev),
      );

      _replaceEditingDrawable(next);
    });
  }

  void _toggleKeyboard() {
    if (_textFocusNode.hasFocus) {
      _textFocusNode.unfocus();
      _enqueueControllerMutation(() {
        final prev = _editingDrawable;
        if (prev == null) return;
        final prevRotation = _readRotation(prev);
        final prevScale = _readScale(prev);
        final next = TextDrawable(
          text: prev.text,
          position: prev.position,
          rotation: prevRotation,
          scale: prevScale,
          style: prev.style,
          direction: prev.direction,
          locked: prev.locked,
          hidden: prev.hidden,
          assists: _defaultTextAssists,
        );
        _replaceEditingDrawable(next);
      });
      return;
    }

    _enqueueControllerMutation(() {
      _ensureEditingDrawable();
      final prev = _editingDrawable;
      if (prev == null) return;
      final prevRotation = _readRotation(prev);
      final prevScale = _readScale(prev);
      final next = TextDrawable(
        text: prev.text,
        position: prev.position,
        rotation: prevRotation,
        scale: prevScale,
        style: prev.style,
        direction: prev.direction,
        locked: prev.locked,
        hidden: prev.hidden,
        assists: const <ObjectDrawableAssist>{},
      );
      _replaceEditingDrawable(next);
      _deselectObject();
      _textFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Get.back(result: false),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: const Text(
          'Văn Bản',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () => Get.back(result: true),
            icon: const Icon(Icons.check, color: Colors.black),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Dùng canvas size cố định 512x512 giống như edit_sticker_screen
                      const canvasSize = 512.0;
                      final screenSize = MediaQuery.sizeOf(context);
                      final maxSize = screenSize.shortestSide * 0.85;
                      final displaySize = canvasSize.clamp(200.0, maxSize);

                      // Lưu canvas size để dùng khi tạo text mới
                      _canvasSize = Size.square(canvasSize);

                      // Tính scale ratio để scale từ canvas size (512x512) lên display size
                      final scaleRatio = displaySize / canvasSize;

                      return SizedBox(
                        width: displaySize,
                        height: displaySize,
                        child: _CheckerboardBackground(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: Theme.of(context).colorScheme
                                  .copyWith(primary: const Color(0xFF2196F3)),
                            ),
                            child: Center(
                              // Dùng Transform.scale với alignment center để scale từ 512x512 lên displaySize
                              // Đảm bảo FlutterPainter luôn dùng tọa độ 512x512, chỉ scale để hiển thị
                              child: Transform.scale(
                                scale: scaleRatio,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: canvasSize,
                                  height: canvasSize,
                                  child: FlutterPainter(
                                    controller: widget.controller,
                                    onDrawableDeleted: (d) {
                                      if (d is! TextDrawable) return;
                                      if (!mounted) return;
                                      if (identical(d, _editingDrawable)) {
                                        _editingDrawable = null;
                                        _syncingFromSelection = true;
                                        _textController.clear();
                                        _syncingFromSelection = false;
                                        _textFocusNode.unfocus();
                                      }
                                    },
                                    onSelectedObjectDrawableChanged: (d) {
                                      if (!mounted) return;
                                      if (d is TextDrawable) {
                                        _editingDrawable = d;
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _BottomToolbar(
                tab: _tab,
                keyboardActive: _textFocusNode.hasFocus,
                textSelected:
                    widget.controller.selectedObjectDrawable is TextDrawable,
                onTabChanged: (t) {
                  setState(() => _tab = t);
                  _textFocusNode.unfocus();
                  if (t == _TextEditorTab.text) {
                    // T tab: only select existing text to show handles; do not type.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _selectExistingTextIfAny();
                    });
                  }
                },
                onKeyboardPressed: _toggleKeyboard,
                onAddText: () {
                  // Tạo text mới
                  _enqueueControllerMutation(() {
                    // Clear text controller để tạo text mới
                    _textController.clear();
                    _editingDrawable = null;
                    // Deselect text hiện tại nếu có
                    _deselectObject();
                    // Tạo text mới ở vị trí giữa canvas với offset
                    _ensureEditingDrawable(createNew: true);
                    // Focus vào keyboard để user có thể gõ ngay
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _textFocusNode.requestFocus();
                      }
                    });
                  });
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child:
                    _textFocusNode.hasFocus
                        ? const SizedBox.shrink()
                        : _BottomPanel(
                          tab: _tab,
                          textController: _textController,
                          focusNode: _textFocusNode,
                          selectedFont: _selectedFont,
                          fonts: _fonts,
                          onFontSelected: (f) {
                            setState(() => _selectedFont = f);
                            _applyStyleToSelected();
                          },
                          palette: _palette,
                          textColor: _textColor,
                          onTextColorChanged: (c) {
                            setState(() => _textColor = c);
                            _applyStyleToSelected();
                          },
                          strokeColor: _strokeColor,
                          onStrokeColorChanged: (c) {
                            setState(() => _strokeColor = c);
                            _applyStyleToSelected();
                          },
                          strokeWidth: _strokeWidth,
                          onStrokeWidthChanged: (v) {
                            setState(() => _strokeWidth = v);
                            _applyStyleToSelected();
                          },
                          shadowColor: _shadowColor,
                          onShadowColorChanged: (c) {
                            setState(() => _shadowColor = c);
                            _applyStyleToSelected();
                          },
                          shadowBlur: _shadowBlur,
                          onShadowBlurChanged: (v) {
                            setState(() => _shadowBlur = v);
                            _applyStyleToSelected();
                          },
                          backgroundColor: _backgroundColor,
                          onBackgroundColorChanged: (c) {
                            setState(() => _backgroundColor = c);
                            _applyStyleToSelected();
                          },
                          opacity: _opacity,
                          onOpacityChanged: (v) {
                            setState(() => _opacity = v);
                            _applyStyleToSelected();
                          },
                        ),
              ),
            ],
          ),
          Offstage(
            offstage: true,
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({
    required this.tab,
    required this.keyboardActive,
    required this.textSelected,
    required this.onTabChanged,
    required this.onKeyboardPressed,
    required this.onAddText,
  });

  final _TextEditorTab tab;
  final bool keyboardActive;
  final bool textSelected;
  final ValueChanged<_TextEditorTab> onTabChanged;
  final VoidCallback onKeyboardPressed;
  final VoidCallback onAddText;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Nút Add Text - tạo text mới
            IconButton(
              onPressed: onAddText,
              icon: const Icon(Icons.add, color: Color(0xFF00C979)),
              tooltip: 'Thêm text mới',
            ),
            IconButton(
              onPressed: onKeyboardPressed,
              icon: Icon(
                Icons.keyboard,
                color:
                    keyboardActive ? const Color(0xFF00C979) : Colors.black54,
              ),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.text && textSelected,
              icon: Icons.title,
              onTap: () => onTabChanged(_TextEditorTab.text),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.stroke,
              icon: Icons.border_color,
              onTap: () => onTabChanged(_TextEditorTab.stroke),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.shadow,
              icon: Icons.blur_on,
              onTap: () => onTabChanged(_TextEditorTab.shadow),
            ),
            _ToolIcon(
              selected: tab == _TextEditorTab.background,
              icon: Icons.chat_bubble_outline,
              onTap: () => onTabChanged(_TextEditorTab.background),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolIcon extends StatelessWidget {
  const _ToolIcon({
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF00C979) : Colors.black54;
    return IconButton(onPressed: onTap, icon: Icon(icon, color: color));
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.tab,
    required this.textController,
    required this.focusNode,
    required this.selectedFont,
    required this.fonts,
    required this.onFontSelected,
    required this.palette,
    required this.textColor,
    required this.onTextColorChanged,
    required this.strokeColor,
    required this.onStrokeColorChanged,
    required this.strokeWidth,
    required this.onStrokeWidthChanged,
    required this.shadowColor,
    required this.onShadowColorChanged,
    required this.shadowBlur,
    required this.onShadowBlurChanged,
    required this.backgroundColor,
    required this.onBackgroundColorChanged,
    required this.opacity,
    required this.onOpacityChanged,
  });

  final _TextEditorTab tab;

  final TextEditingController textController;
  final FocusNode focusNode;

  final String selectedFont;
  final List<String> fonts;
  final ValueChanged<String> onFontSelected;

  final List<Color> palette;
  final Color textColor;
  final ValueChanged<Color> onTextColorChanged;

  final Color strokeColor;
  final ValueChanged<Color> onStrokeColorChanged;
  final double strokeWidth;
  final ValueChanged<double> onStrokeWidthChanged;

  final Color shadowColor;
  final ValueChanged<Color> onShadowColorChanged;
  final double shadowBlur;
  final ValueChanged<double> onShadowBlurChanged;

  final Color backgroundColor;
  final ValueChanged<Color> onBackgroundColorChanged;

  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEAEAEA))),
        ),
        child: switch (tab) {
          _TextEditorTab.text => _TextTab(
            textController: textController,
            focusNode: focusNode,
            selectedFont: selectedFont,
            fonts: fonts,
            onFontSelected: onFontSelected,
            palette: palette,
            textColor: textColor,
            onTextColorChanged: onTextColorChanged,
          ),
          _TextEditorTab.stroke => _EffectsTab(
            title: 'Đường viền',
            palette: palette,
            selectedColor: strokeColor,
            onColorSelected: onStrokeColorChanged,
            sliderLabel: 'Độ dày',
            sliderValue: strokeWidth,
            sliderMin: 0,
            sliderMax: 10,
            onSliderChanged: onStrokeWidthChanged,
            opacity: opacity,
            onOpacityChanged: onOpacityChanged,
          ),
          _TextEditorTab.shadow => _EffectsTab(
            title: 'Bóng',
            palette: palette,
            selectedColor: shadowColor,
            onColorSelected: onShadowColorChanged,
            sliderLabel: 'Độ mờ',
            sliderValue: shadowBlur,
            sliderMin: 0,
            sliderMax: 10,
            onSliderChanged: onShadowBlurChanged,
            opacity: opacity,
            onOpacityChanged: onOpacityChanged,
          ),
          _TextEditorTab.background => _EffectsTab(
            title: 'Nền',
            palette: palette,
            selectedColor: backgroundColor,
            onColorSelected: onBackgroundColorChanged,
            sliderLabel: 'Độ mờ',
            sliderValue: opacity,
            sliderMin: 0,
            sliderMax: 1,
            onSliderChanged: onOpacityChanged,
            opacity: opacity,
            onOpacityChanged: onOpacityChanged,
          ),
        },
      ),
    );
  }
}

class _TextTab extends StatelessWidget {
  const _TextTab({
    required this.textController,
    required this.focusNode,
    required this.selectedFont,
    required this.fonts,
    required this.onFontSelected,
    required this.palette,
    required this.textColor,
    required this.onTextColorChanged,
  });

  final TextEditingController textController;
  final FocusNode focusNode;

  final String selectedFont;
  final List<String> fonts;
  final ValueChanged<String> onFontSelected;

  final List<Color> palette;
  final Color textColor;
  final ValueChanged<Color> onTextColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Màu chữ', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final c = palette[index];
              final selected = c.value == textColor.value;
              return GestureDetector(
                onTap: () => onTextColorChanged(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFDDDDDD),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text('Font', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2.4,
            ),
            itemCount: fonts.length,
            itemBuilder: (context, index) {
              final f = fonts[index];
              final selected = f == selectedFont;
              return InkWell(
                onTap: () => onFontSelected(f),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFE0E0E0),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    f,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: f,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EffectsTab extends StatelessWidget {
  const _EffectsTab({
    required this.title,
    required this.palette,
    required this.selectedColor,
    required this.onColorSelected,
    required this.sliderLabel,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.onSliderChanged,
    required this.opacity,
    required this.onOpacityChanged,
  });

  final String title;
  final List<Color> palette;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  final String sliderLabel;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final ValueChanged<double> onSliderChanged;

  final double opacity;
  final ValueChanged<double> onOpacityChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final c = palette[index];
              final selected = c.value == selectedColor.value;
              return GestureDetector(
                onTap: () => onColorSelected(c),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          selected
                              ? const Color(0xFF00C979)
                              : const Color(0xFFDDDDDD),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Text(sliderLabel, style: const TextStyle(color: Colors.black54)),
        Slider(
          value: sliderValue.clamp(sliderMin, sliderMax),
          min: sliderMin,
          max: sliderMax,
          onChanged: onSliderChanged,
        ),
        const SizedBox(height: 6),
        const Text('Độ mờ', style: TextStyle(color: Colors.black54)),
        Slider(value: opacity, min: 0, max: 1, onChanged: onOpacityChanged),
      ],
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CheckerboardPainter(
        light: const Color(0xFFF3F3F3),
        dark: const Color(0xFFE3E3E3),
        squareSize: 24,
      ),
      child: child,
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  _CheckerboardPainter({
    required this.light,
    required this.dark,
    required this.squareSize,
  });

  final Color light;
  final Color dark;
  final double squareSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isDark =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 1;
        paint.color = isDark ? dark : light;
        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) {
    return oldDelegate.light != light ||
        oldDelegate.dark != dark ||
        oldDelegate.squareSize != squareSize;
  }
}
