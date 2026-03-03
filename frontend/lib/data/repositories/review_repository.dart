import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewRepository {
  final String _baseUrl = 'http://aharabackend-env.eba-nn8ggm5m.ap-south-1.elasticbeanstalk.com/api';

  /// Check if order can be reviewed
  Future<Map<String, dynamic>> checkReviewable({
    required String orderId,
    required String buyerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reviews/check-reviewable/$orderId?buyerId=$buyerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check reviewability: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new review
  Future<Map<String, dynamic>> createReview({
    required String orderId,
    required String reviewerId,
    required String targetType, // "seller" or "volunteer"
    required String targetUserId,
    required int rating,
    String? comment,
    List<String>? tags,
    bool isAnonymous = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': orderId,
          'reviewerId': reviewerId,
          'targetType': targetType,
          'targetUserId': targetUserId,
          'rating': rating,
          'comment': comment,
          'tags': tags,
          'isAnonymous': isAnonymous,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to create review');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get reviews for a user with analytics
  Future<Map<String, dynamic>> getReviewsForUser({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reviews/target/$userId?page=$page&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch reviews: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update a review
  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    required String reviewerId,
    int? rating,
    String? comment,
    List<String>? tags,
  }) async {
    try {
      final body = <String, dynamic>{
        'reviewerId': reviewerId,
      };
      if (rating != null) body['rating'] = rating;
      if (comment != null) body['comment'] = comment;
      if (tags != null) body['tags'] = tags;

      final response = await http.put(
        Uri.parse('$_baseUrl/reviews/$reviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to update review');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a review
  Future<void> deleteReview({
    required String reviewId,
    required String reviewerId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/reviews/$reviewId?reviewerId=$reviewerId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to delete review');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add response to a review (seller/volunteer reply)
  Future<Map<String, dynamic>> addReviewResponse({
    required String reviewId,
    required String responderId,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reviews/$reviewId/response'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'responderId': responderId,
          'message': message,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to add response');
      }
    } catch (e) {
      rethrow;
    }
  }
}
