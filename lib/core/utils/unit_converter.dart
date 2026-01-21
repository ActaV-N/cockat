import '../../data/providers/onboarding_provider.dart';

class UnitConverter {
  /// ml → oz conversion (1 oz = 29.5735 ml)
  static double mlToOz(double ml) => ml / 29.5735;

  /// oz → ml conversion
  static double ozToMl(double oz) => oz * 29.5735;

  /// Format amount with unit conversion based on user's preferred unit system
  static String formatAmount(
    double amount,
    String originalUnit,
    UnitSystem targetUnit, {
    double? amountMax,
  }) {
    // Case 1: Range display (amount-amountMax)
    if (amountMax != null) {
      final convertedAmount = _convert(amount, originalUnit, targetUnit);
      final convertedMax = _convert(amountMax, originalUnit, targetUnit);
      return '${_formatNumber(convertedAmount)}-${_formatNumber(convertedMax)} ${targetUnit.value}';
    }

    // Case 2: Single value display
    final converted = _convert(amount, originalUnit, targetUnit);
    return '${_formatNumber(converted)} ${targetUnit.value}';
  }

  /// Convert value from one unit to target unit system
  static double _convert(double value, String from, UnitSystem to) {
    // If already in target unit, no conversion needed
    if (from == to.value) return value;

    // parts is a ratio, cannot convert
    if (from == 'parts' || to == UnitSystem.parts) return value;

    // ml ↔ oz conversion
    if (from == 'ml' && to == UnitSystem.oz) {
      return mlToOz(value);
    } else if (from == 'oz' && to == UnitSystem.ml) {
      return ozToMl(value);
    }

    return value; // Return original if no conversion available
  }

  /// Format number (remove decimal for integers, round to 1 decimal place)
  static String _formatNumber(double value) {
    // If integer, remove decimal point
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    // Round to 1 decimal place
    return value.toStringAsFixed(1);
  }
}
