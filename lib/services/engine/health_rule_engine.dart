import '../parsing/blood_value_parser.dart';
import '../parsing/diet_plan_parser.dart';

class HealthRuleEngineResult {
  final List<String> labFlags;
  final List<String> recipeTags;
  final List<String> avoidTags;
  final List<String> dietGaps;

  const HealthRuleEngineResult({
    this.labFlags = const [],
    this.recipeTags = const [],
    this.avoidTags = const [],
    this.dietGaps = const [],
  });

  Map<String, dynamic> toJson() => {
        'lab_flags': labFlags,
        'recipe_tags': recipeTags,
        'avoid_tags': avoidTags,
        'diet_gaps': dietGaps,
      };

  /// Builds the anonymized JSON for AI consumption.
  Map<String, dynamic> toAnonymizedJson() => {
        'lab_flags': labFlags,
        'recipe_tags': recipeTags,
        'avoid_tags': avoidTags,
        'diet_gaps': dietGaps,
      };

  bool get hasFlags => labFlags.isNotEmpty;
}

class HealthRuleEngine {
  static final HealthRuleEngine _instance = HealthRuleEngine._();
  factory HealthRuleEngine() => _instance;
  HealthRuleEngine._();

  /// Generates lab_flags, recipe_tags, avoid_tags, and diet_gaps
  /// from parsed blood values and diet plan.
  HealthRuleEngineResult evaluate({
    required ParsedBloodValues bloodValues,
    ParsedDietPlan? dietPlan,
  }) {
    final labFlags = <String>[];
    final recipeTags = <String>[];
    final avoidTags = <String>[];
    final dietGaps = <String>[];

    // ── Blood value rules ──────────────────────────────────────

    // B12 rules
    final b12 = bloodValues.values['b12'];
    if (b12 != null && b12.status == 'low') {
      labFlags.addAll(['low_b12', 'b12_deficiency_risk']);
      recipeTags.addAll(['b12_rich', 'prefer_egg', 'prefer_fish', 'prefer_animal_protein']);
      dietGaps.add('b12_support_needed');
    }

    // Vitamin D rules
    final vitD = bloodValues.values['vitamin_d'];
    if (vitD != null && vitD.status == 'low') {
      labFlags.addAll(['low_vitamin_d', 'vitamin_d_deficiency_risk']);
      recipeTags.addAll(['vitamin_d_rich', 'prefer_fish', 'prefer_egg', 'prefer_dairy']);
      dietGaps.add('vitamin_d_support_needed');
    }

    // Ferritin / Iron rules
    final ferritin = bloodValues.values['ferritin'];
    final iron = bloodValues.values['iron'];
    if ((ferritin != null && ferritin.status == 'low') || (iron != null && iron.status == 'low')) {
      labFlags.addAll(['low_ferritin', 'iron_deficiency_risk']);
      recipeTags.addAll(['iron_rich', 'prefer_legumes', 'prefer_red_meat_moderate', 'prefer_spinach']);
      dietGaps.add('iron_support_needed');
    }

    // LDL rules
    final ldl = bloodValues.values['ldl'];
    if (ldl != null && ldl.status == 'high') {
      labFlags.addAll(['high_ldl', 'ldl_elevated']);
      recipeTags.addAll(['fiber_rich', 'prefer_olive_oil', 'low_saturated_fat', 'prefer_fish']);
      avoidTags.addAll(['high_saturated_fat', 'fried', 'processed_meat']);
      dietGaps.add('fiber_support_needed');
    }

    // HDL rules
    final hdl = bloodValues.values['hdl'];
    if (hdl != null && hdl.status == 'low') {
      labFlags.addAll(['low_hdl', 'hdl_decreased']);
      recipeTags.addAll(['omega3', 'prefer_olive_oil', 'prefer_fish', 'prefer_nuts']);
      avoidTags.addAll(['high_saturated_fat', 'trans_fat']);
      dietGaps.add('omega3_support_needed');
    }

    // Total cholesterol rules
    final totalChol = bloodValues.values['total_cholesterol'];
    if (totalChol != null && totalChol.status == 'high') {
      labFlags.addAll(['high_total_cholesterol']);
      recipeTags.addAll(['fiber_rich', 'low_saturated_fat', 'prefer_fish']);
      avoidTags.addAll(['high_saturated_fat', 'fried']);
    }

    // Triglyceride rules
    final trig = bloodValues.values['triglyceride'];
    if (trig != null && trig.status == 'high') {
      labFlags.addAll(['high_triglyceride', 'triglyceride_elevated']);
      recipeTags.addAll(['omega3', 'prefer_fish', 'low_glycemic']);
      avoidTags.addAll(['refined_carbs', 'sugar', 'alcohol']);
      dietGaps.add('omega3_support_needed');
    }

    // Glucose rules
    final glucose = bloodValues.values['glucose'];
    if (glucose != null && glucose.status == 'high') {
      labFlags.addAll(['high_glucose', 'glucose_elevated']);
      recipeTags.addAll(['low_glycemic', 'high_fiber', 'prefer_whole_grain']);
      avoidTags.addAll(['refined_carbs', 'sugar', 'high_glycemic']);
      dietGaps.add('fiber_support_needed');
    }

    // HbA1c rules
    final hba1c = bloodValues.values['hba1c'];
    if (hba1c != null && hba1c.status == 'high') {
      labFlags.addAll(['high_hba1c', 'hba1c_elevated']);
      recipeTags.addAll(['low_glycemic', 'high_fiber', 'prefer_whole_grain']);
      avoidTags.addAll(['refined_carbs', 'sugar', 'processed_food']);
      dietGaps.add('blood_sugar_management_needed');
    }

    // TSH rules
    final tsh = bloodValues.values['tsh'];
    if (tsh != null) {
      if (tsh.status == 'high') {
        labFlags.addAll(['high_tsh', 'tsh_elevated']);
        recipeTags.addAll(['iodine_rich', 'selenium_rich', 'prefer_fish']);
        dietGaps.add('thyroid_support_needed');
      } else if (tsh.status == 'low') {
        labFlags.addAll(['low_tsh', 'tsh_decreased']);
      }
    }

    // ALT/AST rules
    final alt = bloodValues.values['alt'];
    final ast = bloodValues.values['ast'];
    if ((alt != null && alt.status == 'high') || (ast != null && ast.status == 'high')) {
      labFlags.addAll(['elevated_liver_enzymes']);
      avoidTags.addAll(['alcohol', 'fried', 'processed_food']);
      recipeTags.addAll(['antioxidant_rich', 'prefer_vegetables', 'low_fat']);
      dietGaps.add('liver_support_needed');
    }

    // CRP rules
    final crp = bloodValues.values['crp'];
    if (crp != null && crp.status == 'high') {
      labFlags.addAll(['high_crp', 'inflammation_marker_elevated']);
      recipeTags.addAll(['anti_inflammatory', 'omega3', 'antioxidant_rich']);
      avoidTags.addAll(['processed_food', 'fried', 'high_sugar']);
    }

    // Hemoglobin rules
    final hgb = bloodValues.values['hemoglobin'];
    if (hgb != null && hgb.status == 'low') {
      labFlags.addAll(['low_hemoglobin', 'anemia_risk']);
      recipeTags.addAll(['iron_rich', 'b12_rich', 'folate_rich', 'prefer_red_meat_moderate']);
      dietGaps.add('iron_support_needed');
    }

    // WBC rules
    final wbc = bloodValues.values['wbc'];
    if (wbc != null) {
      if (wbc.status == 'high') {
        labFlags.addAll(['high_wbc']);
      } else if (wbc.status == 'low') {
        labFlags.addAll(['low_wbc']);
      }
    }

    // ── Diet gap analysis from diet plan ────────────────────
    if (dietPlan != null && dietPlan.hasContent) {
      final allFoods = dietPlan.detectedFoodItems.map((f) => f.toLowerCase()).toList();
      final allFoodText = allFoods.join(' ');

      // Check for protein sources
      final hasAnimalProtein = RegExp(r'tavuk|et|balık|balik|köfte|kofte|somon|ton|yumurta').hasMatch(allFoodText);
      final hasPlantProtein = RegExp(r'mercimek|nohut|fasulye|bezelye|börülce|soya|tofu').hasMatch(allFoodText);
      final hasDairy = RegExp(r'süt|sut|yoğurt|yogurt|peynir|kefir|ayran').hasMatch(allFoodText);
      final hasFish = RegExp(r'balık|balik|somon|ton|levrek|çupra|cupra|alabalık').hasMatch(allFoodText);
      final hasVegetables = RegExp(r'sebze|salata|ıspanak|brokoli|havuç|domates|biber|patlıcan|kabak').hasMatch(allFoodText);
      final hasLegumes = RegExp(r'mercimek|nohut|fasulye|börülce|bezelye').hasMatch(allFoodText);
      final hasWholeGrain = RegExp(r'bulgur|tam buğday|tam bugday|çavdar|cavdar|yulaf|kinoa|kepek').hasMatch(allFoodText);

      if (!hasFish) {
        dietGaps.add('fish_intake_low');
        recipeTags.add('prefer_fish');
      }
      if (!hasVegetables) {
        dietGaps.add('vegetable_intake_low');
        recipeTags.add('prefer_vegetables');
      }
      if (!hasLegumes) {
        dietGaps.add('legume_intake_low');
        recipeTags.add('prefer_legumes');
      }
      if (!hasWholeGrain) {
        dietGaps.add('whole_grain_intake_low');
        recipeTags.add('prefer_whole_grain');
      }
      if (!hasDairy && !hasAnimalProtein && !hasPlantProtein) {
        dietGaps.add('protein_intake_low');
        recipeTags.add('high_protein');
      }
    }

    // ── Always-safe universal tags ────────────────────────────
    if (recipeTags.isEmpty) {
      recipeTags.addAll(['balanced', 'general_health']);
    }

    return HealthRuleEngineResult(
      labFlags: labFlags.toSet().toList(),
      recipeTags: recipeTags.toSet().toList(),
      avoidTags: avoidTags.toSet().toList(),
      dietGaps: dietGaps.toSet().toList(),
    );
  }
}
