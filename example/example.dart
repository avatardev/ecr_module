import 'package:ecr_module/ecr_module.dart';
import 'package:ecr_module/src/payment_service_ecr.dart';
import 'package:usb_serial/usb_serial.dart';

// Mock EDC Response Callback for demonstration
class MockEdcResponseCallback implements EdcResponseCallback {
  @override
  void onNegativeError(arg) {
    print('Negative Error: $arg');
  }

  @override
  void onNegativeErrorCode54(arg) {
    print('Negative Error Code 54: $arg');
  }

  @override
  void onNegativeErrorCode55(arg) {
    print('Negative Error Code 55: $arg');
  }

  @override
  void onNegativeErrorCodeCE(arg) {
    print('Negative Error Code CE: $arg');
  }

  @override
  void onNegativeErrorCodeP2(arg) {
    print('Negative Error Code P2: $arg');
  }

  @override
  void onNegativeErrorCodeP3(arg) {
    print('Negative Error Code P3: $arg');
  }

  @override
  void onNegativeErrorCodePT(arg) {
    print('Negative Error Code PT: $arg');
  }

  @override
  void onNegativeErrorCodeS2(arg) {
    print('Negative Error Code S2: $arg');
  }

  @override
  void onNegativeErrorCodeS3(arg) {
    print('Negative Error Code S3: $arg');
  }

  @override
  void onNegativeErrorCodeS4(arg) {
    print('Negative Error Code S4: $arg');
  }

  @override
  void onNegativeErrorCodeTO(arg) {
    print('Negative Error Code TO: $arg');
  }

  @override
  void onNegativeErrorCodeZ3(arg) {
    print('Negative Error Code Z3: $arg');
  }

  @override
  void onPositiveError(arg) {
    print('Positive Error: $arg');
  }

  @override
  void onPositiveErrorCode54(arg) {
    print('Positive Error Code 54: $arg');
  }

  @override
  void onPositiveErrorCode55(arg) {
    print('Positive Error Code 55: $arg');
  }

  @override
  void onPositiveErrorCodeCE(arg) {
    print('Positive Error Code CE: $arg');
  }

  @override
  void onPositiveErrorCodeP2(arg) {
    print('Positive Error Code P2: $arg');
  }

  @override
  void onPositiveErrorCodeP3(arg) {
    print('Positive Error Code P3: $arg');
  }

  @override
  void onPositiveErrorCodePT(arg) {
    print('Positive Error Code PT: $arg');
  }

  @override
  void onPositiveErrorCodeS2(arg) {
    print('Positive Error Code S2: $arg');
  }

  @override
  void onPositiveErrorCodeS3(arg) {
    print('Positive Error Code S3: $arg');
  }

  @override
  void onPositiveErrorCodeS4(arg) {
    print('Positive Error Code S4: $arg');
  }

  @override
  void onPositiveErrorCodeTO(arg) {
    print('Positive Error Code TO: $arg');
  }

  @override
  void onPositiveErrorCodeZ3(arg) {
    print('Positive Error Code Z3: $arg');
  }

  @override
  void onSuccessCode00(arg) {
    print('Success Code 00: $arg');
  }
}

void main() async {
  // 1. Initialize the payment service
  final ecrService = PaymentServiceEcr();

  print('Mencari perangkat USB...');

  // 2. Get a list of available USB devices
  // In a real application, you would present this list to the user
  // so they can select the correct EDC terminal.
  List<UsbDevice> devices = await ecrService.getUsbDevices();

  if (devices.isEmpty) {
    print('Tidak ada perangkat USB yang terdeteksi.');
    return;
  }

  print('Perangkat ditemukan: ${devices.length}');
  for (var device in devices) {
    print('  - Device: ${device.deviceName}, Product: ${device.productName}');
  }

  // For this example, we'll just use the first device found.
  UsbDevice selectedDevice = devices.first;

  // 3. Connect to the selected device
  // This creates and opens a UsbPort.
  UsbPort? devicePort;
  try {
    print('\nMenyambungkan ke ${selectedDevice.productName}...');
    devicePort = await ecrService.connectDevices(selectedDevice);

    if (devicePort == null) {
      print('Gagal menyambungkan ke perangkat.');
      return;
    }

    print('Berhasil tersambung.');

    // 4. Listen for responses from the device
    // The stream will emit data whenever the EDC sends a response.
    devicePort.inputStream?.listen((data) {
      // Here you would parse the response from the EDC.
      // The response format depends on the EDC machine's protocol.
      // You would then call the appropriate method on your EdcResponseCallback.
      print('Data diterima: $data');

      // Example of handling a response:
      // final response = parseEdcResponse(data);
      // handleResponse(response, MockEdcResponseCallback());
    });

    // 5. Initiate a payment (e.g., QRIS payment for Rp 10.000)
    // This sends a command to the EDC machine.
    print('\nMemulai pembayaran QRIS sebesar Rp 10.000...');
    await ecrService.createPaymentQris(devicePort: devicePort, amount: 10000);

    // The EDC machine will now process the payment.
    // The result will be sent back through the inputStream we are listening to.

    // Add a delay to keep the example running and listening for responses.
    await Future.delayed(const Duration(seconds: 10));

  } catch (e) {
    print('Terjadi error: $e');
  } finally {
    // 6. Disconnect from the device when done
    if (devicePort != null) {
      print('\nMemutuskan sambungan...');
      await ecrService.disconnectDevices(devicePort);
      print('Sambungan terputus.');
    }
  }
}
