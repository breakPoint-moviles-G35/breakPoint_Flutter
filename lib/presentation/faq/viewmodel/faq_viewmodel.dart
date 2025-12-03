// presentation/faq/viewmodel/faq_viewmodel.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breakpoint/domain/entities/faq.dart';
import 'package:breakpoint/domain/repositories/faq_repository.dart';

class FaqViewModel extends ChangeNotifier {
  final FaqRepository faqRepository;

  FaqViewModel({required this.faqRepository});

  List<FaqQuestion> questions = [];
  FaqQuestion? currentThread;

  bool loading = false;
  String? error;
  bool offlineMode = false; // <- bandera para el banner

  static const _questionsKey = 'faq_questions_cache';
  static String _threadKey(String id) => 'faq_thread_$id';

  // =========================
  //        CACHE HELPERS
  // =========================

  Future<void> _saveQuestionsToCache(List<FaqQuestion> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        list.map((q) => jsonEncode(q.toJson())).toList(growable: false);
    await prefs.setStringList(_questionsKey, encoded);
  }

  Future<List<FaqQuestion>> _loadQuestionsFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_questionsKey);
    if (encoded == null) return [];
    return encoded
        .map((s) =>
            FaqQuestion.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveThreadToCache(FaqQuestion thread) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _threadKey(thread.id),
      jsonEncode(thread.toJson()),
    );
  }

  Future<FaqQuestion?> _loadThreadFromCache(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_threadKey(id));
    if (encoded == null) return null;
    return FaqQuestion.fromJson(jsonDecode(encoded) as Map<String, dynamic>);
  }

  // =========================
  //         MÉTODOS
  // =========================

  Future<void> loadQuestions() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await faqRepository.getQuestions();
      questions = result;
      offlineMode = false;
      await _saveQuestionsToCache(result);
    } catch (e) {
      // Si falla la red, intento usar cache
      final cached = await _loadQuestionsFromCache();
      if (cached.isNotEmpty) {
        questions = cached;
        offlineMode = true;
        error = null; // importante: no propagar el error si hay cache
      } else {
        error = e.toString();
        offlineMode = false;
      }
    }

    loading = false;
    notifyListeners();
  }

  Future<void> loadThread(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final thread = await faqRepository.getThread(id);
      currentThread = thread;
      offlineMode = false;
      await _saveThreadToCache(thread);
    } catch (e) {
      // Falla la red -> uso cache del hilo
      final cached = await _loadThreadFromCache(id);
      if (cached != null) {
        currentThread = cached;
        offlineMode = true;
        error = null; // no propagar error si hay cache
      } else {
        error = e.toString();
        offlineMode = false;
      }
    }

    loading = false;
    notifyListeners();
  }

  Future<void> submitAnswer(String questionId, String text) async {
    try {
      await faqRepository.createAnswer(questionId, text);
      await loadThread(questionId); // esto refresca y vuelve a cachear online
    } catch (e) {
      // aquí sí guardamos el error porque no tenemos fallback
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> submitQuestion(String title, String question) async {
    try {
      await faqRepository.createQuestion(title, question);
      await loadQuestions();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
