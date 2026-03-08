import 'dart:convert';
import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/ngo_model.dart';

class NeedsProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Ngo> needs = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchNeeds() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final dynamic response = await _api.getNeeds();

      if (response is String) {
        print('RAW API RESPONSE (String): $response');
      } else {
        print('RAW API RESPONSE: $response');
      }

      dynamic data;
      if (response is String) {
        data = json.decode(response);
      } else {
        data = response;
      }

      final List<dynamic> results = (data is Map)
          ? (data['results'] ?? data['needs'] ?? [])
          : (data is List ? data : []);

      needs = results
          .map((item) => Ngo.fromJson(item as Map<String, dynamic>))
          .toList();

      print('✅ Loaded ${needs.length} NGOs');

      if (needs.isEmpty) {
        error = 'No NGOs found in response';
      }
    } catch (e, st) {
      error = 'Failed to fetch NGOs: $e';
      print('Needs fetch error: $e\n$st');
      needs = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
