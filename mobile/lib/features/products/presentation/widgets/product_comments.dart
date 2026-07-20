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

  String? _editingReviewId;
  final TextEditingController _editController = TextEditingController();
  int _editRating = 5;
  bool _isEditing = false;

  String? _editingReplyReviewId;
  String? _editingReplyId;
  final TextEditingController _editReplyController = TextEditingController();
  bool _isEditingReply = false;

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
    _editController.dispose();
    _editReplyController.dispose();
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
            final newReview = Review.fromJson(reviewData);
            final index = _reviews.indexWhere((r) => r.id == newReview.id);
            if (index != -1) {
              _reviews[index] = newReview;
            } else {
              _reviews.insert(0, newReview);
            }
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
      'orderId': '000000000000000000000000', // Backend expects a valid 24-digit hex ObjectId
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

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteReview(String reviewId, bool isAdminDelete) async {
    final confirm = await _showConfirmDialog('Xác nhận xóa', 'Bạn có chắc chắn muốn xóa bình luận này không?');
    if (!confirm) return;

    final success = await ApiService.deleteReview(reviewId, isAdminDelete: isAdminDelete);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa bình luận thất bại')));
    } else if (success && mounted) {
      setState(() {
        _reviews.removeWhere((r) => r.id == reviewId);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bình luận')));
    }
  }

  Future<void> _updateReview(String reviewId) async {
    final text = _editController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isEditing = true);

    final success = await ApiService.updateReview(reviewId, _editRating, text);

    if (mounted) {
      setState(() {
        _isEditing = false;
        if (success) {
          final idx = _reviews.indexWhere((r) => r.id == reviewId);
          if (idx != -1) {
            final old = _reviews[idx];
            _reviews[idx] = Review(
              id: old.id,
              userId: old.userId,
              userName: old.userName,
              userAvatar: old.userAvatar,
              userRole: old.userRole,
              productId: old.productId,
              orderId: old.orderId,
              rating: _editRating,
              comment: text,
              createdAt: old.createdAt,
              replies: old.replies,
            );
          }
          _editingReviewId = null;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật bình luận thành công')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật bình luận thất bại')));
        }
      });
    }
  }

  Future<void> _updateReply(String reviewId, String replyId) async {
    final text = _editReplyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isEditingReply = true);

    final success = await ApiService.updateReply(reviewId, replyId, text);

    if (mounted) {
      setState(() {
        _isEditingReply = false;
        if (success) {
          final idx = _reviews.indexWhere((r) => r.id == reviewId);
          if (idx != -1) {
            final repIdx = _reviews[idx].replies.indexWhere((r) => r.id == replyId);
            if (repIdx != -1) {
              final oldRep = _reviews[idx].replies[repIdx];
              _reviews[idx].replies[repIdx] = ReviewReply(
                id: oldRep.id,
                userId: oldRep.userId,
                userName: oldRep.userName,
                userAvatar: oldRep.userAvatar,
                userRole: oldRep.userRole,
                comment: text,
                createdAt: oldRep.createdAt,
              );
            }
          }
          _editingReplyId = null;
          _editingReplyReviewId = null;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật câu trả lời thành công')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật câu trả lời thất bại')));
        }
      });
    }
  }

  Future<void> _deleteReply(String reviewId, String replyId) async {
    final confirm = await _showConfirmDialog('Xác nhận xóa', 'Bạn có chắc chắn muốn xóa câu trả lời này không?');
    if (!confirm) return;

    final success = await ApiService.deleteReply(reviewId, replyId);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa câu trả lời thất bại')));
    } else if (success && mounted) {
      setState(() {
        final idx = _reviews.indexWhere((r) => r.id == reviewId);
        if (idx != -1) {
          _reviews[idx].replies.removeWhere((r) => r.id == replyId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa câu trả lời')));
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
            final bool isOwner = _currentUser?.id == review.userId;
            final bool canEdit = isOwner;
            final bool canDelete = _currentUser?.role == 'Admin' || _currentUser?.role == 'Staff' || isOwner;
            final bool isAdminDelete = _currentUser?.role == 'Admin' || _currentUser?.role == 'Staff';

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
                                  if (_currentUser != null) const SizedBox(width: 16),
                                  if (canEdit) ...[
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _editingReviewId = review.id;
                                          _editRating = review.rating;
                                          _editController.text = review.comment;
                                        });
                                      },
                                      child: const Text('Sửa', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  if (canDelete) ...[
                                    GestureDetector(
                                      onTap: () => _deleteReview(review.id, isAdminDelete && !isOwner),
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
                  
                  // Edit Input Field
                  if (_editingReviewId == review.id)
                    Padding(
                      padding: const EdgeInsets.only(left: 52, top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(5, (index) => IconButton(
                                icon: Icon(
                                  index < _editRating ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _editRating = index + 1),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _editController,
                              maxLines: 2,
                              style: TextStyle(color: textColor, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Sửa bình luận...',
                                hintStyle: TextStyle(color: hintColor),
                                isDense: true,
                                contentPadding: const EdgeInsets.all(10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => setState(() => _editingReviewId = null),
                                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                                ),
                                ElevatedButton(
                                  onPressed: _isEditing ? null : () => _updateReview(review.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  child: _isEditing
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Lưu', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
                            final bool isReplyOwner = _currentUser?.id == reply.userId;
                            final bool canEditReply = isReplyOwner;
                            final bool canDeleteReply = _currentUser?.role == 'Admin' || _currentUser?.role == 'Staff' || isReplyOwner;

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

                                        if (_editingReplyId == reply.id)
                                          Column(
                                            children: [
                                              TextField(
                                                controller: _editReplyController,
                                                maxLines: 2,
                                                style: TextStyle(color: textColor, fontSize: 13),
                                                decoration: InputDecoration(
                                                  hintText: 'Sửa câu trả lời...',
                                                  hintStyle: TextStyle(color: hintColor),
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.all(10),
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: borderColor)),
                                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.blue)),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () => setState(() => _editingReplyId = null),
                                                    child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: _isEditingReply ? null : () => _updateReply(review.id, reply.id),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                                      minimumSize: const Size(0, 30),
                                                    ),
                                                    child: _isEditingReply
                                                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                      : const Text('Lưu', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        else
                                          Text(reply.comment, style: TextStyle(color: textColor, height: 1.4, fontSize: 13)),

                                        if (_currentUser != null && _editingReplyId != reply.id)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                if (canEditReply) ...[
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _editingReplyId = reply.id;
                                                        _editingReplyReviewId = review.id;
                                                        _editReplyController.text = reply.comment;
                                                      });
                                                    },
                                                    child: const Text('Sửa', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
                                                  ),
                                                  const SizedBox(width: 12),
                                                ],
                                                if (canDeleteReply) ...[
                                                  GestureDetector(
                                                    onTap: () => _deleteReply(review.id, reply.id),
                                                    child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                                                  ),
                                                ]
                                              ],
                                            ),
                                          ),
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
