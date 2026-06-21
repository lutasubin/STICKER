import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/view/my_sticker/widgets/user_pack_export_button.dart';
import 'package:sticker_app/view/my_sticker/widgets/user_pack_header.dart';
import 'package:sticker_app/view/my_sticker/widgets/user_pack_sticker_grid.dart';
import 'package:sticker_app/viewmodel/user_pack_detail_viewmodel.dart';

class UserPackDetailScreen extends StatelessWidget {
  const UserPackDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Get.put(UserPackDetailViewModel());

    return WillPopScope(
      onWillPop: () async {
        Get.back(result: viewModel.hasChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Get.back(result: viewModel.hasChanged);
            },
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: viewModel.renamePack,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.black),
              onPressed: viewModel.sharePack,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black),
              onPressed: viewModel.confirmDeletePack,
            ),
          ],
        ),
        body: Obx(() {
          // Đọc pack trực tiếp trong Obx builder
          final pack = viewModel.pack.value;

          if (pack == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final stickers = pack.stickerFileUris;

          return Column(
            children: [
              UserPackHeader(title: pack.title, stickerCount: stickers.length),
              UserPackStickerGrid(
                stickers: stickers,
                onAddSticker: viewModel.addSticker,
                onOpenSticker: viewModel.openStickerViewer,
              ),
              Obx(
                () => UserPackExportButton(
                  isSending: viewModel.isSending.value,
                  onPressed: viewModel.exportPack,
                  isInstalled: viewModel.isInstalled.value,
                  isChecking: viewModel.isChecking.value,
                  needsUpdate: viewModel.needsUpdate.value,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
