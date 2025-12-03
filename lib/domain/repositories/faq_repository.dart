import 'package:breakpoint/domain/entities/faq.dart';

abstract class FaqRepository {
  Future<List<FaqQuestion>> getQuestions();
  Future<FaqQuestion> getThread(String id);
  Future<FaqQuestion> createQuestion(String title, String question);
  Future<FaqAnswer> createAnswer(String questionId, String text);
}
