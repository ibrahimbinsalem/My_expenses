import 'dart:math';

import '../models/transaction_model.dart';

/// Lightweight heuristic engine that mimics on-device AI insights.
class LocalInsightService {
  Future<List<String>> generateInsights(
    List<TransactionModel> transactions,
  ) async {
    if (transactions.isEmpty) {
      return ['ابدأ بتسجيل مصاريفك لتحصل على نصائح مخصصة.'];
    }

    final expenses = transactions.where(
      (txn) => txn.type == TransactionType.expense,
    );
    final average = expenses.isEmpty
        ? 0
        : expenses.map((e) => e.amount).reduce((a, b) => a + b) /
              expenses.length;
    final highest = expenses.fold<TransactionModel?>(null, (previous, txn) {
      if (previous == null) return txn;
      return txn.amount > previous.amount ? txn : previous;
    });

    final insights = <String>[
      if (average > 0)
        'متوسط صرفك للعملية الواحدة هو ${average.toStringAsFixed(2)}، جرّب تقليصه 10٪ هذا الأسبوع.',
      if (highest != null)
        'أعلى صرف كان ${highest.amount.toStringAsFixed(2)} في ${highest.date.day}/${highest.date.month}. فكر هل كان ضروريًا؟',
    ];

    final random = Random();
    const tips = [
      'قسّم محفظتك إلى أكثر من حساب لتعرف مصدر الصرف.',
      'ضع هدف ادخار أسبوعي صغير، واستثمر التكرار.',
      'استخدم تسجيل الفواتير بالصور لتقليل النسيان.',
    ];
    insights.add(tips[random.nextInt(tips.length)]);
    return insights;
  }
}
