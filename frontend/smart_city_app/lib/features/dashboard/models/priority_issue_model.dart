class PriorityIssue {
  final int issueId;
  final String title;
  final String description;
  final String category;
  final String status;
  final String aiPriority;
 final String finalPriority;
final String? reviewStatus;
  final String? priorityExplanation;
  final List<String> matchedKeywords;
  final int analysisId;
  final DateTime createdAt;

  PriorityIssue({
    required this.issueId,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.aiPriority,
   required this.finalPriority,
this.reviewStatus,
    this.priorityExplanation,
    required this.matchedKeywords,
    required this.analysisId,
    required this.createdAt,
  });

  factory PriorityIssue.fromJson(Map<String, dynamic> json) {
    return PriorityIssue(
      issueId: json['issue_id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      status: json['status'],
      aiPriority: json['ai_priority'],
     finalPriority: json['final_priority'] ?? json['ai_priority'],
reviewStatus: json['review_status'],
      priorityExplanation: json['priority_explanation'],
      matchedKeywords: List<String>.from(
        json['matched_keywords'] ?? [],
      ),
      analysisId: json['analysis_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
