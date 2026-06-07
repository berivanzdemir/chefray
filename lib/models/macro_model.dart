/// Model for macro nutrient data.
class MacroModel {
  final String name;
  final int current;
  final int target;
  final double percentage;

  const MacroModel({
    required this.name,
    required this.current,
    required this.target,
    required this.percentage,
  });
}

class MacroMockData {
  MacroMockData._();

  static const List<MacroModel> macros = [
    MacroModel(name: 'Protein', current: 78, target: 110, percentage: 0.71),
    MacroModel(name: 'Karbonhidrat', current: 165, target: 275, percentage: 0.60),
    MacroModel(name: 'Yağ', current: 42, target: 73, percentage: 0.58),
  ];
}
