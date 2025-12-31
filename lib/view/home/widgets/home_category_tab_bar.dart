import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/controller/home/home_controller.dart';
import 'package:sticker_app/model/sticker_pack.dart';

/// Thanh tab category ở trên cùng màn hình Home.
class HomeCategoryTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HomeCategoryTabBar({super.key, required this.controller});

  final HomeController controller;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children:
              controller.categoriesOrder.map((category) {
                final isSelected = controller.currentCategory == category;

                return GestureDetector(
                  onTap: () => controller.onCategorySelected(category),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color:
                                isSelected
                                    ? Colors.black
                                    : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 32 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C979),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}
