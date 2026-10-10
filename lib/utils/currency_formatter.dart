class CurrencyFormatter {
  static String formatCurrency(int amount) {
    String str = amount.toString();
    if (str.length <= 3) return str;
    String lastThree = str.substring(str.length - 3);
    String otherNumbers = str.substring(0, str.length - 3);
    if (otherNumbers != '') {
      lastThree = ',$lastThree';
    }
    String result = '';
    for (int i = 0; i < otherNumbers.length; i++) {
      if (i > 0 && (otherNumbers.length - i) % 2 == 0) {
        result += ',';
      }
      result += otherNumbers[i];
    }
    return result + lastThree;
  }
}
