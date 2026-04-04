class LyricSection {
  const LyricSection({required this.heading, required this.content});

  final String heading;
  final String content;

  LyricSection copyWith({String? heading, String? content}) {
    return LyricSection(
      heading: heading ?? this.heading,
      content: content ?? this.content,
    );
  }

  Map<String, dynamic> toJson() {
    return {'heading': heading, 'content': content};
  }

  factory LyricSection.fromJson(Map<String, dynamic> json) {
    return LyricSection(
      heading: json['heading'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}
