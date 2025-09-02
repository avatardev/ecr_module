import 'transaction_data.dart';

class EdcResponse {
  final String status;
  final String message;
  final TransactionData? data;

  EdcResponse({required this.status, required this.message, this.data});
}

typedef EdcCallback = void Function(EdcResponse response);
