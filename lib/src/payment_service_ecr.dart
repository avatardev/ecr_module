import 'dart:async';
import 'dart:typed_data';

import 'package:ecr_bca/ecr_service.dart';
import 'package:usb_serial/usb_serial.dart';

import 'ecr_utils.dart';

class PaymentServiceEcr extends EcrService {
  @override
  Future<List<UsbDevice>> getUsbDevices() async {
    List<UsbDevice> devices = await UsbSerial.listDevices();
    if (devices.isEmpty) return [];
    return devices;
  }

  @override
  Future<void> initDevice(UsbDevice device) async {
    final devicePort = await connectDevices(device);
    if (devicePort != null) await disconnectDevices(devicePort);
  }

  @override
  Future<UsbPort?> connectDevices(UsbDevice device) async {
    final UsbPort? port = await device.create();
    await port?.open();
    return port;
  }

  @override
  Future<void> disconnectDevices(UsbPort devicePort) async {
    await devicePort.close();
  }

  @override
  Future<Stream<Uint8List>?> createPaymentQris({
    required UsbPort devicePort,
    required int amount,
  }) async {
    // Prepare the data
    String ecrVer = "03";
    String transType = EcrUtils.asciiToHex('31');
    String transAmount = EcrUtils.asciiToHex(
        EcrUtils.padWithZero(amount.toString()),
        lineLength: 12,
        padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex('', lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> createPaymentQrisInquiry({
    required UsbPort devicePort,
    required String reffNum,
  }) async {
    // Prepare the data
    String ecrVer = '03';
    String transType = EcrUtils.asciiToHex('32');
    String transAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex(reffNum, lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> createPaymentSale({
    required UsbPort devicePort,
    required int amount,
  }) async {
    // Prepare the data
    String ecrVer = '01';
    String transType = EcrUtils.asciiToHex('01');
    String transAmount = EcrUtils.asciiToHex(
        EcrUtils.padWithZero(amount.toString()),
        lineLength: 12,
        padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('5432480089691688', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('2806');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex('', lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> createPaymentTopUpFlazz({
    required UsbPort devicePort,
    required int amount,
  }) async {
    // Prepare the data
    String ecrVer = '03';
    String transType = EcrUtils.asciiToHex('21');
    String transAmount = EcrUtils.asciiToHex(
        EcrUtils.padWithZero(amount.toString()),
        lineLength: 12,
        padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('5432480089691688', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('2806');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex('', lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> settlement({required UsbPort devicePort}) async {
    // Prepare the data
    String ecrVer = '03';
    String transType = EcrUtils.asciiToHex('10');
    String transAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('5432480089691688', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('2806');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex('', lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> echoTest({required UsbPort devicePort}) async {
    // Prepare the data
    String ecrVer = '03';
    String transType = EcrUtils.asciiToHex('17');
    String transAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('0', lineLength: 4, padFilter: '0');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex('', lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> balanceInquiryFlazz(
      {required UsbPort devicePort}) async {
    // Prepare the data
    String ecrVer = '03';
    String transType = EcrUtils.asciiToHex('36');
    String transAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String otherAmount =
        EcrUtils.asciiToHex('0', lineLength: 12, padFilter: '0');
    String pan = EcrUtils.asciiToHex('', lineLength: 19);
    String expiryDate = EcrUtils.asciiToHex('0', lineLength: 4, padFilter: '0');
    String cancelReason =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String invoiceNumber =
        EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String authCode = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    String installmentFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String redeemFlag = EcrUtils.asciiToHex('', lineLength: 1);
    String dCCFlag = EcrUtils.asciiToHex('N');
    String installmentPlan =
        EcrUtils.asciiToHex('', lineLength: 3, padFilter: '0');
    String installmentTenor =
        EcrUtils.asciiToHex('', lineLength: 2, padFilter: '0');
    String genericData = EcrUtils.asciiToHex('', lineLength: 12);
    String reffNumber = EcrUtils.asciiToHex('', lineLength: 12);
    String originalDate = EcrUtils.asciiToHex('', lineLength: 4);
    String bcaFiller = EcrUtils.asciiToHex('', lineLength: 50);

    String data = (ecrVer +
            transType +
            transAmount +
            otherAmount +
            pan +
            expiryDate +
            cancelReason +
            invoiceNumber +
            authCode +
            installmentFlag +
            redeemFlag +
            dCCFlag +
            installmentPlan +
            installmentTenor +
            genericData +
            reffNumber +
            originalDate +
            bcaFiller)
        .replaceAll(" ", ""); // Message payload

    String stx = String.fromCharCode(0x02);
    String etx = String.fromCharCode(0x03);

    String messageLength = '0150'; // Length of data

    // Calculate LRC
    String lrc = EcrUtils.binToHex(EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList(
            '$messageLength$data${EcrUtils.asciiToHex(etx)}')));

    // Create the final message
    String hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    List<int> binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }
}
