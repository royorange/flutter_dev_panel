import 'network_request.dart';

class NetworkFilter {
  final String? searchQuery;
  final RequestMethod? method;
  final RequestStatus? status;
  final int? minStatusCode;
  final int? maxStatusCode;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool showOnlyErrors;

  const NetworkFilter({
    this.searchQuery,
    this.method,
    this.status,
    this.minStatusCode,
    this.maxStatusCode,
    this.startTime,
    this.endTime,
    this.showOnlyErrors = false,
  });

  bool matches(NetworkRequest request) {
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!request.url.toLowerCase().contains(query) &&
          !request.methodString.toLowerCase().contains(query) &&
          !(request.statusCode?.toString().contains(query) ?? false)) {
        return false;
      }
    }

    if (method != null && request.method != method) {
      return false;
    }

    if (status != null && request.status != status) {
      return false;
    }

    if (minStatusCode != null && (request.statusCode ?? 0) < minStatusCode!) {
      return false;
    }

    if (maxStatusCode != null && (request.statusCode ?? 999) > maxStatusCode!) {
      return false;
    }

    if (startTime != null && request.startTime.isBefore(startTime!)) {
      return false;
    }

    if (endTime != null && request.startTime.isAfter(endTime!)) {
      return false;
    }

    if (showOnlyErrors && !request.isError) {
      return false;
    }

    return true;
  }

  NetworkFilter copyWith({
    String? searchQuery,
    RequestMethod? method,
    RequestStatus? status,
    int? minStatusCode,
    int? maxStatusCode,
    DateTime? startTime,
    DateTime? endTime,
    bool? showOnlyErrors,
  }) {
    return NetworkFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      method: method ?? this.method,
      status: status ?? this.status,
      minStatusCode: minStatusCode ?? this.minStatusCode,
      maxStatusCode: maxStatusCode ?? this.maxStatusCode,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      showOnlyErrors: showOnlyErrors ?? this.showOnlyErrors,
    );
  }

  NetworkFilter clearFilters() {
    return const NetworkFilter();
  }

  bool get hasActiveFilters {
    return searchQuery != null ||
        method != null ||
        status != null ||
        minStatusCode != null ||
        maxStatusCode != null ||
        startTime != null ||
        endTime != null ||
        showOnlyErrors;
  }
}