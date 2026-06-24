// viewmodel/onboarding_viewmodel.dart — ViewModel del onboarding
// ISO/IEC 25010:2023 — Aprendizabilidad: guía visual paso a paso con control de salto
import 'package:flutter/foundation.dart';
import '../model/onboarding_model.dart';

class OnboardingViewModel extends ChangeNotifier {
  int     _currentPage = 0;
  bool    _saving      = false;
  String? _error;

  double? heightCm;
  double? weightKg;
  int?    age;
  String  sex   = 'male';
  double  years = 1.0;

  // ── Slides ISO: guías visuales animadas ─────────────────────────────────
  static const List<OnboardingSlideModel> introSlides = [
    OnboardingSlideModel(
      title: 'Tu entrenador de IA',
      subtitle: 'Analiza tu técnica con precisión científica',
      animationKey: 'ai_coach',
      bulletPoints: [
        'Detecta tu cuerpo completo automáticamente',
        'Calcula 40 parámetros de movimiento por repetición',
        'Feedback inmediato después de cada sesión',
      ],
      skippable: true,
    ),
    OnboardingSlideModel(
      title: 'Aprende de cada sesión',
      subtitle: 'La IA se adapta a tu morfología',
      animationKey: 'learning',
      bulletPoints: [
        'Se calibra con tus rangos personales',
        'Detecta fatiga técnica antes de que causes lesión',
        'Compara tu progreso sesión a sesión',
      ],
      skippable: true,
    ),
    OnboardingSlideModel(
      title: 'Cómo grabar correctamente',
      subtitle: 'Sigue estos pasos para mejores resultados',
      animationKey: 'how_to_record',
      bulletPoints: [
        'Coloca la cámara a la altura de tu cadera',
        'Asegúrate de que todo tu cuerpo sea visible',
        'Elige una zona con buena iluminación',
      ],
      skippable: false, // OBLIGATORIO — ISO Operabilidad
    ),
  ];

  // ── Getters ──────────────────────────────────────────────────────────────
  int     get currentPage    => _currentPage;
  bool    get saving         => _saving;
  String? get error          => _error;
  bool    get isOnIntroSlide => _currentPage < introSlides.length;
  bool    get isOnDataForm   => _currentPage == introSlides.length;
  int     get totalPages     => introSlides.length + 1;
  double  get progress       => (_currentPage + 1) / totalPages;
  OnboardingSlideModel? get currentSlide => isOnIntroSlide ? introSlides[_currentPage] : null;
  bool    get canSkipCurrent => isOnIntroSlide && introSlides[_currentPage].skippable;

  // ── Acciones ──────────────────────────────────────────────────────────────
  void setPage(int p) { _currentPage = p; notifyListeners(); }

  void nextPage() {
    if (_currentPage < totalPages - 1) { _currentPage++; notifyListeners(); }
  }

  void skipToData() { _currentPage = introSlides.length; notifyListeners(); }

  void setHeight(String v) { heightCm = double.tryParse(v); notifyListeners(); }
  void setWeight(String v) { weightKg = double.tryParse(v); notifyListeners(); }
  void setAge(String v)    { age = int.tryParse(v); notifyListeners(); }
  void setSex(String v)    { sex = v; notifyListeners(); }
  void setYears(double v)  { years = v; notifyListeners(); }
  void setSaving(bool v)   { _saving = v; notifyListeners(); }
  void setError(String? v) { _error = v; notifyListeners(); }
  void clearError()        { _error = null; notifyListeners(); }

  static const double minHeight = 120, maxHeight = 200;
  static const double minWeight = 35,  maxWeight = 150;
  static const int    minAge    = 12,  maxAge    = 80;

  String? get heightError {
    if (heightCm == null) return null;
    if (heightCm! < minHeight || heightCm! > maxHeight)
      return 'Altura entre ${minHeight.toInt()} y ${maxHeight.toInt()} cm';
    return null;
  }

  String? get weightError {
    if (weightKg == null) return null;
    if (weightKg! < minWeight || weightKg! > maxWeight)
      return 'Peso entre ${minWeight.toInt()} y ${maxWeight.toInt()} kg';
    return null;
  }

  String? get ageError {
    if (age == null) return null;
    if (age! < minAge || age! > maxAge)
      return 'Edad entre $minAge y $maxAge años';
    return null;
  }

  bool get dataIsValid =>
      heightCm != null && heightError == null &&
      weightKg != null && weightError == null &&
      age      != null && ageError    == null;

  String? get dataError {
    if (heightCm == null) return 'Ingresa tu altura';
    if (heightError != null) return heightError;
    if (weightKg == null) return 'Ingresa tu peso';
    if (weightError != null) return weightError;
    if (age == null) return 'Ingresa tu edad';
    if (ageError != null) return ageError;
    return null;
  }
}
