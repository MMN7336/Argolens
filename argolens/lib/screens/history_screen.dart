import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _vouchers = [];
  bool _isLoading = true;

  String get _baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final token = await user.getIdToken();
      final response = await http.get(
        Uri.parse('$_baseUrl/api/history-vouchers/all'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _vouchers = data['vouchers'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Fetch History Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadImage(String imageUrl) async {
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }

      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/history_voucher_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(response.bodyBytes);

        await Gal.putImage(file.path);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ဘောင်ချာပုံကို ဖုန်း Gallery ထဲသို့ သိမ်းဆည်းပြီးပါပြီ။'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Download Image Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ပုံသိမ်းဆည်းရာတွင် အမှားရှိသည်: $e')),
        );
      }
    }
  }

  Future<void> _deleteVoucher(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await user.getIdToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/history-vouchers/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _vouchers.removeWhere((v) => v['_id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('မှတ်တမ်းကို အောင်မြင်စွာ ဖျက်လိုက်ပါပြီ။'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ဖျက်ဆည်းရာတွင် အမှားရှိသည်: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF2E7D32);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF4F6F3),
      appBar: AppBar(
        title: const Text(
          "ဘောင်ချာမှတ်တမ်းများ (History)",
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 16),
        ),
        backgroundColor: primaryGreen,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _vouchers.isEmpty
          ? Center(
        child: Text(
          "သိမ်းဆည်းထားသော မှတ်တမ်း မရှိသေးပါ။",
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 15),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _vouchers.length,
        itemBuilder: (context, index) {
          final voucher = _vouchers[index];
          final voucherId = voucher['_id'];
          final imageUrl = voucher['imageUrl'] != null ? '$_baseUrl${voucher['imageUrl']}' : '';

          final itemName = voucher['itemName'] ?? 'စပါး';
          final netProfit = voucher['netProfit'] ?? 0;
          final quantity = voucher['quantity'] ?? voucher['baskets'] ?? 0;
          final totalRevenue = voucher['totalRevenue'] ?? 0;

          String formattedDate = '';
          if (voucher['date'] != null) {
            DateTime dt = DateTime.parse(voucher['date']);
            formattedDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: isDark ? 1 : 2,
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "$itemName: $quantity တင်း",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedDate,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "စုစုပေါင်းရငွေ:",
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "$totalRevenue ကျပ်",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                "အသားတင်အမြတ်:",
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "$netProfit ကျပ်",
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: netProfit >= 0
                                      ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                      : Colors.redAccent,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(10),
                              child: Stack(
                                children: [
                                  Center(
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      boundaryMargin: const EdgeInsets.all(20),
                                      minScale: 0.5,
                                      maxScale: 4,
                                      child: Image.network(imageUrl),
                                    ),
                                  ),
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Image.network(
                          imageUrl,
                          height: 420,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              height: 300,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey,
                              child: const Center(child: Text("ပုံကို ဖွင့်၍မရပါ။", style: TextStyle(color: Colors.white))),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (imageUrl.isNotEmpty)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange.shade400,
                            side: BorderSide(color: Colors.orange.shade400),
                          ),
                          onPressed: () => _downloadImage(imageUrl),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text("ဖုန်းထဲသိမ်း"),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                              title: Text("သတိပေးချက်", style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                              content: Text("ဤမှတ်တမ်းကို ဖျက်ရန် သေချာပါသလား?", style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("မလုပ်တော့ပါ"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _deleteVoucher(voucherId);
                                  },
                                  child: const Text("ဖျက်မည်", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text("ဖျက်ရန်"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}