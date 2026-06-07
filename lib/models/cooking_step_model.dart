/// Model for a cooking step.
class CookingStepModel {
  final int step;
  final String title;
  final String description;
  final String duration;
  final int timerSeconds;
  final String? tip;

  const CookingStepModel({
    required this.step,
    required this.title,
    required this.description,
    required this.duration,
    this.timerSeconds = 0,
    this.tip,
  });

  CookingStepModel copyWith({
    int? step,
    String? title,
    String? description,
    String? duration,
    int? timerSeconds,
    String? tip,
  }) {
    return CookingStepModel(
      step: step ?? this.step,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      timerSeconds: timerSeconds ?? this.timerSeconds,
      tip: tip ?? this.tip,
    );
  }
}
