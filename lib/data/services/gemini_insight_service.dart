import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_keys.dart';
import '../models/transaction_model.dart';

class GeminiInsightService {
  GeminiInsightService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<String>> generateInsights({
    required List<TransactionModel> transactions,
    required String username,
  }) async {
    if (ApiKeys.gemini.isEmpty) {
      throw Exception('Gemini API key is missing');
    }
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${ApiKeys.gemini}',
    );
    final prompt = _buildPrompt(transactions, username);
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          }
        ],
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Gemini request failed: ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return [];
    }
    final text = candidates.first['content']['parts'][0]['text'] as String? ?? '';
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  String _buildPrompt(List<TransactionModel> transactions, String username) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are an offline-first personal finance assistant. '
      'Analyze the following transactions for the user $username and provide actionable insights. '
      'Summaries should be in Arabic with concise bullet points.',
    );
    for (final txn in transactions) {
      buffer.writeln(
        '${txn.date.toIso8601String()} | ${txn.type.name} | '
        '${txn.amount.toStringAsFixed(2)} | ${txn.note ?? 'بدون ملاحظة'}',
      );
    }
    buffer.writeln(
      'Return the insights as short bullet sentences separated by newlines. '
      'Focus on spending patterns, savings opportunities, and warnings.',
    );
    return buffer.toString();
  }
}
