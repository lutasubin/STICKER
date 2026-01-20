import 'package:flutter/material.dart';

/// Tỷ lệ kích thước sticker so với canvas (30%)
const double _stickerSizeRatio = 0.3;

/// Model đại diện cho một sticker layer
class StickerLayer {
  StickerLayer({
    required this.id,
    required this.imagePath,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,
  });

  final String id;
  final String imagePath;
  Offset position;
  double scale;
  double rotation;

  /// Tạo copy với các giá trị mới
  StickerLayer copyWith({Offset? position, double? scale, double? rotation}) {
    return StickerLayer(
      id: id,
      imagePath: imagePath,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
    );
  }
}

/// Widget hiển thị một sticker layer có thể transform
class TransformableStickerLayer extends StatefulWidget {
  const TransformableStickerLayer({
    super.key,
    required this.sticker,
    required this.canvasSize,
    required this.displayScale,
    required this.isSelected,
    required this.isEditable,
    required this.onTransform,
    required this.onDelete,
    required this.onTap,
  });

  final StickerLayer sticker;
  final double canvasSize;
  final double displayScale; // Tỷ lệ scale từ canvas sang display
  final bool isSelected;
  final bool isEditable; // Cho phép chỉnh sửa hay không
  final Function(StickerLayer) onTransform;
  final Function(String id) onDelete;
  final Function(String id) onTap;

  @override
  State<TransformableStickerLayer> createState() =>
      _TransformableStickerLayerState();
}

class _TransformableStickerLayerState extends State<TransformableStickerLayer> {
  late Offset _position;
  late double _scale;
  late double _rotation;
  Offset? _panStart;
  Offset? _focalPointStart;
  double? _scaleStart;
  double? _rotationStart;

  @override
  void initState() {
    super.initState();
    _position = widget.sticker.position;
    _scale = widget.sticker.scale;
    _rotation = widget.sticker.rotation;
  }

  @override
  void didUpdateWidget(TransformableStickerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sticker != widget.sticker) {
      _position = widget.sticker.position;
      _scale = widget.sticker.scale;
      _rotation = widget.sticker.rotation;
    }
  }

  // Scale handlers - xử lý cả pan (1 ngón) và scale (2 ngón)
  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStart = _scale;
    _rotationStart = _rotation;
    _panStart = _position;
    _focalPointStart = details.focalPoint;
    widget.onTap(widget.sticker.id);
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_scaleStart == null || _panStart == null || _focalPointStart == null) {
      return;
    }

    setState(() {
      final scaleDelta = details.scale;
      final hasScaleChange = (scaleDelta - 1.0).abs() > 0.01;

      // Xử lý Scale (2 ngón tay - pinch zoom)
      if (hasScaleChange) {
        // Scale từ center - position (center) không thay đổi, chỉ scale thay đổi
        _scale = (_scaleStart! * scaleDelta).clamp(0.3, 3.0);
      }

      // Xử lý Pan (di chuyển) - luôn xử lý để hỗ trợ vừa scale vừa pan
      // Convert từ display coordinates sang canvas coordinates
      final focalPointDelta = details.focalPoint - _focalPointStart!;
      final canvasDelta = Offset(
        focalPointDelta.dx / widget.displayScale,
        focalPointDelta.dy / widget.displayScale,
      );
      // Cập nhật position (center) khi pan
      _position = Offset(
        _panStart!.dx + canvasDelta.dx,
        _panStart!.dy + canvasDelta.dy,
      );

      // Rotation - chỉ áp dụng khi có rotation đáng kể
      if (details.rotation.abs() > 0.01) {
        _rotation = _rotationStart! + details.rotation;
      }

      // Giới hạn position trong canvas (position là center)
      _clampPosition();
    });

    widget.onTransform(
      widget.sticker.copyWith(
        position: _position,
        scale: _scale,
        rotation: _rotation,
      ),
    );
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _rotationStart = null;
    _panStart = null;
    _focalPointStart = null;
  }

  // Helper method để giới hạn position trong canvas
  // Position là CENTER của sticker, cần đảm bảo sticker không bị cắt ra ngoài canvas
  void _clampPosition() {
    final stickerSize = widget.canvasSize * _scale * _stickerSizeRatio;
    final halfSticker = stickerSize / 2;

    // Tính toán bounds chính xác:
    // - Min: sticker phải nằm trong canvas, nên center không được nhỏ hơn halfSticker
    // - Max: sticker phải nằm trong canvas, nên center không được lớn hơn canvasSize - halfSticker
    final minX = halfSticker;
    final maxX = widget.canvasSize - halfSticker;
    final minY = halfSticker;
    final maxY = widget.canvasSize - halfSticker;

    // Clamp với bounds chính xác hơn
    _position = Offset(
      _position.dx.clamp(minX, maxX),
      _position.dy.clamp(minY, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Position được lưu trong canvas coordinates (512x512) - là CENTER của sticker
    // Cần scale lên display coordinates để hiển thị đúng
    final displayCenter = Offset(
      _position.dx * widget.displayScale,
      _position.dy * widget.displayScale,
    );

    // Kích thước gốc của sticker (trong canvas coordinates)
    final baseStickerSize = widget.canvasSize * _stickerSizeRatio;
    // Kích thước hiển thị (sau khi scale lên display)
    final displayBaseSize = baseStickerSize * widget.displayScale;
    // Kích thước cuối cùng (sau khi áp dụng scale của user)
    final finalDisplaySize = displayBaseSize * _scale;

    // Tính top-left từ center (để vẽ đúng vị trí)
    final displayTopLeft = Offset(
      displayCenter.dx - finalDisplaySize / 2,
      displayCenter.dy - finalDisplaySize / 2,
    );

    return Positioned(
      left: displayTopLeft.dx,
      top: displayTopLeft.dy,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(widget.sticker.id),
        onScaleStart: _handleScaleStart,
        onScaleUpdate: _handleScaleUpdate,
        onScaleEnd: _handleScaleEnd,
        child: SizedBox(
          width: finalDisplaySize,
          height: finalDisplaySize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Sticker image
              Transform.rotate(
                angle: _rotation,
                child: Container(
                  width: displayBaseSize,
                  height: displayBaseSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Transform.scale(
                    scale: _scale,
                    alignment: Alignment.center,
                    child: Image.asset(
                      widget.sticker.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error_outline),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Selection border và controls
              if (widget.isSelected && widget.isEditable) ...[
                // Border
                Transform.rotate(
                  angle: _rotation,
                  child: Container(
                    width: displayBaseSize,
                    height: displayBaseSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF00C979),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Transform.scale(
                      scale: _scale,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: displayBaseSize,
                        height: displayBaseSize,
                      ),
                    ),
                  ),
                ),

                // Delete button - dùng GestureDetector với onTapDown để response nhanh
                Positioned(
                  right: -12,
                  top: -12,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) {
                      // Gọi delete ngay khi tap down (không cần chờ tap up)
                      widget.onDelete(widget.sticker.id);
                    },
                    onTap: () {
                      // Backup: cũng gọi delete khi tap (để đảm bảo)
                      widget.onDelete(widget.sticker.id);
                    },
                    child: Container(
                      width: 32, // Tăng kích thước hit area để dễ bấm hơn
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget quản lý tất cả sticker layers trên canvas
class StickerLayersWidget extends StatelessWidget {
  const StickerLayersWidget({
    super.key,
    required this.layers,
    required this.canvasSize,
    required this.displayScale,
    required this.selectedLayerId,
    required this.onLayerTransform,
    required this.onLayerDelete,
    required this.onLayerTap,
    this.isEditable = true,
  });

  final List<StickerLayer> layers;
  final double canvasSize;
  final double displayScale;
  final String? selectedLayerId;
  final Function(StickerLayer) onLayerTransform;
  final Function(String id) onLayerDelete;
  final Function(String id) onLayerTap;
  final bool isEditable; // Cho phép chỉnh sửa hay không

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children:
          layers.map((layer) {
            return TransformableStickerLayer(
              key: ValueKey(layer.id),
              sticker: layer,
              canvasSize: canvasSize,
              displayScale: displayScale,
              isSelected: selectedLayerId == layer.id,
              isEditable: isEditable,
              onTransform: onLayerTransform,
              onDelete: onLayerDelete,
              onTap: onLayerTap,
            );
          }).toList(),
    );
  }
}
