class ReviewReply {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userRole;
  final String comment;
  final DateTime createdAt;

  ReviewReply({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userRole,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewReply.fromJson(Map<String, dynamic> json) {
    return ReviewReply(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      userRole: json['userRole'] ?? 'Customer',
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}

class Review {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String userRole;
  final String productId;
  final String orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final List<ReviewReply> replies;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.userRole,
    required this.productId,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.replies,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    var repliesList = json['replies'] as List? ?? [];
    List<ReviewReply> parsedReplies = repliesList.map((r) => ReviewReply.fromJson(r)).toList();

    return Review(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'] ?? '',
      userRole: json['userRole'] ?? 'Customer',
      productId: json['productId'] ?? '',
      orderId: json['orderId'] ?? '',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      replies: parsedReplies,
    );
  }
}
