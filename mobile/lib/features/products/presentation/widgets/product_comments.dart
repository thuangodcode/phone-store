import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/review.dart';
import '../../../../core/models/user_info.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/review_signalr_service.dart';
import '../../../../../main.dart'; // For themeManager if needed

class ProductComments extends StatefulWidget {
  final String productId;
  final bool isDark;
  
  const ProductComments({
    Key? key,
    required this.productId,
    required this.isDark,
  }) : super(key: key);

  @override
  State<ProductComments> createState() => _ProductCommentsState();
}

class _ProductCommentsState extends State<ProductComments> {
  List<Review> _reviews = [];
  UserInfo? _currentUser;
  bool _isLoading = true;
  
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  String? _replyingToReviewId;
  final TextEditingController _replyController = TextEditingController();
  bool _isReplying = false;

  ReviewSignalRService? _signalRService;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initSignalR();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    _signalRService?.dispose(widget.productId);
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = await ApiService.getSavedUser();
    final reviewsData = await ApiService.getProductReviews(widget.productId);
    
    if (mounted) {
      setState(() {
        _currentUser = user;
        _reviews = reviewsData.map((e) => Review.fromJson(e)).toList();
        _isLoading = false;
      });
    }
  }

  void _initSignalR() {
    _signalRService = ReviewSignalRService(
      onReceiveReview: (reviewData) {
        if (mounted) {
          setState(() {
            _reviews.insert(0, Review.fromJson(reviewData));
          });
        }
      },
      onReceiveReviewDelete: (reviewId) {
        if (mounted) {
          setState(() {
            _reviews.removeWhere((r) => r.id == reviewId);
          });
        }
      },
      onReceiveReviewReply: (replyData) {
        if (mounted) {
          final reply = ReviewReply.fromJson(replyData);
          setState(() {
            final idx = _reviews.indexWhere((r) => r.id == replyData['reviewId']);
            if (idx != -1) {
              _reviews[idx].replies.add(reply);
            }
          });
        }
      },
    );
    _signalRService!.initConnection(widget.productId);
  }

  Future<void> _submitReview() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập để bình luận')));
      return;
    }
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    final result = await ApiService.createReview({
      'productId': widget.productId,
      'orderId': null, // Bỏ qua orderId theo logic hiện tại
      'rating': _rating,
      'comment': text,
    });

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result != null && result['success'] == true) {
        _commentController.clear();
        _rating = 5;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['message'] ?? 'Gửi bình luận thất bại')));
      }
    }
  }

  Future<void> _submitReply(String reviewId) async {
    if (_currentUser == null) return;
    
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isReplying = true);

    final result = await ApiService.replyReview(reviewId, text);

    if (mounted) {
      setState(() {
        _isReplying = false;
        if (result != null && result['success'] == true) {
          _replyController.clear();
          _replyingToReviewId = null;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result?['message'] ?? 'Gửi trả lời thất bại')));
        }
      });
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final success = await ApiService.deleteReview(reviewId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa bình luận thất bại')));
    }
  }

  Widget _buildAvatar(String? avatarUrl, String name) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey[200],
      );
    }
    
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.blue.withOpacity(0.2),
      child: Text(initial, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRoleBadge(String role) {
    if (role == 'Staff' || role == 'Admin') {
      return Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withOpacity(0.5)),
        ),
        child: const Text('QTV', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    final hintColor = widget.isDark ? Colors.white54 : Colors.black54;
    final cardColor = widget.isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = widget.isDark ? const Color(0xFF374151) : Colors.grey[200]!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá & Bình luận (${_reviews.length})',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 16),
        
        // Comment Input
        if (_currentUser != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildAvatar(_currentUser!.avatar, _currentUser!.fullName),
                    const SizedBox(width: 12),
                    Text(_currentUser!.fullName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) => IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 24,
                    ),
                    onPressed: () => setState(() => _rating = index + 1),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentController,
                  maxLines: 3,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Nhập đánh giá của bạn về sản phẩm...',
                    hintStyle: TextStyle(color: hintColor, fontSize: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isSubmitting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Gửi Đánh Giá', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: const Text('Vui lòng đăng nhập để bình luận.', style: TextStyle(color: Colors.blue)),
          ),
          
        const SizedBox(height: 24),

        // Reviews List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final review = _reviews[index];
            final bool canDelete = _currentUser?.role == 'Admin' || _currentUser?.role == 'Staff';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(review.userAvatar, review.userName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(review.userName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                _buildRoleBadge(review.userRole),
                                const Spacer(),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(review.createdAt),
                                  style: TextStyle(color: hintColor, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: List.generate(5, (starIdx) => Icon(
                                starIdx < review.rating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14,
                              )),
                            ),
                            const SizedBox(height: 8),
                            Text(review.comment, style: TextStyle(color: textColor, height: 1.4)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (_currentUser != null)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _replyingToReviewId = _replyingToReviewId == review.id ? null : review.id;
                                      });
                                    },
                                    child: const Text('Trả lời', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                if (canDelete) ...[
                                  if (_currentUser != null) const SizedBox(width: 16),
                                  GestureDetector(
                                    onTap: () => _deleteReview(review.id),
                                    child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Reply Input Field
                  if (_replyingToReviewId == review.id)
                    Padding(
                      padding: const EdgeInsets.only(left: 52, top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _replyController,
                              style: TextStyle(color: textColor, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Nhập câu trả lời...',
                                hintStyle: TextStyle(color: hintColor),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.blue)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: _isReplying 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send, color: Colors.blue),
                            onPressed: _isReplying ? null : () => _submitReply(review.id),
                          ),
                        ],
                      ),
                    ),

                  // Replies List
                  if (review.replies.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 40, top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDark ? const Color(0xFF374151).withOpacity(0.3) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: review.replies.map((reply) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildAvatar(reply.userAvatar, reply.userName),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(reply.userName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 13)),
                                            _buildRoleBadge(reply.userRole),
                                            const Spacer(),
                                            Text(
                                              DateFormat('dd/MM/yyyy HH:mm').format(reply.createdAt),
                                              style: TextStyle(color: hintColor, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(reply.comment, style: TextStyle(color: textColor, height: 1.4, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
