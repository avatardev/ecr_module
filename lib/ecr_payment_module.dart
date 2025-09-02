import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import 'src/ecr_service.dart';
import 'src/payment_service_ecr.dart';
import 'src/edc_response.dart';
import 'src/ecr_utils.dart';
import 'src/transaction_data.dart';

typedef EcrTransactionExecutor =
    Future<Stream<Uint8List>?> Function(UsbPort port);

class EcrPaymentModule {
  final EcrService _ecrService = PaymentServiceEcr();
  int? _retryTransTryCount;
  String? _statusPaymentEdc;
  StreamSubscription<Uint8List>? _portSubscription;

  Future<UsbPort?> _openPort() async {
    List<UsbDevice> devices = await _ecrService.getUsbDevices();
    if (devices.isEmpty) return null;
    final edc = devices
        .where((device) => device.productName == "Move2500")
        .firstOrNull;
    if (edc == null) return null;
    return await _ecrService.connectDevices(edc);
  }

  void _executeTransaction(
    EcrTransactionExecutor transactionExecutor,
    EdcCallback onFinished,
  ) async {
    await _portSubscription?.cancel();
    _retryTransTryCount = null;
    _statusPaymentEdc = null;

    final port = await _openPort();
    if (port == null) {
      onFinished(
        EdcResponse(
          status: "DEVICE_NOT_FOUND",
          message: "No EDC device found.",
        ),
      );
      return;
    }
    _processTransaction(port, transactionExecutor, onFinished);
  }

  void _processTransaction(
    UsbPort port,
    EcrTransactionExecutor transactionExecutor,
    EdcCallback onFinished,
  ) async {
    try {
      final ackResp = await _ecrService.ackResponse(devicePort: port);
      final nakResp = await _ecrService.nakResponse(devicePort: port);

      final responseStream = await transactionExecutor(port);

      if (responseStream == null) {
        onFinished(
          EdcResponse(
            status: "ERROR",
            message: "Failed to get response stream.",
          ),
        );
        await port.close();
        return;
      }

      _portSubscription = responseStream.listen(
        (Uint8List event) async {
          String hexString = event
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join('')
              .toLowerCase();

          if (hexString == '06') {
            // ACK
            return;
          }

          if (hexString == '15') {
            // NAK
            if (_retryTransTryCount == null || _retryTransTryCount! < 2) {
              _retryTransTryCount = (_retryTransTryCount ?? 0) + 1;
              _processTransaction(port, transactionExecutor, onFinished);
            } else {
              onFinished(
                EdcResponse(
                  status: "NAK_RECEIVED",
                  message: "Transaction failed after retries.",
                ),
              );
              await _portSubscription?.cancel();
              await port.close();
            }
            return;
          }

          if (hexString.length > 100) {
            final transactionData = TransactionData.fromHexString(hexString);
            final status = transactionData.resCode ?? 'UNKNOWN';

            if (_statusPaymentEdc != status) {
              _statusPaymentEdc = status;
              onFinished(
                EdcResponse(
                  status: status,
                  message: _getResponseMessage(status),
                  data: transactionData,
                ),
              );
            }
            await port.write(ackResp);
            await _portSubscription?.cancel();
            await port.close();
            _retryTransTryCount = null;
          } else {
            onFinished(
              EdcResponse(
                status: "UNEXPECTED_RESPONSE",
                message: "Received unexpected data from device.",
              ),
            );
            await port.write(nakResp);
            await _portSubscription?.cancel();
            await port.close();
          }
        },
        onError: (error) async {
          onFinished(
            EdcResponse(status: "STREAM_ERROR", message: error.toString()),
          );
          await _portSubscription?.cancel();
          await port.close();
        },
        onDone: () async {
          if (_statusPaymentEdc == null) {
            onFinished(
              EdcResponse(
                status: "CONNECTION_LOST",
                message: "Connection to device lost before response.",
              ),
            );
          }
          await _portSubscription?.cancel();
          await port.close();
        },
      );
    } catch (e) {
      onFinished(EdcResponse(status: "ERROR", message: e.toString()));
      await port.close();
    }
  }

  // --- Public API Methods ---

  void doCreateSale({required double amount, required EdcCallback onFinished}) {
    _executeTransaction(
      (port) => _ecrService.createPaymentSale(devicePort: port, amount: amount),
      onFinished,
    );
  }

  void doCreateQris({required double amount, required EdcCallback onFinished}) {
    _executeTransaction(
      (port) => _ecrService.createPaymentQris(devicePort: port, amount: amount),
      onFinished,
    );
  }

  void doQrisInquiry({
    required String reffNum,
    required EdcCallback onFinished,
  }) {
    _executeTransaction(
      (port) => _ecrService.createPaymentQrisInquiry(
        devicePort: port,
        reffNum: reffNum,
      ),
      onFinished,
    );
  }

  void doTopUpFlazz({required double amount, required EdcCallback onFinished}) {
    _executeTransaction(
      (port) =>
          _ecrService.createPaymentTopUpFlazz(devicePort: port, amount: amount),
      onFinished,
    );
  }

  void doSettlement({required EdcCallback onFinished}) {
    _executeTransaction(
      (port) => _ecrService.settlement(devicePort: port),
      onFinished,
    );
  }

  void doEchoTest({required EdcCallback onFinished}) {
    _executeTransaction(
      (port) => _ecrService.echoTest(devicePort: port),
      onFinished,
    );
  }

  void doBalanceInquiryFlazz({required EdcCallback onFinished}) {
    _executeTransaction(
      (port) => _ecrService.balanceInquiryFlazz(devicePort: port),
      onFinished,
    );
  }

  void doCreatePaymentFlazzCard({
    required double amount,
    required EdcCallback onFinished,
  }) {
    _executeTransaction(
      (port) =>
          _ecrService.createPaymentFlazzCard(devicePort: port, amount: amount),
      onFinished,
    );
  }

  String _getResponseMessage(String statusCode) {
    switch (statusCode) {
      case '00':
        return 'Transaction Approved';
      case '54':
        return 'Expired Card';
      case '55':
        return 'Incorrect PIN';
      case 'P2':
        return 'Read Card Error';
      case 'P3':
        return 'Canceled on Terminal';
      case 'Z3':
        return 'EMV Card Not Accepted';
      case 'CE':
        return 'Connection Error';
      case 'TO':
        return 'Connection Timeout';
      case 'PT':
        return 'EDC Terminal Problem';
      case 'S2':
        return 'Transaction Failed, Please Retry on EDC';
      case 'S3':
        return 'Transaction Not Processed, Scan QR to Proceed';
      case 'S4':
        return 'Transaction Expired';
      default:
        return 'Transaction Declined';
    }
  }
}
