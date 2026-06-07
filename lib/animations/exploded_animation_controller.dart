/// Timing curves for the exploded view animation sequence.
/// Used by ExplodedRecipeScreen to orchestrate the multi-phase animation.
class ExplodedAnimationConfig {
  ExplodedAnimationConfig._();

  /// Total animation duration
  static const Duration totalDuration = Duration(milliseconds: 2400);

  /// Phase 1: Scan beam (0.0 - 0.35)
  static const double scanStart = 0.0;
  static const double scanEnd = 0.35;

  /// Phase 2: Ingredients separate (0.25 - 0.7)
  static const double separateStart = 0.25;
  static const double separateEnd = 0.7;

  /// Phase 3: Labels fade in (0.5 - 0.85)
  static const double labelsStart = 0.5;
  static const double labelsEnd = 0.85;

  /// Phase 4: Connector lines (0.65 - 1.0)
  static const double connectorsStart = 0.65;
  static const double connectorsEnd = 1.0;

  /// Calculate sub-progress within a phase
  static double phaseProgress(double t, double start, double end) {
    if (t <= start) return 0.0;
    if (t >= end) return 1.0;
    return (t - start) / (end - start);
  }
}
