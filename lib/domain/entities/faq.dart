// domain/entities/faq.dart
class FaqAnswer {
  final String id;
  final String text;
  final String authorName;
  final String authorId;

  FaqAnswer({
    required this.id,
    required this.text,
    required this.authorName,
    required this.authorId,
  });

  factory FaqAnswer.fromJson(Map<String, dynamic> json) {
    return FaqAnswer(
      id: json['id'],
      text: json['text'],
      // Soporta tanto respuesta del backend como desde el cache local
      authorName: json['author']?['name'] ?? json['authorName'] ?? '',
      authorId: json['authorId'] ?? json['author_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'authorName': authorName,
      'authorId': authorId,
    };
  }
}

class FaqQuestion {
  final String id;
  final String title;
  final String question;
  final String authorName;
  final String authorId;
  final List<FaqAnswer> answers;

  FaqQuestion({
    required this.id,
    required this.title,
    required this.question,
    required this.authorId,
    required this.authorName,
    required this.answers,
  });

  factory FaqQuestion.fromJson(Map<String, dynamic> json) {
    return FaqQuestion(
      id: json['id'],
      title: json['title'],
      question: json['question'],
      authorId: json['authorId'] ?? json['author_id'] ?? '',
      // Soporta tanto backend (author.name) como cache local (authorName)
      authorName: json['author']?['name'] ?? json['authorName'] ?? '',
      answers: (json['answers'] as List? ?? [])
          .map((e) => FaqAnswer.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'question': question,
      'authorId': authorId,
      'authorName': authorName,
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }
}
