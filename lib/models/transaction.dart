class Transaction {
  final int? id;
  final int tenantId;
  final double amountGiven;
  final int monthsCovered;
  final double remainingBalance;
  final String date;

  Transaction({
    this.id,
    required this.tenantId,
    required this.amountGiven,
    required this.monthsCovered,
    required this.remainingBalance,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'amountGiven': amountGiven,
      'monthsCovered': monthsCovered,
      'remainingBalance': remainingBalance,
      'date': date,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      tenantId: map['tenantId'],
      amountGiven: map['amountGiven'],
      monthsCovered: map['monthsCovered'],
      remainingBalance: map['remainingBalance'],
      date: map['date'],
    );
  }
}
