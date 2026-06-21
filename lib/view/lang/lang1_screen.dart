import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/core/constants/app_colors.dart';
import 'package:sticker_app/viewmodel/lang_viewmodel.dart';

class LangScreen1 extends StatelessWidget {
  const LangScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(LangViewModel());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 150,
        leading: Center(
          child: Text(
            'language'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: viewModel.confirmAndNavigate,
            icon: const Icon(Icons.check, color: Colors.black, size: 24),
          ),
        ],
      ),
      body: Obx(() {
        // Đọc selectedLanguage trực tiếp trong Obx builder để GetX track được
        final selectedLang = viewModel.selectedLanguage.value;

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: viewModel.languages.length,
                itemBuilder: (context, index) {
                  final lang = viewModel.languages[index];
                  final isSelected = selectedLang == lang['name'];

                  return GestureDetector(
                    onTap: () => viewModel.selectLanguage(lang['name']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : Colors.grey.withOpacity(0.08),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lang['name']!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
