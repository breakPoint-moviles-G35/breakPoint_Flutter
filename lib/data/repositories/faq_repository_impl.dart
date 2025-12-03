import 'package:breakpoint/data/services/faq_api.dart';
import 'package:breakpoint/domain/entities/faq.dart';
import 'package:breakpoint/domain/repositories/faq_repository.dart';

class FaqRepositoryImpl implements FaqRepository {
  final FaqApi api;

  FaqRepositoryImpl(this.api);

  @override
  Future<List<FaqQuestion>> getQuestions() async {
    final raw = await api.getQuestions();
    return raw.map((e) => FaqQuestion.fromJson(e)).toList();
  }

  @override
  Future<FaqQuestion> getThread(String id) async {
    return FaqQuestion.fromJson(await api.getThread(id));
  }

  @override
  Future<FaqQuestion> createQuestion(String title, String question) async {
    return FaqQuestion.fromJson(
      await api.createQuestion(title: title, question: question),
    );
  }

  @override
  Future<FaqAnswer> createAnswer(String questionId, String text) async {
    return FaqAnswer.fromJson(
      await api.createAnswer(questionId: questionId, text: text),
    );
  }
}
