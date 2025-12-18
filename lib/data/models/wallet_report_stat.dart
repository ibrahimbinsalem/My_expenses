class WalletReportStat {
  final int walletId;
  final String name;
  final String currency;
  final double income;
  final double expense;

  const WalletReportStat({
    required this.walletId,
    required this.name,
    required this.currency,
    required this.income,
    required this.expense,
  });

  double get net => income - expense;

  factory WalletReportStat.fromMap(Map<String, dynamic> map) {
    return WalletReportStat(
      walletId: map['wallet_id'] as int,
      name: map['name'] as String,
      currency: map['currency'] as String? ?? '',
      income: (map['income'] as num).toDouble(),
      expense: (map['expense'] as num).toDouble(),
    );
  }
}
