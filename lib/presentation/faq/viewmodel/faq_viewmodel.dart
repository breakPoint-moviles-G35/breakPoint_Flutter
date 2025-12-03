import 'package:flutter/material.dart';
import 'package:breakpoint/domain/entities/faq.dart';
import 'package:breakpoint/domain/repositories/faq_repository.dart';

class FaqViewModel extends ChangeNotifier {
  final FaqRepository faqRepository;

  FaqViewModel({required this.faqRepository});

  List<FaqQuestion> questions = [];
  FaqQuestion? currentThread;

  bool loading = false;
  String? error;

  Future<void> loadQuestions() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      questions = await faqRepository.getQuestions();
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> loadThread(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      currentThread = await faqRepository.getThread(id);
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> submitAnswer(String questionId, String text) async {
    try {
      await faqRepository.createAnswer(questionId, text);
      await loadThread(questionId);
    } catch (e) {
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
