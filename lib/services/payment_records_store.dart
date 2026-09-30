import 'package:flutter/foundation.dart';

class PaymentRecordsStore extends ChangeNotifier {
  static final PaymentRecordsStore _instance = PaymentRecordsStore._internal();
  factory PaymentRecordsStore() => _instance;
  PaymentRecordsStore._internal();

  final Set<String> usedUtrNumbers = {};

  bool isUtrAlreadyUsed(String utr) => usedUtrNumbers.contains(utr);

  void recordUtr(String utr) {
    usedUtrNumbers.add(utr);
    notifyListeners();
  }
}
