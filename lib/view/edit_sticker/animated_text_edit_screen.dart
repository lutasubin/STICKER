import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

/// Text editor tabs - giống sticker tĩnh - export để dùng chung
enum AnimatedTextEditorTab { text, stroke, shadow, background }

/// Model cho mỗi text item - export để dùng chung
class AnimatedTextItem {
  final String id;
  String text;
  Offset position;
  Color textColor;
  Color? backgroundColor;
  double fontSize;
  double scale;
  FontWeight fontWeight;
  String fontFamily;
  final TextAlign textAlign;

  // Stroke (viền text) - giống sticker tĩnh
  Color? strokeColor;
  double strokeWidth;

  // Shadow (đổ bóng) - giống sticker tĩnh
  Color? shadowColor;
  double shadowBlur;
  Offset shadowOffset;
  double opacity;

  AnimatedTextItem({
    required this.id,
    required this.text,
    required this.position,
    this.textColor = Colors.white,
    this.backgroundColor,
    this.fontSize = 40.0,
    this.scale = 1.0,
    this.fontWeight = FontWeight.bold,
    this.fontFamily = 'Roboto',
    this.textAlign = TextAlign.center,
    this.strokeColor,
    this.strokeWidth = 0.0,
    this.shadowColor,
    this.shadowBlur = 0.0,
    this.shadowOffset = const Offset(2, 2),
    this.opacity = 1.0,
  });

  AnimatedTextItem copyWith({
    String? text,
    Offset? position,
    Color? textColor,
    Color? backgroundColor,
    double? fontSize,
    double? scale,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? strokeColor,
    double? strokeWidth,
    Color? shadowColor,
    double? shadowBlur,
    Offset? shadowOffset,
    double? opacity,
  }) {
    return AnimatedTextItem(
      id: id,
      text: text ?? this.text,
      position: position ?? this.position,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontSize: fontSize ?? this.fontSize,
      scale: scale ?? this.scale,
      fontWeight: fontWeight ?? this.fontWeight,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffset: shadowOffset ?? this.shadowOffset,
      opacity: opacity ?? this.opacity,
    );
  }
}

class AnimatedTextEditScreen extends StatefulWidget {
  const AnimatedTextEditScreen({
    super.key,
    required this.videoFile,
    required this.textItems,
    required this.selectedTextId,
    required this.onTextItemsChanged,
    required this.onSelectedTextIdChanged,
  });

  final File videoFile;
  final List<AnimatedTextItem> textItems;
  final String? selectedTextId;
  final Function(List<AnimatedTextItem>) onTextItemsChanged;
  final Function(String?) onSelectedTextIdChanged;

  @override
  State<AnimatedTextEditScreen> createState() => _AnimatedTextEditScreenState();
}

class _AnimatedTextEditScreenState extends State<AnimatedTextEditScreen> {
  late List<AnimatedTextItem> _textItems;
  String? _selectedTextId;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  AnimatedTextEditorTab _textEditorTab = AnimatedTextEditorTab.text;

  // Video player
  VideoPlayerController? _videoController;
  bool _isDisposed = false;
  bool _isVideoPausedForGesture =
      false; // Track if video was paused for gesture

  // Fonts list - giống sticker tĩnh
  static const List<String> _fonts = [
    'Roboto',
    'Risque',
    'Rockwell Condensed',
    'Satisfy',
    'Pacifico',
    'Segoe Script',
  ];

  // Color palette - giống sticker tĩnh
  static const List<Color> _palette = [
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
    Color(0xFF00C979),
  ];

  @override
  void initState() {
    super.initState();
    _textItems = List.from(widget.textItems);
    _selectedTextId = widget.selectedTextId;
    _textController.addListener(_onTextChanged);
    _initVideoPlayer();
    // Không tự động focus - chỉ focus khi bấm icon keyboard
  }

  Future<void> _initVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.file(widget.videoFile);
      await _videoController!.initialize();
      _videoController!.setLooping(false);
      _videoController!.play();
      _videoController!.addListener(_videoListener);
      if (mounted && !_isDisposed) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _videoListener() {
    if (_isDisposed || _videoController == null) return;
    try {
      final value = _videoController!.value;
      if (value.isPlaying &&
          value.position >= value.duration &&
          value.duration > Duration.zero) {
        _videoController!.pause();
        _videoController!.seekTo(Duration.zero);
      }
    } catch (e) {
      debugPrint('Error in video listener: $e');
    }
  }

  @override
  void didUpdateWidget(AnimatedTextEditScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textItems != widget.textItems) {
      _textItems = List.from(widget.textItems);
    }
    if (oldWidget.selectedTextId != widget.selectedTextId) {
      _selectedTextId = widget.selectedTextId;
      _updateTextController();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _videoController?.removeListener(_videoListener);
    _videoController?.pause();
    _videoController?.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  AnimatedTextItem? get _selectedTextItem {
    if (_selectedTextId == null) return null;
    try {
      return _textItems.firstWhere((item) => item.id == _selectedTextId);
    } catch (e) {
      return null;
    }
  }

  void _updateTextController() {
    final item = _selectedTextItem;
    if (item != null && _textController.text != item.text) {
      _textController.text = item.text;
    } else if (item == null) {
      _textController.text = '';
    }
  }

  void _onTextChanged() {
    final newText = _textController.text;
    final selectedItem = _selectedTextItem;

    if (selectedItem != null && selectedItem.text != newText) {
      final index = _textItems.indexWhere((i) => i.id == selectedItem.id);
      if (index != -1) {
        setState(() {
          _textItems[index] = selectedItem.copyWith(text: newText);
        });
        widget.onTextItemsChanged(_textItems);
      }
    }
  }

  void _addNewText() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newTextItem = AnimatedTextItem(
      id: newId,
      text: '',
      position: const Offset(256, 256),
      textColor: Colors.white,
      fontSize: 40.0,
      scale: 1.0,
    );

    setState(() {
      _textItems.add(newTextItem);
      _selectedTextId = newId;
      _textController.text = '';
    });
    widget.onTextItemsChanged(_textItems);
    widget.onSelectedTextIdChanged(_selectedTextId);
    // Không tự động focus - user phải bấm icon keyboard để nhập
  }

  void _deleteSelectedText() {
    if (_selectedTextId != null) {
      setState(() {
        _textItems.removeWhere((item) => item.id == _selectedTextId);
        _selectedTextId = null;
        _textController.text = '';
      });
      widget.onTextItemsChanged(_textItems);
      widget.onSelectedTextIdChanged(null);
    }
  }

  void _selectTextItem(String id) {
    setState(() {
      _selectedTextId = id;
      final item = _textItems.firstWhere((i) => i.id == id);
      _textController.text = item.text;
    });
    widget.onSelectedTextIdChanged(_selectedTextId);
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = _selectedTextItem;
    final keyboardActive = _textFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset:
          false, // Không resize màn hình khi keyboard hiện
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Get.back(result: false),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: Text(
          'text_edit_title'.tr,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
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
                      // Dùng canvas size cố định 512x512 để tính toán position text
                      const canvasSize = 512.0;
                      // Video hiển thị to - dùng toàn bộ không gian có sẵn, giống màn edit
                      final availableWidth = constraints.maxWidth;
                      final availableHeight = constraints.maxHeight;
                      // Dùng cạnh ngắn nhất để đảm bảo video vuông
                      final displaySize =
                          availableWidth < availableHeight
                              ? availableWidth
                              : availableHeight;
                      final scaleRatio = displaySize / canvasSize;

                      return SizedBox(
                        width: displaySize,
                        height: displaySize,
                        child: Container(
                          color: Colors.white,
                          child: Center(
                            child: Transform.scale(
                              scale: scaleRatio,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: canvasSize,
                                height: canvasSize,
                                child: Stack(
                                  children: [
                                    // Video player
                                    if (_videoController != null &&
                                        _videoController!.value.isInitialized)
                                      Positioned.fill(
                                        child: VideoPlayer(_videoController!),
                                      )
                                    else
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    // Text overlays - có thể di chuyển được (tối ưu với ValueNotifier)
                                    ..._textItems.map((item) {
                                      return _DraggableTextOverlay(
                                        key: ValueKey(item.id),
                                        item: item,
                                        isSelected: item.id == _selectedTextId,
                                        scaleRatio: scaleRatio,
                                        onTap: () {
                                          setState(() {
                                            _selectedTextId = item.id;
                                            _textController.text = item.text;
                                          });
                                          widget.onSelectedTextIdChanged(
                                            _selectedTextId,
                                          );
                                        },
                                        onTransform: (newPosition, newScale) {
                                          final index = _textItems.indexWhere(
                                            (i) => i.id == item.id,
                                          );
                                          if (index != -1 &&
                                              mounted &&
                                              !_isDisposed) {
                                            setState(() {
                                              _textItems[index] = item.copyWith(
                                                position: newPosition,
                                                scale: newScale,
                                              );
                                            });
                                            widget.onTextItemsChanged(
                                              _textItems,
                                            );
                                          }
                                        },
                                      );
                                    }),
                                  ],
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
                tab: _textEditorTab,
                keyboardActive: keyboardActive,
                textSelected: selectedItem != null,
                onTabChanged: (t) {
                  setState(() => _textEditorTab = t);
                  _textFocusNode.unfocus();
                  if (t == AnimatedTextEditorTab.text) {
                    // Select existing text if any
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || _isDisposed) return;
                      if (_textItems.isNotEmpty && _selectedTextId == null) {
                        _selectTextItem(_textItems.first.id);
                      }
                    });
                  }
                },
                onKeyboardPressed: _toggleKeyboard,
                onAddText: _addNewText,
                onDeleteText:
                    _selectedTextId != null ? _deleteSelectedText : null,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child:
                    keyboardActive
                        ? const SizedBox.shrink()
                        : _BottomPanel(
                          tab: _textEditorTab,
                          selectedItem: selectedItem,
                          onItemChanged: (updatedItem) {
                            final index = _textItems.indexWhere(
                              (i) => i.id == updatedItem.id,
                            );
                            if (index != -1) {
                              setState(() {
                                _textItems[index] = updatedItem;
                              });
                              widget.onTextItemsChanged(_textItems);
                            }
                          },
                          fonts: _fonts,
                          palette: _palette,
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

  void _toggleKeyboard() {
    if (_textFocusNode.hasFocus) {
      _textFocusNode.unfocus();
    } else {
      if (_textItems.isEmpty) {
        _addNewText();
      } else {
        _textFocusNode.requestFocus();
      }
    }
  }
}

/// Draggable text overlay với ValueNotifier để di chuyển mượt - giống sticker tĩnh
class _DraggableTextOverlay extends StatefulWidget {
  const _DraggableTextOverlay({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.onTransform,
    required this.scaleRatio,
  });

  final AnimatedTextItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(Offset position, double scale) onTransform;
  final double scaleRatio; // Tỷ lệ scale từ display size về canvas size

  @override
  State<_DraggableTextOverlay> createState() => _DraggableTextOverlayState();
}

class _DraggableTextOverlayState extends State<_DraggableTextOverlay> {
  // Dùng ValueNotifier để tối ưu - chỉ rebuild Transform, không rebuild toàn bộ widget
  late final ValueNotifier<Offset> _positionNotifier;
  late final ValueNotifier<double> _scaleNotifier;
  late Offset _position;
  late double _scale;
  Offset? _panStart;
  Offset? _focalPointStart; // Điểm bắt đầu của gesture
  double? _scaleStart;

  @override
  void initState() {
    super.initState();
    _position = widget.item.position;
    _scale = widget.item.scale;
    _positionNotifier = ValueNotifier(_position);
    _scaleNotifier = ValueNotifier(_scale);
  }

  @override
  void didUpdateWidget(_DraggableTextOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item != widget.item) {
      _position = widget.item.position;
      _scale = widget.item.scale;
      _positionNotifier.value = _position;
      _scaleNotifier.value = _scale;
    }
  }

  @override
  void dispose() {
    _positionNotifier.dispose();
    _scaleNotifier.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStart = _scale;
    _panStart = _position;
    _focalPointStart = details.focalPoint; // Lưu điểm bắt đầu
    widget.onTap();
    // Pause video để tối ưu performance khi di chuyển
    _pauseVideoForGesture();
  }

  void _pauseVideoForGesture() {
    // Tìm parent state để pause video
    final context = this.context;
    final ancestor =
        context.findAncestorStateOfType<_AnimatedTextEditScreenState>();
    if (ancestor != null && ancestor._videoController != null) {
      if (ancestor._videoController!.value.isPlaying) {
        ancestor._isVideoPausedForGesture = true;
        ancestor._videoController!.pause();
      }
    }
  }

  void _resumeVideoForGesture() {
    // Tìm parent state để resume video
    final context = this.context;
    final ancestor =
        context.findAncestorStateOfType<_AnimatedTextEditScreenState>();
    if (ancestor != null && ancestor._videoController != null) {
      if (ancestor._isVideoPausedForGesture) {
        ancestor._isVideoPausedForGesture = false;
        ancestor._videoController!.play();
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_scaleStart == null || _panStart == null || _focalPointStart == null) {
      return;
    }

    // Xử lý Scale (2 ngón tay - pinch zoom)
    final scaleDelta = details.scale;
    final hasScaleChange = (scaleDelta - 1.0).abs() > 0.01;
    if (hasScaleChange) {
      _scale = (_scaleStart! * scaleDelta).clamp(0.5, 3.0);
    }

    // Xử lý Pan (di chuyển) - DÙNG focalPoint - focalPointStart như sticker tĩnh
    // Tính delta từ điểm bắt đầu, sau đó scale về canvas coordinates
    final focalPointDelta = details.focalPoint - _focalPointStart!;
    final canvasDelta = Offset(
      focalPointDelta.dx / widget.scaleRatio,
      focalPointDelta.dy / widget.scaleRatio,
    );
    _position = Offset(
      _panStart!.dx + canvasDelta.dx,
      _panStart!.dy + canvasDelta.dy,
    );

    // Clamp position để giữ text trong bounds (512x512 preview area)
    const textWidthEstimate = 200.0;
    const textHeightEstimate = 40.0;
    final minX = textWidthEstimate / 2;
    final maxX = 512 - textWidthEstimate / 2;
    final minY = textHeightEstimate / 2;
    final maxY = 512 - textHeightEstimate / 2;

    _position = Offset(
      _position.dx.clamp(minX, maxX),
      _position.dy.clamp(minY, maxY),
    );

    // CHỈ update ValueNotifier - KHÔNG gọi onTransform để tránh setState trong parent
    // Chỉ sync với parent khi kết thúc gesture (trong _handleScaleEnd)
    _positionNotifier.value = _position;
    _scaleNotifier.value = _scale;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _panStart = null;
    _focalPointStart = null;
    // Đảm bảo callback được gọi lần cuối
    widget.onTransform(_position, _scale);
    // Resume video sau khi kết thúc gesture
    _resumeVideoForGesture();
  }

  @override
  Widget build(BuildContext context) {
    // Cache text style để tránh rebuild style mỗi lần
    final textStyle = TextStyle(
      color: widget.item.textColor.withOpacity(widget.item.opacity),
      fontSize: widget.item.fontSize,
      fontFamily: widget.item.fontFamily,
      fontWeight: widget.item.fontWeight,
      shadows:
          widget.item.shadowColor != null && widget.item.shadowBlur > 0
              ? [
                Shadow(
                  color: widget.item.shadowColor!.withOpacity(
                    widget.item.opacity,
                  ),
                  offset: widget.item.shadowOffset,
                  blurRadius: widget.item.shadowBlur,
                ),
              ]
              : null,
      backgroundColor: widget.item.backgroundColor,
    );

    // Tính toán position để center text
    const textWidthEstimate = 200.0;
    const textHeightEstimate = 40.0;

    // Positioned phải là direct child của Stack, nên dùng ValueListenableBuilder bên trong
    return ValueListenableBuilder<Offset>(
      valueListenable: _positionNotifier,
      builder: (context, position, _) {
        final displayPosition = Offset(
          position.dx - textWidthEstimate / 2,
          position.dy - textHeightEstimate / 2,
        );
        return Positioned(
          left: displayPosition.dx,
          top: displayPosition.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onScaleEnd: _handleScaleEnd,
            child: RepaintBoundary(
              child: ValueListenableBuilder<double>(
                valueListenable: _scaleNotifier,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        widget.item.backgroundColor ??
                        widget.item.textColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          widget.isSelected ? Colors.white : Colors.transparent,
                      width: widget.isSelected ? 2 : 0,
                    ),
                  ),
                  child: Text(
                    widget.item.text.isEmpty ? 'Text' : widget.item.text,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Bottom toolbar với tabs - giống sticker tĩnh
class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({
    required this.tab,
    required this.keyboardActive,
    required this.textSelected,
    required this.onTabChanged,
    required this.onKeyboardPressed,
    required this.onAddText,
    this.onDeleteText,
  });

  final AnimatedTextEditorTab tab;
  final bool keyboardActive;
  final bool textSelected;
  final ValueChanged<AnimatedTextEditorTab> onTabChanged;
  final VoidCallback onKeyboardPressed;
  final VoidCallback onAddText;
  final VoidCallback? onDeleteText;

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
              selected: tab == AnimatedTextEditorTab.text && textSelected,
              icon: Icons.title,
              onTap: () => onTabChanged(AnimatedTextEditorTab.text),
            ),
            _ToolIcon(
              selected: tab == AnimatedTextEditorTab.stroke,
              icon: Icons.border_color,
              onTap: () => onTabChanged(AnimatedTextEditorTab.stroke),
            ),
            _ToolIcon(
              selected: tab == AnimatedTextEditorTab.shadow,
              icon: Icons.blur_on,
              onTap: () => onTabChanged(AnimatedTextEditorTab.shadow),
            ),
            _ToolIcon(
              selected: tab == AnimatedTextEditorTab.background,
              icon: Icons.chat_bubble_outline,
              onTap: () => onTabChanged(AnimatedTextEditorTab.background),
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

// Bottom panel với nội dung theo tab
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.tab,
    required this.selectedItem,
    required this.onItemChanged,
    required this.fonts,
    required this.palette,
  });

  final AnimatedTextEditorTab tab;
  final AnimatedTextItem? selectedItem;
  final ValueChanged<AnimatedTextItem> onItemChanged;
  final List<String> fonts;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    if (selectedItem == null) {
      return const SizedBox.shrink();
    }

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
          AnimatedTextEditorTab.text => _TextTab(
            item: selectedItem!,
            onItemChanged: onItemChanged,
            fonts: fonts,
            palette: palette,
          ),
          AnimatedTextEditorTab.stroke => _EffectsTab(
            item: selectedItem!,
            onItemChanged: onItemChanged,
            palette: palette,
            isShadow: false,
          ),
          AnimatedTextEditorTab.shadow => _EffectsTab(
            item: selectedItem!,
            onItemChanged: onItemChanged,
            palette: palette,
            isShadow: true,
          ),
          AnimatedTextEditorTab.background => _BackgroundTab(
            item: selectedItem!,
            onItemChanged: onItemChanged,
            palette: palette,
          ),
        },
      ),
    );
  }
}

// Text tab - font selection và text color
class _TextTab extends StatelessWidget {
  const _TextTab({
    required this.item,
    required this.onItemChanged,
    required this.fonts,
    required this.palette,
  });

  final AnimatedTextItem item;
  final ValueChanged<AnimatedTextItem> onItemChanged;
  final List<String> fonts;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'text_color_label'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final c = palette[index];
              final selected = c.value == item.textColor.value;
              return GestureDetector(
                onTap: () => onItemChanged(item.copyWith(textColor: c)),
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
        Text(
          'font_label'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
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
              final selected = f == item.fontFamily;
              return InkWell(
                onTap: () => onItemChanged(item.copyWith(fontFamily: f)),
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

// Effects tab - stroke hoặc shadow
class _EffectsTab extends StatelessWidget {
  const _EffectsTab({
    required this.item,
    required this.onItemChanged,
    required this.palette,
    required this.isShadow,
  });

  final AnimatedTextItem item;
  final ValueChanged<AnimatedTextItem> onItemChanged;
  final List<Color> palette;
  final bool isShadow;

  @override
  Widget build(BuildContext context) {
    final currentColor = isShadow ? item.shadowColor : item.strokeColor;
    final sliderValue = isShadow ? item.shadowBlur : item.strokeWidth;
    final sliderMin = 0.0;
    final sliderMax = isShadow ? 10.0 : 10.0;
    final title = isShadow ? 'Bóng' : 'Đường viền';
    final sliderLabel = isShadow ? 'Độ mờ' : 'Độ dày';

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
              final selected =
                  currentColor != null && c.value == currentColor.value;
              return GestureDetector(
                onTap: () {
                  if (isShadow) {
                    onItemChanged(item.copyWith(shadowColor: c));
                  } else {
                    onItemChanged(item.copyWith(strokeColor: c));
                  }
                },
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
          onChanged: (value) {
            if (isShadow) {
              onItemChanged(item.copyWith(shadowBlur: value));
            } else {
              onItemChanged(item.copyWith(strokeWidth: value));
            }
          },
        ),
        const SizedBox(height: 6),
        Text('opacity_label'.tr, style: const TextStyle(color: Colors.black54)),
        Slider(
          value: item.opacity,
          min: 0,
          max: 1,
          onChanged: (value) {
            onItemChanged(item.copyWith(opacity: value));
          },
        ),
      ],
    );
  }
}

// Background tab
class _BackgroundTab extends StatelessWidget {
  const _BackgroundTab({
    required this.item,
    required this.onItemChanged,
    required this.palette,
  });

  final AnimatedTextItem item;
  final ValueChanged<AnimatedTextItem> onItemChanged;
  final List<Color> palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nền', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: palette.length + 1, // +1 for transparent
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Transparent option
                final isSelected = item.backgroundColor == null;
                return GestureDetector(
                  onTap:
                      () => onItemChanged(item.copyWith(backgroundColor: null)),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF00C979)
                                : const Color(0xFFDDDDDD),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child:
                        isSelected
                            ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF00C979),
                            )
                            : null,
                  ),
                );
              }
              final c = palette[index - 1];
              final selected =
                  item.backgroundColor != null &&
                  c.value == item.backgroundColor!.value;
              return GestureDetector(
                onTap: () => onItemChanged(item.copyWith(backgroundColor: c)),
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
        Text('opacity_label'.tr, style: const TextStyle(color: Colors.black54)),
        Slider(
          value: item.opacity,
          min: 0,
          max: 1,
          onChanged: (value) {
            onItemChanged(item.copyWith(opacity: value));
          },
        ),
      ],
    );
  }
}
