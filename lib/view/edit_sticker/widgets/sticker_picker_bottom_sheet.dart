import 'package:flutter/material.dart';
import 'package:sticker_app/service/sticker/sticker_edit_service.dart';

/// Bottom sheet để chọn sticker
class StickerPickerBottomSheet extends StatefulWidget {
  const StickerPickerBottomSheet({super.key, required this.onStickerSelected});

  final Function(String stickerPath) onStickerSelected;

  @override
  State<StickerPickerBottomSheet> createState() =>
      _StickerPickerBottomSheetState();
}

class _StickerPickerBottomSheetState extends State<StickerPickerBottomSheet> {
  final StickerEditService _service = StickerEditService();
  StickerCategory _selectedCategory = StickerCategory.glass;
  List<String> _stickers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  Future<void> _loadStickers() async {
    setState(() => _isLoading = true);
    final stickers = await _service.getStickersByCategory(_selectedCategory);
    if (mounted) {
      setState(() {
        _stickers = stickers;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(StickerCategory category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    _loadStickers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header với nút đóng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Chọn Sticker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Hàng danh mục (category icons)
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: StickerCategory.values.length,
              itemBuilder: (context, index) {
                final category = StickerCategory.values[index];
                final isSelected = _selectedCategory == category;
                return GestureDetector(
                  onTap: () => _onCategorySelected(category),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFF00C979).withOpacity(0.15)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF00C979)
                                : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          category.icon,
                          color:
                              isSelected
                                  ? const Color(0xFF00C979)
                                  : Colors.black54,
                          size: 28,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? const Color(0xFF00C979)
                                    : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Lưới sticker
          Flexible(
            child:
                _isLoading
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00C979),
                          ),
                        ),
                      ),
                    )
                    : _stickers.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Không có sticker nào',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: _stickers.length,
                      itemBuilder: (context, index) {
                        final stickerPath = _stickers[index];
                        return GestureDetector(
                          onTap: () {
                            widget.onStickerSelected(stickerPath);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                stickerPath,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),

          // Padding cho safe area
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
