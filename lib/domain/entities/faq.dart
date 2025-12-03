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
      authorName: json['author']?['name'] ?? '',
      authorId: json['authorId'] ?? json['author_id'] ?? '',
    );
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
      authorName: json['author']?['name'] ?? '',
      answers: (json['answers'] as List? ?? [])
          .map((e) => FaqAnswer.fromJson(e))
          .toList(),
    );
  }
}
