import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:argolens/providers/language_provider.dart';

class AnalyzeDiseaseScreen extends StatefulWidget {
  final File imageFile;

  const AnalyzeDiseaseScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<AnalyzeDiseaseScreen> createState() => _AnalyzeDiseaseScreenState();
}

class _AnalyzeDiseaseScreenState extends State<AnalyzeDiseaseScreen> {
  bool _isLoading = false;
  String? _diagnosisResult;
  String? _treatmentRecommendation;
  Interpreter? _interpreter;
  List<String> _labels = [];
  late File _currentImageFile;

  @override
  void initState() {
    super.initState();
    _currentImageFile = widget.imageFile;
    _loadModelAndalyze();
  }

  // 📌 ရောဂါအလိုက် ကုသရန်နည်းလမ်းများနှင့် ဆေးဝါးများ
  String _getTreatmentForDisease(String diseaseName, bool isMyanmar) {
    switch (diseaseName.toLowerCase().trim()) {
      case 'bacterial_leaf_blight':
      case 'bacterial leaf blight':
        return isMyanmar
            ? "🌱 **ဘက်တီးရီးယား ရွက်ခြောက်ရောဂါ (Bacterial Leaf Blight)**\n\n"
            "• **အကြောင်းရင်း:** Xanthomonas oryzae ဘက်တီးရီးယားကြောင့်ဖြစ်ပြီး နိုက်ထရိုဂျင်ဓာတ်မြေဩဇာ အလွန်အကျွံသုံးခြင်းနှင့် မိုးလေပြင်းထန်၍ ဒဏ်ရာရခြင်းမှ ကူးစက်သည်။\n"
            "• **ကာကွယ်ကုသရန်:** ယူရီးယားမြေဩဇာကျွေးခြင်းကို လျှော့ချပါ။ ဖော့စရပ်နှင့် ပိုတက်စီယမ်ကို မျှတစွာထည့်ပါ။ ရေသွင်းရေထုတ် မှန်ကန်စေရန် လုပ်ဆောင်ပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Copper Hydroxide (သို့မဟုတ်) Streptomycin sulfate + Tetracycline hydrochloride ပါဝင်သော ဘက်တီးရီးယား ပိုးသတ်ဆေးများကို ညွှန်ကြားချက်အတိုင်း ပက်ဖြန်းပါ။"
            : "🌱 **Bacterial Leaf Blight**\n\n"
            "• **Cause:** Caused by Xanthomonas oryzae bacteria, often triggered by excessive nitrogen fertilizer and storm injuries.\n"
            "• **Prevention & Treatment:** Reduce urea fertilizer, balance phosphorus and potassium, and manage proper water irrigation/drainage.\n"
            "• **Recommended Chemicals:** Spray bactericides containing Copper Hydroxide or Streptomycin sulfate + Tetracycline hydrochloride.";

      case 'bacterial_leaf_streak':
        return isMyanmar
            ? "🌱 **ဘက်တီးရီးယား ရွက်ကြောစိမ်းရောဂါ (Bacterial Leaf Streak)**\n\n"
            "• **အကြောင်းရင်း:** ဘက်တီးရီးယားပိုးကြောင့် အရွက်ကြောများကြားတွင် ရေစိမ့်ကဲ့သို့ အစင်းကြောင်းများဖြစ်ပေါ်ပြီး အရွက်ဝါလာသည်။\n"
            "• **ကာကွယ်ကုသရန်:** ပိုတက်စီယမ်မြေဩဇာကို မျှတစွာသုံးပါ။ ရေအလွန်အကျွံတင်ခြင်းကို ရှောင်ရှားပါ။ အပင်ကျပ်လွန်းပါက လေဝင်လေထွက်လုပ်ပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Copper based bactericides (ဥပမာ - Copper Oxychloride) သို့မဟုတ် Validamycin ကို အသုံးပြုပါ။"
            : "🌱 **Bacterial Leaf Streak**\n\n"
            "• **Cause:** Bacterial infection causing water-soaked streaks between leaf veins.\n"
            "• **Prevention & Treatment:** Use balanced potassium fertilizers and avoid excessive flooding.\n"
            "• **Recommended Chemicals:** Use copper-based bactericides (e.g., Copper Oxychloride) or Validamycin.";

      case 'bacterial_panicle_blight':
        return isMyanmar
            ? "🌱 **နှံစပ်ဘက်တီးရီးယားပုပ်ရောဂါ (Bacterial Panicle Blight)**\n\n"
            "• **အကြောင်းရင်း:** စပါးနှံထွက်ချိန်နှင့် ပန်းပွင့်ချိန်တွင် အပူချိန်နှင့် စိုထိုင်းဆ မြင့်မားပါက ဖြစ်ပွားသည်။\n"
            "• **ကာကွယ်ကုသရန်:** နိုက်ထရိုဂျင်မြေဩဇာ အလွန်အကျွံသုံးခြင်းကို ရှောင်ကြဉ်ပါ။ ဆားငန်ဓာတ်နှင့် ရေကြီးရေလျှံမှုကို ကာကွယ်ပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Oxolinic acid ပါဝင်သော ဘက်တီးရီးယား ပိုးသတ်ဆေးများနှင့် ပိုတက်ရှ်ဓာတ်မြေဩဇာ ပက်ဖြန်းပေးပါ။"
            : "🌱 **Bacterial Panicle Blight**\n\n"
            "• **Cause:** Occurs during heading and flowering stages under high temperature and humidity.\n"
            "• **Prevention & Treatment:** Avoid excessive nitrogen application and manage field drainage.\n"
            "• **Recommended Chemicals:** Use bactericides containing Oxolinic acid and apply foliar potassium.";

      case 'blast':
      case 'leaf blast':
        return isMyanmar
            ? "🌱 **ရွက်ပြောက် ရောဂါ (Blast)**\n\n"
            "• **အကြောင်းရင်း:** Pyricularia oryzae မှိုကြောင့်ဖြစ်ပြီး စိုထိုင်းဆများခြင်းနှင့် မိုးစဲ၍ တိမ်ထူထပ်သော ရာသီဥတုတွင် အဖြစ်များသည်။\n"
            "• **ကာကွယ်ကုသရန်:** နိုက်ထရိုဂျင်မြေဩဇာကို အပိုင်းခွဲ၍ကျွေးပါ။ စပါးခင်းအတွင်း ရေအေးအမြဲမရှိစေဘဲ လေဝင်လေထွက်ကောင်းအောင် ထိန်းပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Tricyclazole, Isoprothiolane (သို့မဟုတ်) Kasugamycin ပါဝင်သော မှိုသတ်ဆေးများကို အသုံးပြုပါ။"
            : "🌱 **Leaf Blast**\n\n"
            "• **Cause:** Caused by Pyricularia oryzae fungus, favored by high humidity and cloudy weather.\n"
            "• **Prevention & Treatment:** Split nitrogen fertilizer applications. Ensure good aeration.\n"
            "• **Recommended Chemicals:** Use fungicides containing Tricyclazole, Isoprothiolane, or Kasugamycin.";

      case 'brown_spot':
      case 'brown spot':
        return isMyanmar
            ? "🌱 **ညိုစက်ရောဂါ (Brown Spot)**\n\n"
            "• **အကြောင်းရင်း:** Bipolaris oryzae မှိုကြောင့်ဖြစ်ပြီး မြေဆီလွှာတွင် အာဟာရဓာတ် (ပိုတက်စီယမ်နှင့် ရေ) ချို့တဲ့ခြင်းကြောင့် ဖြစ်ပွားသည်။\n"
            "• **ကာကွယ်ကုသရန်:** ပိုတက်စီယမ်နှင့် ဖော့စရပ်မြေဩဇာကို လုံလောက်စွာကျွေးပါ။ မစိုက်ပျိုးမီ မျိုးစေ့ကို မှိုသတ်ဆေးဖြင့် ဆေးလူး (Seed Treatment) ပြုလုပ်ပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Propiconazole, Edifenphos (သို့မဟုတ်) Mancozeb ပါဝင်သော မှိုသတ်ဆေးများကို အသုံးပြုပါ။"
            : "🌱 **Brown Spot**\n\n"
            "• **Cause:** Caused by Bipolaris oryzae; linked to nutrient deficiencies and water stress.\n"
            "• **Prevention & Treatment:** Apply adequate potassium and phosphorus. Treat seeds before planting.\n"
            "• **Recommended Chemicals:** Use fungicides containing Propiconazole, Edifenphos, or Mancozeb.";

      case 'dead_heart':
        return isMyanmar
            ? "🐛 **စပါးပင်သေ နှလုံးခြောက်ရောဂါ (Dead Heart)**\n\n"
            "• **အကြောင်းရင်း:** ပင်စည်ထိုးပိုး (Stem Borer) သန်ကောင်/ပိုးကောင်များကြောင့် အပင်ထိပ်ဖူး ခြောက်သွေ့သေဆုံးခြင်း ဖြစ်သည်။\n"
            "• **ကာကွယ်ကုသရန်:** ပိုးကျနေသော အပင်ပေါက်များကို နှုတ်ပယ်ပါ။ မီးပုံရှို့ခြင်း သို့မဟုတ် မြေမြှုပ်ခြင်းပြုလုပ်ပါ။ အလင်းဖမ်းစက်များ သုံးပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Cartap hydrochloride, Chlorpyrifos (သို့မဟုတ်) Fipronil ပါဝင်သော ပိုးသတ်ဆေးများကို အသုံးပြုပါ။"
            : "🐛 **Dead Heart**\n\n"
            "• **Cause:** Caused by stem borer larvae resulting in dead central shoots.\n"
            "• **Prevention & Treatment:** Remove and destroy infected tillers. Use light traps.\n"
            "• **Recommended Chemicals:** Use insecticides containing Cartap hydrochloride, Chlorpyrifos, or Fipronil.";

      case 'downy_mildew':
        return isMyanmar
            ? "🌱 **အမွှေးပါမှိုရောဂါ (Downy Mildew)**\n\n"
            "• **အကြောင်းရင်း:** စိုထိုင်းဆများပြီး ရေဝပ်သောနေရာများတွင် မှိုတစ်မျိုးကြောင့် ဖြစ်ပွားသည်။\n"
            "• **ကာကွယ်ကုသရန်:** ရေထုတ်မြောင်းများကို သေချာလုပ်ဆောင်ပါ။ မျိုးစေ့ကို မှိုသတ်ဆေးဖြင့် လူးနယ်စိုက်ပျိုးပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Metalaxyl (သို့မဟုတ်) Dimethomorph ပါဝင်သော မှိုသတ်ဆေးများကို အသုံးပြုပါ။"
            : "🌱 **Downy Mildew**\n\n"
            "• **Cause:** Fungal disease thriving in high humidity and poorly drained soils.\n"
            "• **Prevention & Treatment:** Ensure good drainage and treat seeds with fungicide.\n"
            "• **Recommended Chemicals:** Use fungicides containing Metalaxyl or Dimethomorph.";

      case 'hispa':
      case 'rice hispa':
        return isMyanmar
            ? "🐛 **စပါးလိပ်ပိုး / အရွက်စားပိုး (Rice Hispa)**\n\n"
            "• **အကြောင်းရင်း:** ပိုးကောင်ငယ်များက စပါးရွက်စိမ်းများကို ခြစ်စားခြင်းကြောင့် အရွက်များတွင် ဖြူရော်သောလိုင်းများ ဖြစ်ပေါ်စေသည်။\n"
            "• **ကာကွယ်ကုသရန်:** ပိုးကျနေသော အရွက်ဖျားများကို ညှပ်ထုတ်ပါ။ ပိုးဥများနှင့် ပိုးကောင်များကို ဖယ်ရှားပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Cypermethrin, Chlorpyrifos (သို့မဟုတ်) Lambda-cyhalothrin ပါဝင်သော ပိုးသတ်ဆေးများကို အသုံးပြုပါ။"
            : "🐛 **Rice Hispa**\n\n"
            "• **Cause:** Insect pests scrape green tissues of rice leaves, creating whitish streaks.\n"
            "• **Prevention & Treatment:** Clip infected leaf tips and manually remove pests.\n"
            "• **Recommended Chemicals:** Use insecticides containing Cypermethrin, Chlorpyrifos, or Lambda-cyhalothrin.";

      case 'normal':
      case 'healthy rice leaf':
        return isMyanmar
            ? "🌿 **ကျန်းမာသော စပါးရွက် (Normal / Healthy Rice Leaf)**\n\n"
            "• အပင်သည် ကျန်းမာကောင်းမွန်လျက်ရှိပါသည်။\n"
            "• **ထိန်းသိမ်းရန်:** ရောဂါများ မကျရောက်စေရန် ပုံမှန် ရေနှင့် မြေဩဇာ အုပ်ချုပ်မှုစနစ်အတိုင်း ဆက်လက် ထိန်းသိမ်းပါ။ ကာကွယ်ဆေး ပက်ဖြန်းရန် မလိုပါ။"
            : "🌿 **Normal / Healthy Rice Leaf**\n\n"
            "• The plant is in good and healthy condition.\n"
            "• **Maintenance:** Maintain standard water and fertilizer management practices to prevent future diseases.";

      case 'not_paddy':
        return isMyanmar
            ? "⚠️ **စပါးပင်မဟုတ်ပါ (Not Paddy / Invalid Image)**\n\n"
            "• **အကြောင်းရင်း:** တင်သွင်းလာသော ပုံသည် စပါးပင် သို့မဟုတ် စပါးရွက်နှင့် မသက်ဆိုင်ပါ။\n"
            "• **လုပ်ဆောင်ရန်:** ကျေးဇူးပြု၍ စပါးပင် သို့မဟုတ် စပါးရွက်ပုံကိုသာ ပြန်လည်ရိုက်ကူး၍ သို့မဟုတ် ရွေးချယ်၍ တင်ပြပေးပါ။"
            : "⚠️ **Not a Paddy Plant**\n\n"
            "• **Cause:** The uploaded image does not appear to be a rice or paddy plant.\n"
            "• **Action:** Please upload or capture a clear photo of a paddy plant or leaf for accurate analysis.";

      case 'tungro':
        return isMyanmar
            ? "🦠 **တန်ဂရိုရောဂါ (Tungro)**\n\n"
            "• **အကြောင်းရင်း:** ပိတုန်းစိမ်း (Green Leafhopper) များမှတစ်ဆင့် ဗိုင်းရပ်စ်ပိုး ကူးစက်ခြင်းကြောင့် ဖြစ်သည်။ အရွက်များ ဝါလာပြီး အပင်ပုသွားသည်။\n"
            "• **ကာကွယ်ကုသရန်:** ရောဂါကျနေသော အပင်များကို ဖယ်ရှားပါ။ ပိတုန်းစိမ်း ပိုးမွှားများကို အမြစ်ပြတ် ကြိုတင် ကာကွယ်ပါ။\n"
            "• **သုံးစွဲရန်ဆေးဝါးများ:** Imidacloprid, Thiamethoxam (သို့မဟုတ်) Dinotefuran ပါဝင်သော ပိုးသတ်ဆေးများကို အသုံးပြု၍ ဗိုင်းရပ်စ်သယ်ဆောင်သည့် ပိုးများကို နှိမ်နင်းပါ။"
            : "🦠 **Tungro**\n\n"
            "• **Cause:** Viral disease transmitted by Green Leafhoppers causing yellowing and stunting.\n"
            "• **Prevention & Treatment:** Remove infected plants and control vector leafhoppers.\n"
            "• **Recommended Chemicals:** Use systemic insecticides containing Imidacloprid, Thiamethoxam, or Dinotefuran.";

      default:
        return isMyanmar
            ? "ℹ️ အသေးစိတ် ကုသနည်း အချက်အလက် မရှိသေးပါ။ ကျေးဇူးပြု၍ ဒေသခံ စိုက်ပျိုးရေးပညာရှင်နှင့် တိုင်ပင်ပါ။"
            : "ℹ️ No detailed treatment information available. Please consult a local agricultural expert.";
    }
  }

  Future<void> _loadModelAndalyze() async {
    setState(() {
      _isLoading = true;
      _diagnosisResult = null;
      _treatmentRecommendation = null;
    });

    try {
      _interpreter ??= await Interpreter.fromAsset('assets/model/diseasemodel.tflite');

      if (_labels.isEmpty) {
        final labelData = await rootBundle.loadString('assets/model/name.txt');
        _labels = labelData
            .split('\n')
            .where((label) => label.trim().isNotEmpty)
            .map((label) {
          final parts = label.trim().split(RegExp(r'^\d+\s*'));
          return parts.length > 1 ? parts[1].trim() : label.trim();
        }).toList();
      }

      await _runModelOnImage(_currentImageFile);
    } catch (e) {
      setState(() {
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        _diagnosisResult = langProvider.isMyanmar
            ? "Model ဖွင့်ဖတ်ရာတွင် အမှားအယွင်းရှိသည်: $e"
            : "Error loading model: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _runModelOnImage(File imageFile) async {
    if (_interpreter == null || _labels.isEmpty) {
      setState(() {
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        _diagnosisResult = langProvider.isMyanmar
            ? "Model သို့မဟုတ် Labels ဖိုင် မတွေ့ပါ။"
            : "Model or Labels file not found.";
        _isLoading = false;
      });
      return;
    }

    try {
      final rawImage = img.decodeImage(imageFile.readAsBytesSync());
      if (rawImage == null) {
        setState(() {
          _isLoading = false;
          final langProvider = Provider.of<LanguageProvider>(context, listen: false);
          _diagnosisResult = langProvider.isMyanmar ? "ပုံကို ဖတ်ရှု၍ မရပါ။" : "Failed to decode image.";
        });
        return;
      }

      final resizedImage = img.copyResize(rawImage, width: 224, height: 224);
      var input = List.generate(
        1,
            (i) => List.generate(
          224,
              (j) => List.generate(
            224,
                (k) => List.filled(3, 0.0),
          ),
        ),
      );

      for (int y = 0; y < 224; y++) {
        for (int x = 0; x < 224; x++) {
          var pixel = resizedImage.getPixel(x, y);
          input[0][y][x][0] = pixel.r / 255.0;
          input[0][y][x][1] = pixel.g / 255.0;
          input[0][y][x][2] = pixel.b / 255.0;
        }
      }

      var output = List.generate(1, (i) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);

      var recognitions = output[0];
      double highestProb = 0.0;
      int highestIndex = 0;

      for (int i = 0; i < recognitions.length; i++) {
        if (recognitions[i] > highestProb) {
          highestProb = recognitions[i];
          highestIndex = i;
        }
      }

      if (!mounted) return;

      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final isMyanmar = langProvider.isMyanmar;

      setState(() {
        String diseaseName = _labels[highestIndex];
        String confidence = (highestProb * 100).toStringAsFixed(2);

        _diagnosisResult = isMyanmar
            ? "ရောဂါအမျိုးအစား: $diseaseName\nသေချာနှုန်း (Confidence): $confidence%"
            : "Disease: $diseaseName\nConfidence: $confidence%";

        _treatmentRecommendation = _getTreatmentForDisease(diseaseName, isMyanmar);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      setState(() {
        _diagnosisResult = langProvider.isMyanmar
            ? "ခွဲခြမ်းစိတ်ဖြာမှု အမှားအယွင်း: $e"
            : "Analysis error: $e";
        _isLoading = false;
      });
    }
  }

  // 📌 ဓာတ်ပုံအသစ်ရွေးချယ်ရန် (ကင်မရာကို အပေါ်၊ ဂလဲရီကို အောက်ဘက်သို့ စီစဉ်ထားသည်)
  Future<void> _pickNewImage() async {
    final ImagePicker picker = ImagePicker();

    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final langProvider = Provider.of<LanguageProvider>(context, listen: false);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Wrap(
              children: [
                // 📌 ကင်မရာဖြင့် အသစ်ရိုက်မည် (အပေါ်တွင် ရှိမည်)
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green, size: 26),
                  title: Text(
                    langProvider.isMyanmar ? "ကင်မရာဖြင့် အသစ်ရိုက်မည်" : "Take a New Photo",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                const Divider(height: 1),
                // 📌 ဖုန်းထဲမှ ပုံရွေးမည် (အောက်တွင် ရှိမည်)
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green, size: 26),
                  title: Text(
                    langProvider.isMyanmar ? "ဖုန်းထဲမှ ပုံရွေးမည်" : "Pick from Gallery",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice != null) {
      final XFile? pickedFile = await picker.pickImage(source: choice);
      if (pickedFile != null) {
        setState(() {
          _currentImageFile = File(pickedFile.path);
        });
        _loadModelAndalyze();
      }
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = langProvider.isMyanmar;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          isMyanmar ? "အပင်ရောဂါ စစ်ဆေးခြင်း" : "Analyze Plant Disease",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Image.file(
                              _currentImageFile,
                              fit: BoxFit.cover,
                              height: 240,
                              width: double.infinity,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(color: Colors.green),
                            const SizedBox(height: 16),
                            Text(
                              isMyanmar ? "စပါးရွက်ရောဂါကို စစ်ဆေးနေပါပြီ..." : "Analyzing plant disease...",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    if (_diagnosisResult != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.green.shade100, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.analytics_rounded, color: Colors.green, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isMyanmar ? "စစ်ဆေးတွေ့ရှိချက်" : "Diagnosis Result",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Colors.grey),
                            ),
                            Text(
                              _diagnosisResult!,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    if (_treatmentRecommendation != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.amber.shade200, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.medical_services_rounded, color: Colors.orange, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isMyanmar ? "ကုသရန် နည်းလမ်းနှင့် ဆေးဝါးများ" : "Treatment & Remedies",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1, color: Colors.grey),
                            ),
                            Text(
                              _treatmentRecommendation!,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(
                      isMyanmar ? "ထွက်မည်" : "Back",
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _pickNewImage,
                    child: Text(
                      isMyanmar ? "ထပ်မံ စစ်ဆေးမည်" : "Re-analyze",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}