import 'dart:io';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:gal/gal.dart';
import '../providers/language_provider.dart';

class RiceVoucherScreen extends StatefulWidget {
  const RiceVoucherScreen({super.key});

  @override
  State<RiceVoucherScreen> createState() => _RiceVoucherScreenState();
}

class _RiceVoucherScreenState extends State<RiceVoucherScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _voucherKey = GlobalKey();

  // 📌 ပင်မ စပါးအချက်အလက် Controller များ
  final TextEditingController _itemNameController = TextEditingController(text: 'စပါး');
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // 📌 ဘေးထွက်ပစ္စည်းများ (ဖွဲ၊ ဆန်ကွဲ စသည်ဖြင့်) ထည့်ရန် Controller များ
  final TextEditingController _extraNameController = TextEditingController();
  final TextEditingController _extraAmountController = TextEditingController();
  final List<Map<String, dynamic>> _extraIncomes = [];

  // 📌 ကုန်ကျစရိတ် Controller များ
  final TextEditingController _expenseNameController = TextEditingController();
  final TextEditingController _expenseAmountController = TextEditingController();
  final List<Map<String, dynamic>> _expenses = [];

  bool _isGenerating = false;
  bool _isSavedToDb = false;
  double _fontScale = 1.0;

  @override
  void initState() {
    super.initState();
    _loadFontScale();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _extraNameController.dispose();
    _extraAmountController.dispose();
    _expenseNameController.dispose();
    _expenseAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontScale = prefs.getDouble('app_font_scale') ?? 1.0;
      });
    }
  }

  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';

  // 📌 ဘေးထွက်ပစ္စည်း (ဖွဲ၊ ဆန်ကွဲ) ထည့်ရန်
  void _addExtraIncome() {
    if (_extraNameController.text.isNotEmpty && _extraAmountController.text.isNotEmpty) {
      setState(() {
        _extraIncomes.add({
          'name': _extraNameController.text.trim(),
          'amount': double.tryParse(_extraAmountController.text) ?? 0.0,
        });
        _extraNameController.clear();
        _extraAmountController.clear();
        _isSavedToDb = false;
      });
    }
  }

  void _removeExtraIncome(int index) {
    setState(() {
      _extraIncomes.removeAt(index);
      _isSavedToDb = false;
    });
  }

  // 📌 ကုန်ကျစရိတ် ထည့်ရန်
  void _addExpense() {
    if (_expenseNameController.text.isNotEmpty && _expenseAmountController.text.isNotEmpty) {
      setState(() {
        _expenses.add({
          'name': _expenseNameController.text.trim(),
          'amount': double.tryParse(_expenseAmountController.text) ?? 0.0,
        });
        _expenseNameController.clear();
        _expenseAmountController.clear();
        _isSavedToDb = false;
      });
    }
  }

  void _removeExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
      _isSavedToDb = false;
    });
  }

  double get _totalQuantity => double.tryParse(_quantityController.text) ?? 0.0;
  double get _pricePerUnit => double.tryParse(_priceController.text) ?? 0.0;

  // 📌 ပင်မ စပါးရောင်းရငွေ
  double get _mainRevenue => _totalQuantity * _pricePerUnit;

  // 📌 ဘေးထွက်ပစ္စည်းများ ရောင်းရငွေ စုစုပေါင်း
  double get _totalExtraIncomes {
    double sum = 0;
    for (var item in _extraIncomes) {
      sum += (item['amount'] as double);
    }
    return sum;
  }

  // 📌 စုစုပေါင်း ဝင်ငွေ (စပါး + ဖွဲ + ဆန်ကွဲ)
  double get _totalRevenue => _mainRevenue + _totalExtraIncomes;

  double get _totalExpenses {
    double sum = 0;
    for (var exp in _expenses) {
      sum += (exp['amount'] as double);
    }
    return sum;
  }

  double get _netProfit => _totalRevenue - _totalExpenses;

  void _showVoucherBottomSheet(bool isMyanmar) {
    if (_extraNameController.text.isNotEmpty && _extraAmountController.text.isNotEmpty) {
      _addExtraIncome();
    }
    if (_expenseNameController.text.isNotEmpty && _expenseAmountController.text.isNotEmpty) {
      _addExpense();
    }

    if (!_formKey.currentState!.validate()) return;

    const Color primaryGreen = Color(0xFF2E7D32);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String displayItemName = _itemNameController.text.trim().isEmpty
        ? (isMyanmar ? "စပါး" : "Rice")
        : _itemNameController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    RepaintBoundary(
                      key: _voucherKey,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: primaryGreen.withOpacity(0.3), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                isMyanmar ? "🌾 စပါးနှင့် ဘေးထွက်ပစ္စည်း အရောင်းအဝယ် ဘောင်ချာ 🌾" : "🌾 Rice & By-products Trade Voucher 🌾",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                              ),
                            ),
                            const Divider(height: 20, thickness: 1.5),

                            // ပင်မ စပါး အချက်အလက်
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "ပစ္စည်းအမည်:" : "Item Name:", style: const TextStyle(color: Colors.black87))),
                                Text(displayItemName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "စပါးတင်းရေ:" : "Quantity (Baskets):", style: const TextStyle(color: Colors.black87))),
                                Text('${_totalQuantity.toStringAsFixed(0)} တင်း', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "တစ်တင်းပေါက်ဈေး:" : "Price per Basket:", style: const TextStyle(color: Colors.black87))),
                                Text('${_pricePerUnit.toStringAsFixed(0)} ${isMyanmar ? "ကျပ်" : "MMK"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "စပါးရောင်းရငွေ:" : "Main Revenue:", style: const TextStyle(color: Colors.black87))),
                                Text('${_mainRevenue.toStringAsFixed(0)} ${isMyanmar ? "ကျပ်" : "MMK"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),

                            // ဘေးထွက်ပစ္စည်းများ (ဖွဲ၊ ဆန်ကွဲ စသည်ဖြင့်)
                            if (_extraIncomes.isNotEmpty) ...[
                              const Divider(height: 15),
                              Text(isMyanmar ? "ဘေးထွက်ပစ္စည်း/အခြား ဝင်ငွေများ:" : "By-products / Extra Incomes:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                              ..._extraIncomes.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text("- ${item['name']}", style: const TextStyle(color: Colors.black87))),
                                    Text('${item['amount']} ${isMyanmar ? "ကျပ်" : "MMK"}', style: const TextStyle(color: Colors.black87)),
                                  ],
                                ),
                              )),
                            ],

                            const Divider(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "စုစုပေါင်း ဝင်ငွေ:" : "Total Revenue:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                                Text('${_totalRevenue.toStringAsFixed(0)} ${isMyanmar ? "ကျပ်" : "MMK"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                              ],
                            ),
                            const Divider(height: 15),

                            // ကုန်ကျစရိတ်များ
                            Text(isMyanmar ? "ကုန်ကျစရိတ်များအသေးစိတ်:" : "Expense Details:", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                            if (_expenses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                child: Text("- မရှိပါ။", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ),
                            ..._expenses.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text("- ${e['name']}", style: const TextStyle(color: Colors.black87))),
                                  Text('${e['amount']} ${isMyanmar ? "ကျပ်" : "MMK"}', style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                            )),
                            const Divider(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "စုစုပေါင်း ကုန်ကျစရိတ်:" : "Total Expenses:", style: const TextStyle(color: Colors.black87))),
                                Text('${_totalExpenses.toStringAsFixed(0)} ${isMyanmar ? "ကျပ်" : "MMK"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              ],
                            ),
                            const Divider(height: 20, thickness: 1.5),

                            // အသားတင် အမြတ်
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(isMyanmar ? "အသားတင် အမြတ်ငွေ (Net Profit):" : "Net Profit:", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87))),
                                Text('${_netProfit.toStringAsFixed(0)} ${isMyanmar ? "ကျပ်" : "MMK"}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _netProfit >= 0 ? Colors.green.shade800 : Colors.red)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // လုပ်ဆောင်ချက် ခလုတ်များ
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSavedToDb ? Colors.grey.shade600 : primaryGreen,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isGenerating ? null : () async {
                              await _saveToDatabase(isMyanmar: isMyanmar, itemName: displayItemName);
                              setModalState(() {});
                            },
                            icon: _isGenerating
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(_isSavedToDb ? Icons.check_circle : Icons.save, color: Colors.white, size: 18),
                            label: Text(
                              _isSavedToDb
                                  ? (isMyanmar ? "သိမ်းပြီးပါပြီ" : "Saved")
                                  : (isMyanmar ? "History သိမ်း" : "Save DB"),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade800,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isGenerating ? null : () async {
                              await _saveImageToDevice(isMyanmar: isMyanmar);
                              if (context.mounted) Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.download, color: Colors.white, size: 18),
                            label: Text(isMyanmar ? "ဖုန်းထဲသိမ်း" : "Save Image", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _isGenerating ? null : () async {
                              await _shareVoucherImage(isMyanmar: isMyanmar);
                              if (context.mounted) Navigator.pop(sheetContext);
                            },
                            icon: const Icon(Icons.share, color: Colors.white, size: 18),
                            label: Text(isMyanmar ? "မျှဝေမည်" : "Share", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveImageToDevice({required bool isMyanmar}) async {
    try {
      setState(() => _isGenerating = true);
      RenderRepaintBoundary boundary = _voucherKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/trade_voucher_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putImage(file.path);
      setState(() => _isGenerating = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isMyanmar ? 'ဘောင်ချာပုံကို ဖုန်း Gallery ထဲသို့ သိမ်းပြီးပါပြီ။' : 'Voucher saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _shareVoucherImage({required bool isMyanmar}) async {
    try {
      setState(() => _isGenerating = true);
      RenderRepaintBoundary boundary = _voucherKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/trade_voucher_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);
      setState(() => _isGenerating = false);

      await Share.shareXFiles([XFile(file.path)], text: 'Trade Voucher & Profit Statement');
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // 📌 Corrected API URL to match backend (`/api/history-vouchers/save`)
  Future<void> _saveToDatabase({required bool isMyanmar, required String itemName}) async {
    if (_isSavedToDb) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() => _isGenerating = true);
      RenderRepaintBoundary boundary = _voucherKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // ဖိုင်ပုံစံ Temporary သိမ်းမည်
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/trade_voucher_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(pngBytes);

      final token = await user.getIdToken();

      // 📌 မှန်ကန်သော Backend API Endpoint လမ်းကြောင်း (`/api/history-vouchers/save`) သို့ ချိတ်ဆက်ခြင်း
      var uri = Uri.parse('$_baseUrl/api/history-vouchers/save');
      var request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['itemName'] = itemName;
      request.fields['quantity'] = _totalQuantity.toString();
      request.fields['pricePerUnit'] = _pricePerUnit.toString();
      request.fields['extraIncomes'] = json.encode(_extraIncomes);
      request.fields['expenses'] = json.encode(_expenses);
      request.fields['totalRevenue'] = _totalRevenue.toString();
      request.fields['totalExpenses'] = _totalExpenses.toString();
      request.fields['netProfit'] = _netProfit.toString();
      request.fields['date'] = DateTime.now().toIso8601String();

      // ပုံဖိုင်ထည့်သွင်းခြင်း (Backend က upload.single('image') နဲ့ဖမ်းမည်)
      request.files.add(
        await http.MultipartFile.fromPath('image', file.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      setState(() => _isGenerating = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isSavedToDb = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMyanmar ? '✅ Database တွင် သိမ်းဆည်းပြီးပါပြီ။' : '✅ Saved to DB!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint("Server Error Response: ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isMyanmar ? 'သိမ်းဆည်း၍ မရပါ: ${response.body}' : 'Failed: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      debugPrint("Catch Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isMyanmar = languageProvider.isMyanmar;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_fontScale)),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F3),
        appBar: AppBar(
          title: Text(
            isMyanmar ? "စပါးနှင့် ဘေးထွက်ပစ္စည်း အမြတ်တွက်ချက်မှု" : "Rice & By-products Calculator",
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
          ),
          backgroundColor: primaryGreen,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. ပင်မ စပါး အချက်အလက် Card
                Card(
                  elevation: isDark ? 1 : 2,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyanmar ? "ပင်မ စပါး အရောင်းအဝယ်" : "Main Rice Trade",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.greenAccent : primaryGreen),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _itemNameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: isMyanmar ? 'ပစ္စည်းအမည်' : 'Item Name',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.shopping_bag, color: isDark ? Colors.greenAccent : primaryGreen),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: isMyanmar ? 'စပါးတင်းရေ (Quantity)' : 'Quantity in Baskets',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.grass, color: isDark ? Colors.greenAccent : primaryGreen),
                          ),
                          onChanged: (_) => setState(() => _isSavedToDb = false),
                          validator: (value) => value!.isEmpty ? (isMyanmar ? 'တင်းရေထည့်ရန် လိုအပ်သည်' : 'Required') : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: isMyanmar ? 'တစ်တင်း ပေါက်ဈေး (ကျပ်)' : 'Price per Basket (MMK)',
                            labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                            border: const OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money, color: isDark ? Colors.greenAccent : primaryGreen),
                          ),
                          onChanged: (_) => setState(() => _isSavedToDb = false),
                          validator: (value) => value!.isEmpty ? (isMyanmar ? 'ဈေးနှုန်းထည့်ရန် လိုအပ်သည်' : 'Required') : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. ဘေးထွက်ပစ္စည်းများ (ဖွဲ၊ ဆန်ကွဲ) Card
                Card(
                  elevation: isDark ? 1 : 2,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyanmar ? "စပါးပင်မှရရှိသော ကောက်ရိုး၊စပါးခွံများကိုရောင်းရ‌ငွေ(ဥပမာ- ဖွဲ၊ ဆန်ကွဲ)" : "Income from agricultural by-products",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.greenAccent : primaryGreen),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _extraNameController,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  labelText: isMyanmar ? 'ပစ္စည်းအမည် (ဥပမာ- ဖွဲ)' : 'Item Name',
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _extraAmountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  labelText: isMyanmar ? 'ရငွေ' : 'Amount',
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _addExtraIncome,
                              icon: Icon(Icons.add_circle, color: isDark ? Colors.greenAccent : primaryGreen, size: 36),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _extraIncomes.length,
                          itemBuilder: (context, index) {
                            final item = _extraIncomes[index];
                            return ListTile(
                              dense: true,
                              title: Text(item['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${item['amount']} ${isMyanmar ? "ကျပ်" : "MMK"}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () => _removeExtraIncome(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. ကုန်ကျစရိတ် Card
                Card(
                  elevation: isDark ? 1 : 2,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMyanmar ? "ကုန်ကျစရိတ်များ (Expenses)" : "Expenses",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.greenAccent : primaryGreen),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _expenseNameController,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  labelText: isMyanmar ? 'စရိတ်အမည် (ဥပမာ- ကြိတ်ခ)' : 'Expense Name',
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _expenseAmountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                decoration: InputDecoration(
                                  labelText: isMyanmar ? 'ငွေပမာဏ' : 'Amount',
                                  labelStyle: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _addExpense,
                              icon: Icon(Icons.add_circle, color: isDark ? Colors.greenAccent : primaryGreen, size: 36),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _expenses.length,
                          itemBuilder: (context, index) {
                            final exp = _expenses[index];
                            return ListTile(
                              dense: true,
                              title: Text(exp['name'], style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${exp['amount']} ${isMyanmar ? "ကျပ်" : "MMK"}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade300 : Colors.black87),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () => _removeExpense(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // တွက်ချက်မည် ခလုတ်
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showVoucherBottomSheet(isMyanmar),
                  icon: const Icon(Icons.calculate, color: Colors.white),
                  label: Text(
                    isMyanmar ? "ဘောင်ချာ တွက်ချက်မည်" : "Calculate Voucher",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}