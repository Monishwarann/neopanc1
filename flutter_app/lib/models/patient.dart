class PatientQuestionnaire {
  final int age;
  final String gender;
  final String bloodGroup;
  final double height;
  final double weight;
  final double bmi;
  final int smokingHistory;
  final int alcoholConsumption;
  final int diabetes;
  final int familyHistory;
  final int weightLoss;
  final int abdominalPain;
  final int appetiteChanges;
  final int jaundice;

  PatientQuestionnaire({
    required this.age,
    required this.gender,
    required this.bloodGroup,
    required this.height,
    required this.weight,
    required this.bmi,
    required this.smokingHistory,
    required this.alcoholConsumption,
    required this.diabetes,
    required this.familyHistory,
    required this.weightLoss,
    required this.abdominalPain,
    required this.appetiteChanges,
    required this.jaundice,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'smoking_history': smokingHistory,
      'alcohol_consumption': alcoholConsumption,
      'diabetes': diabetes,
      'family_history': familyHistory,
      'weight_loss': weightLoss,
      'abdominal_pain': abdominalPain,
      'appetite_changes': appetiteChanges,
      'jaundice': jaundice,
    };
  }
}
