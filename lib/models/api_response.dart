/// Standard API response model for consistent response format
class ApiResponse<T> {
  final String status; // 'success' or 'error'
  final String message;
  final T? data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  /// Create success response
  factory ApiResponse.success({
    required String message,
    T? data,
  }) {
    return ApiResponse(
      status: 'success',
      message: message,
      data: data,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String message,
  }) {
    return ApiResponse(
      status: 'error',
      message: message,
      data: null,
    );
  }

  /// Convert to JSON format
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      if (data != null) 'data': data,
    };
  }
}
