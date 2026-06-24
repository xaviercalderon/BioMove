// model/onboarding_model.dart — Modelos del onboarding ISO/IEC 25010:2023
class OnboardingSlideModel {
  final String title;
  final String subtitle;
  final String animationKey;
  final List<String> bulletPoints;
  final bool skippable; // ISO Aprendizabilidad: el usuario puede saltarse slides que ya conoce

  const OnboardingSlideModel({
    required this.title,
    required this.subtitle,
    required this.animationKey,
    required this.bulletPoints,
    this.skippable = true,
  });
}
