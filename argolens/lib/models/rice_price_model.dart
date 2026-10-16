class RicePriceModel {
  final String id;
  final String name;
  final String marketValue;
  final String region; // 👈 Region Field အသစ် ထည့်သွင်းခြင်း

  RicePriceModel({
    required this.id,
    required this.name,
    required this.marketValue,
    required this.region, // 👈 Required ထည့်ရန်
  });

  factory RicePriceModel.fromJson(Map<String, dynamic> json) {
    return RicePriceModel(
      id: json['_id'] ?? json['id'] ?? '', // MongoDB ရဲ့ _id ကို ဖမ်းရန်
      name: json['name'] ?? '',
      marketValue: json['market_value']?.toString() ?? '0',
      region: json['region'] ?? '', // 👈 JSON မှ region ကို ဖမ်းရန်
    );
  }
}