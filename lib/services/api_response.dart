/// Generic response wrapper for GIAT API calls
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final Map<String, dynamic>? rawData;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.rawData,
  });

  factory ApiResponse.success({
    required String message,
    T? data,
    int? statusCode,
    Map<String, dynamic>? rawData,
  }) {
    return ApiResponse(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode ?? 200,
      rawData: rawData,
    );
  }

  factory ApiResponse.error({
    required String message,
    T? data,
    int? statusCode,
    Map<String, dynamic>? rawData,
  }) {
    return ApiResponse(
      success: false,
      message: message,
      data: data,
      statusCode: statusCode,
      rawData: rawData,
    );
  }

  @override
  String toString() => 'ApiResponse(success: $success, message: $message, data: $data)';
}
