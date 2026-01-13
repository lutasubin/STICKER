import 'package:get/get.dart';
import 'package:sticker_app/view/home/home_screen.dart';
import 'package:sticker_app/view/home/sticker_pack_detail_screen.dart';
import 'package:sticker_app/view/lang/lang.dart';
import 'package:sticker_app/view/lang/lang1_screen.dart';
import 'package:sticker_app/view/onboarding/onboarding_screen.dart';
import 'package:sticker_app/view/setting/setting_screen.dart';
import 'package:sticker_app/view/splash/splash_screen.dart';
import 'package:sticker_app/view/create_sticker/select_image_screen.dart';
import 'package:sticker_app/view/create_sticker/crop_screen.dart';
import 'package:sticker_app/view/create_sticker/select_video_screen.dart';
import 'package:sticker_app/view/create_sticker/crop_video_screen.dart';
import 'package:sticker_app/view/edit_sticker/edit_sticker_screen.dart';
import 'package:sticker_app/view/edit_sticker/sticker_picker_screen.dart';
import 'package:sticker_app/view/my_sticker/my_sticker_screen.dart';
import 'package:sticker_app/view/my_sticker/user_pack_detail_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const langFirst = '/langFirst';
  static const home = '/home';
  static const mySticker = '/mySticker';
  static const userPackDetail = '/userPackDetail';
  static const setting = '/setting';
  static const lang = '/lang';
  static const welcome = '/welcome';
  static const onboard = '/onboard';
  static const stickerPackDetail = '/stickerPackDetail';
  static const createStickerSelectImage = '/createStickerSelectImage';
  static const createStickerCrop = '/createStickerCrop';
  static const createAnimatedSelectVideo = '/createAnimatedSelectVideo';
  static const createAnimatedCrop = '/createAnimatedCrop';
  static const editSticker = '/editSticker';
  static const stickerPicker = '/stickerPicker';

  static final routes = [
    GetPage(
      name: splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: langFirst,
      page: () => const LangScreen1(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: onboard,
      page: () => const OnboardingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    // GetPage(
    //   name: welcome,
    //   page: () => const WelcomeScreen(),
    //   transition: Transition.fadeIn,
    //   transitionDuration: const Duration(milliseconds: 500),
    // ),
    GetPage(
      name: home,
      page: () => const HomeScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: mySticker,
      page: () => const MyStickerScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: userPackDetail,
      page: () => const UserPackDetailScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: stickerPackDetail,
      page: () => const StickerPackDetailScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: createStickerSelectImage,
      page: () => const SelectImageScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: createStickerCrop,
      page: () => const CropScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: createAnimatedSelectVideo,
      page: () => const SelectVideoScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: createAnimatedCrop,
      page: () => const CropVideoScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: editSticker,
      page: () => const EditStickerScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: stickerPicker,
      page: () => const StickerPickerScreen(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),

    GetPage(
      name: setting,
      page: () => const SettingScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
    GetPage(
      name: lang,
      page: () => const LangScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),
  ];
}
