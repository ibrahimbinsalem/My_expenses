import 'dart:math';

import 'package:get/get.dart';

import '../models/transaction_model.dart';

/// Lightweight heuristic engine that mimics on-device AI insights.
class LocalInsightService {
  Future<List<String>> generateInsights(
    List<TransactionModel> transactions,
  ) async {
    if (transactions.isEmpty) {
      return ['ابدأ بتسجيل مصاريفك لتحصل على نصائح مخصصة.'.tr];
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
        'متوسط صرفك للعملية الواحدة هو @amount، جرّب تقليصه 10٪ هذا الأسبوع.'
            .trParams({'amount': average.toStringAsFixed(2)}),
      if (highest != null)
        'أعلى صرف كان @amount في @date. فكر هل كان ضروريًا؟'.trParams({
          'amount': highest.amount.toStringAsFixed(2),
          'date': '${highest.date.day}/${highest.date.month}',
        }),
    ];

    final random = Random();
    final tips = [
      'قسّم محفظتك إلى أكثر من حساب لتعرف مصدر الصرف.'.tr,
      'ضع هدف ادخار أسبوعي صغير، واستثمر التكرار.'.tr,
      'استخدم تسجيل الفواتير بالصور لتقليل النسيان.'.tr,
    ];
    insights.add(tips[random.nextInt(tips.length)]);
    return insights;
  }
}
