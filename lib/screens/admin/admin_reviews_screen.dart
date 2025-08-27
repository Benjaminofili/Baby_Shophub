// // File: lib/screens/admin/admin_reviews_screen.dart
// import 'package:flutter/material.dart';
// import '../../../services/admin_service.dart';
// import '../../../components/loading_widget.dart';
// import '../../../components/error_widget.dart';
// import '../../../components/empty_state_widget.dart';
// import '../../../components/custom_app_bar.dart';
// import '../../../theme.dart';
//
// class AdminReviewsScreen extends StatefulWidget {
//   const AdminReviewsScreen({super.key});
//
//   @override
//   State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
// }
//
// class _AdminReviewsScreenState extends State<AdminReviewsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool _isLoading = true;
//   String? _error;
//   List<Map<String, dynamic>> _reviews = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadReviews();
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _loadReviews([bool? isApproved]) async {
//     try {
//       setState(() {
//         _isLoading = true;
//         _error = null;
//       });
//
//       final reviews = await AdminService.getAllReviews(isApproved: isApproved);
//
//       setState(() {
//         _reviews = reviews;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = e.toString();
//         _isLoading = false;
//       });
//     }
//   }
//
//   Future<void> _approveReview(String reviewId) async {
//     try {
//       await AdminService.approveReview(reviewId);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Review approved successfully')),
//       );
//       _loadReviews(_getCurrentApprovalStatus());
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error approving review: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _rejectReview(String reviewId) async {
//     try {
//       await AdminService.rejectReview(reviewId);
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Review rejected successfully')),
//       );
//       _loadReviews(_getCurrentApprovalStatus());
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error rejecting review: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
//
//   Future<void> _deleteReview(String reviewId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Confirm Delete'),
//         content: Text('Are you sure you want to delete this review? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );
//
//     if (confirmed == true) {
//       try {
//         await AdminService.deleteReview(reviewId);
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Review deleted successfully')),
//         );
//         _loadReviews(_getCurrentApprovalStatus());
//       } catch (e) {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error deleting review: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }
//
//   bool? _getCurrentApprovalStatus() {
//     switch (_tabController.index) {
//       case 0:
//         return null; // All reviews
//       case 1:
//         return false; // Pending reviews
//       case 2:
//         return true; // Approved reviews
//       default:
//         return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: CustomAppBar(
//         title: 'Reviews Management',
//         subtitle: _reviews.isNotEmpty ? '${_reviews.length} reviews' : null,
//       ),
//       body: Column(
//         children: [
//           _buildTabBar(),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildReviewsList(null), // All reviews
//                 _buildReviewsList(false), // Pending reviews
//                 _buildReviewsList(true), // Approved reviews
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTabBar() {
//     return Container(
//       color: Colors.white,
//       child: TabBar(
//         controller: _tabController,
//         labelColor: AppTheme.primary,
//         unselectedLabelColor: Colors.grey,
//         indicatorColor: AppTheme.primary,
//         onTap: (index) {
//           final status = _getCurrentApprovalStatus();
//           _loadReviews(status);
//         },
//         tabs: [
//           Tab(text: 'ALL REVIEWS'),
//           Tab(text: 'PENDING'),
//           Tab(text: 'APPROVED'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReviewsList(bool? isApproved) {
//     if (_isLoading) {
//       return LoadingWidget(message: 'Loading reviews...');
//     }
//
//     if (_error != null) {
//       return ErrorDisplayWidget(
//         message: _error!,
//         actionText: 'Retry',
//         onActionPressed: () => _loadReviews(isApproved),
//       );
//     }
//
//     if (_reviews.isEmpty) {
//       String message;
//       if (isApproved == null) {
//         message = 'No reviews found';
//       } else if (isApproved) {
//         message = 'No approved reviews found';
//       } else {
//         message = 'No pending reviews found';
//       }
//
//       return EmptyStateWidget(
//         message: message,
//         subtitle: 'Reviews will appear here when customers submit them',
//         icon: Icons.rate_review,
//       );
//     }
//
//     return RefreshIndicator(
//       onRefresh: () => _loadReviews(isApproved),
//       child: ListView.builder(
//         padding: EdgeInsets.all(16),
//         itemCount: _reviews.length,
//         itemBuilder: (context, index) {
//           final review = _reviews[index];
//           return _buildReviewCard(review);
//         },
//       ),
//     );
//   }
//
//   Widget _buildReviewCard(Map<String, dynamic> review) {
//     final isApproved = review['is_approved'] ?? false;
//     final rating = (review['rating'] as num?)?.toInt() ?? 0;
//     final reviewText = review['review_text'] ?? '';
//     final customerName = review['profiles']?['full_name'] ?? 'Anonymous';
//     final productName = review['products']?['name'] ?? 'Unknown Product';
//     final productImage = review['products']?['image_url'];
//     final createdAt = DateTime.tryParse(review['created_at'] ?? '');
//
//     return Card(
//       margin: EdgeInsets.only(bottom: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 // Product Image
//                 Container(
//                   width: 50,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(8),
//                     color: Colors.grey[100],
//                   ),
//                   child: productImage != null
//                       ? ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.network(
//                       productImage,
//                       fit: BoxFit.cover,
//                       errorBuilder: (_, __, ___) => Icon(Icons.image, color: Colors.grey),
//                     ),
//                   )
//                       : Icon(Icons.image, color: Colors.grey),
//                 ),
//                 SizedBox(width: 12),
//
//                 // Product and Customer Info
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         productName,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                           color: AppTheme.textPrimary,
//                         ),
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       SizedBox(height: 2),
//                       Text(
//                         'By $customerName',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: AppTheme.textSecondary,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 // Status Badge
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: isApproved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     isApproved ? 'APPROVED' : 'PENDING',
//                     style: TextStyle(
//                       fontSize: 10,
//                       color: isApproved ? Colors.green : Colors.orange,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 12),
//
//             // Star Rating
//             Row(
//               children: [
//                 ...List.generate(5, (index) {
//                   return Icon(
//                     index < rating ? Icons.star : Icons.star_border,
//                     color: Colors.amber,
//                     size: 18,
//                   );
//                 }),
//                 SizedBox(width: 8),
//                 Text(
//                   '$rating/5',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: AppTheme.textPrimary,
//                   ),
//                 ),
//                 Spacer(),
//                 if (createdAt != null)
//                   Text(
//                     '${createdAt.day}/${createdAt.month}/${createdAt.year}',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: AppTheme.textSecondary,
//                     ),
//                   ),
//               ],
//             ),
//
//             if (reviewText.isNotEmpty) ...[
//               SizedBox(height: 12),
//               Container(
//                 padding: EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   reviewText,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: AppTheme.textPrimary,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//
//             SizedBox(height: 12),
//
//             // Action Buttons
//             Row(
//               children: [
//                 if (!isApproved) ...[
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () => _approveReview(review['id']),
//                       icon: Icon(Icons.check, size: 16),
//                       label: Text('Approve'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.green,
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => _rejectReview(review['id']),
//                       icon: Icon(Icons.close, size: 16),
//                       label: Text('Reject'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.red,
//                         side: BorderSide(color: Colors.red),
//                         padding: EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//                 if (isApproved) ...[
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () => _rejectReview(review['id']),
//                       icon: Icon(Icons.remove_circle, size: 16),
//                       label: Text('Unapprove'),
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: Colors.orange,
//                         side: BorderSide(color: Colors.orange),
//                         padding: EdgeInsets.symmetric(vertical: 8),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                 ],
//                 SizedBox(
//                   width: 40,
//                   child: IconButton(
//                     onPressed: () => _deleteReview(review['id']),
//                     icon: Icon(Icons.delete, size: 18),
//                     color: Colors.red,
//                     tooltip: 'Delete Review',
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }