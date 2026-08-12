class FormatUtils {
  static String format(double value, {int decimals = 4}) {
    if (value.isNaN || value.isInfinite) return value.toString();
    
    // Round to the specified number of decimals to handle floating-point noise
    String s = value.toStringAsFixed(decimals);
    
    // Remove trailing zeros if there is a decimal point
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0*$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    
    return s;
  }
}
