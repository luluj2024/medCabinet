import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenfdaService {
  OpenfdaService._internal();
  static final OpenfdaService instance = OpenfdaService._internal();

  static const String _baseUrl = 'https://api.fda.gov/drug/label.json';

  Future<List<OpenFdaDrugLabel>> searchDrugLabel(String query, {int limit = 5}) async {
    final q = query.trim();

    if(q.isEmpty) return [];

    final search = 'openfda.brand_name: "$q" OR openfda.generic_name: "$q"';

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'search': search,
      'limit': '$limit',
    });

    final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
    );

    if(response.statusCode != 200) throw Exception('openFDA error: ${response.statusCode} ${response.reasonPhrase}');

    final jsonMap = json.decode(response.body) as Map<String, dynamic>;
    final results = (jsonMap['results'] as List<dynamic>?) ?? [];

    return results.map((e) => OpenFdaDrugLabel.fromJson(e as Map<String, dynamic>)).toList();

  }
}

class OpenFdaDrugLabel {
  final String? brandName;
  final String? genericName;
  final String? purpose;
  final String? warnings;

  OpenFdaDrugLabel({
    this.brandName,
    this.genericName,
    this.purpose,
    this.warnings,
  });

  factory OpenFdaDrugLabel.fromJson(Map<String, dynamic> json) {
    final openfda = (json['openfda'] as Map<String, dynamic>?) ?? {};

    String? firstString(dynamic v){
      if(v is List && v.isNotEmpty && v.first is String) return v.first.toString();
      if(v is String) return v;
      return null;
    }

    return OpenFdaDrugLabel(
      brandName: firstString(openfda['brand_name']),
      genericName: firstString(openfda['generic_name']),
      purpose: firstString(json['purpose']),
      warnings: firstString(json['warnings']),
    );
  }

}