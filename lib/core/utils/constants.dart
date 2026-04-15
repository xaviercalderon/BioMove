// lib/core/utils/constants.dart
class AppConstants {
  // IMPORTANTE: Emulador Android = 10.0.2.2 | Dispositivo físico = IP de tu PC
  static const baseUrl = 'http://10.0.2.2:8000';
  static const firebaseStorageBucket = 'biomove-c5ee5.firebasestorage.app';
  static const googleWebClientId = '178341348430-624smbtjhkkq8dsp10ptcankvic8vg49.apps.googleusercontent.com';
}

class ExerciseInfo {
  final String id, label, emoji, description, primaryView;
  const ExerciseInfo({required this.id, required this.label, required this.emoji,
      required this.description, required this.primaryView});

  static const squat      = ExerciseInfo(id:'squat',       label:'Sentadilla',  emoji:'🏋️',
      description:'40 parámetros: rodilla, cadera, espalda, tobillo', primaryView:'lateral');
  static const deadlift   = ExerciseInfo(id:'deadlift',    label:'Peso muerto', emoji:'⬆️',
      description:'Cadena posterior: espalda, cadera, rodilla', primaryView:'lateral');
  static const benchPress = ExerciseInfo(id:'bench_press', label:'Press banca', emoji:'🤸',
      description:'Tren superior: hombro, codo, muñeca, arco', primaryView:'frontal');

  static const all = [squat, deadlift, benchPress];
  static ExerciseInfo fromId(String id) => all.firstWhere((e) => e.id == id, orElse: () => squat);
}
