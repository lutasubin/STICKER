import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LangScreen extends StatefulWidget {
  const LangScreen({super.key});

  @override
  State<LangScreen> createState() => _LangScreenState();
}

class _LangScreenState extends State<LangScreen> {
  final GetStorage storage = GetStorage();
  String selectedLanguage = "English";

  final List<Map<String, String>> languages = [
    {"name": "English", "flag": "🇬🇧"},
    {"name": "Hindi", "flag": "🇮🇳"},
    {"name": "Arabic", "flag": "🇸🇦"},
    {"name": "Japanese", "flag": "🇯🇵"},
    {"name": "Brazil", "flag": "🇧🇷"},
    {"name": "Vietnamese", "flag": "🇻🇳"},
    {"name": "Singapore", "flag": "🇸🇬"},
    {"name": "France", "flag": "🇫🇷"},
    {"name": "Turkey", "flag": "🇹🇷"},
    {"name": "Indonesia", "flag": "🇮🇩"},
    {"name": "Korea", "flag": "🇰🇷"},
    {"name": "Russia", "flag": "🇷🇺"},
    {"name": "Germany", "flag": "🇩🇪"},
    {"name": "Ukraine", "flag": "🇺🇦"},
    {"name": "China", "flag": "🇨🇳"},
    {"name": "Spain", "flag": "🇪🇸"},
  ];

  final Map<String, Locale> languageLocales = {
    "English": const Locale('en', 'US'),
    "Hindi": const Locale('hi', 'IN'),
    "Arabic": const Locale('ar', 'SA'),
    "Japanese": const Locale('ja', 'JP'),
    "Brazil": const Locale('pt', 'BR'),
    "Vietnamese": const Locale('vi', 'VN'),
    "Singapore": const Locale('en', 'SG'),
    "France": const Locale('fr', 'FR'),
    "Turkey": const Locale('tr', 'TR'),
    "Indonesia": const Locale('id', 'ID'),
    "Korea": const Locale('ko', 'KR'),
    "Russia": const Locale('ru', 'RU'),
    "Germany": const Locale('de', 'DE'),
    "Ukraine": const Locale('uk', 'UA'),
    "China": const Locale('zh', 'CN'),
    "Spain": const Locale('es', 'ES'),
  };

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    String? savedLanguage = storage.read('selected_language');
    if (savedLanguage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selectedLanguage = savedLanguage;
        });
        if (languageLocales.containsKey(savedLanguage)) {
          Get.updateLocale(languageLocales[savedLanguage]!);
        }
      });
    }
  }

  void _saveLanguage(String language) {
    storage.write('selected_language', language);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        elevation: 0,
        leadingWidth: 150, // mở rộng vùng leading để text không bị cắt
        leading: Center(
          child: Text(
            'language'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(Icons.check, color: Colors.black, size: 24),
          ),
        ],
      ),
      body: Column(
        children: [
          // Grid View
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected = selectedLanguage == lang["name"];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedLanguage = lang["name"]!;
                    });
                    _saveLanguage(lang["name"]!);
                    if (languageLocales.containsKey(lang["name"])) {
                      Get.updateLocale(languageLocales[lang["name"]]!);
                    }
                  },
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
                                ? const Color(0xFF00C979)
                                : Colors.grey.withOpacity(0.08),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        Text(
                          lang["flag"]!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang["name"]!,
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
      ),
    );
  }
}
