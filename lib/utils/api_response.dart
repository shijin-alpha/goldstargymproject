/// Standardized API response structure
class ApiResponse<T> {
  final String status;
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
    final Map<String, dynamic> json = {
      'status': status,
      'message': message,
    };

    if (data != null) {
      json['data'] = data as dynamic;
    }

    return json;
  }
}
