import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sticker_app/controller/appbinding.dart';
import 'package:sticker_app/helper/translate/translate_service.dart';
import 'package:sticker_app/router/router.dart';


class StickerApp extends StatelessWidget {
  const StickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      initialBinding: AppBinding(),
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white
        ), // cùng màu scaffold ,
        scaffoldBackgroundColor: Colors.white,
      ),
      locale: TranslationService.getSavedLocale(),
      translations: TranslationService(),
      fallbackLocale: TranslationService.fallbackLocale,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr, // luôn LTR
          child: child!,
        );
      },
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.noTransition,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
    );
  }
}
