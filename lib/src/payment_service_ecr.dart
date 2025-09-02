import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import 'ecr_constants.dart';
import 'ecr_service.dart';
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

  Future<Stream<Uint8List>?> _sendMessage({
    required UsbPort devicePort,
    required String ecrVer,
    required String transType,
    String amount = '0',
    String pan = '',
    String expiryDate = '',
    String reffNum = '',
    String dCCFlag = EcrConstants.dccFlagNo,
  }) async {
    final transTypeHex = EcrUtils.asciiToHex(transType);
    final transAmountHex = EcrUtils.asciiToHex(
      EcrUtils.padWithZero(amount),
      lineLength: 12,
      padFilter: '0',
    );
    final otherAmountHex = EcrUtils.asciiToHex(
      '',
      lineLength: 12,
      padFilter: '0',
    );
    final panHex = EcrUtils.asciiToHex(pan, lineLength: 19);

    final expiryDateHex =
        (transType == EcrConstants.transTypeEchoTest ||
            transType == EcrConstants.transTypeBalanceInquiryFlazz)
        ? EcrUtils.asciiToHex(expiryDate, lineLength: 4, padFilter: '0')
        : EcrUtils.asciiToHex(expiryDate);

    final cancelReasonHex = EcrUtils.asciiToHex(
      '',
      lineLength: 2,
      padFilter: '0',
    );
    final invoiceNumberHex = EcrUtils.asciiToHex(
      '',
      lineLength: 6,
      padFilter: '0',
    );
    final authCodeHex = EcrUtils.asciiToHex('', lineLength: 6, padFilter: '0');
    final installmentFlagHex = EcrUtils.asciiToHex('', lineLength: 1);
    final redeemFlagHex = EcrUtils.asciiToHex('', lineLength: 1);
    final dCCFlagHex = EcrUtils.asciiToHex(dCCFlag);
    final installmentPlanHex = EcrUtils.asciiToHex(
      '',
      lineLength: 3,
      padFilter: '0',
    );
    final installmentTenorHex = EcrUtils.asciiToHex(
      '',
      lineLength: 2,
      padFilter: '0',
    );
    final genericDataHex = EcrUtils.asciiToHex('', lineLength: 12);
    final reffNumberHex = EcrUtils.asciiToHex(reffNum, lineLength: 12);
    final originalDateHex = EcrUtils.asciiToHex('', lineLength: 4);
    final bcaFillerHex = EcrUtils.asciiToHex('', lineLength: 50);

    final data =
        (ecrVer +
                transTypeHex +
                transAmountHex +
                otherAmountHex +
                panHex +
                expiryDateHex +
                cancelReasonHex +
                invoiceNumberHex +
                authCodeHex +
                installmentFlagHex +
                redeemFlagHex +
                dCCFlagHex +
                installmentPlanHex +
                installmentTenorHex +
                genericDataHex +
                reffNumberHex +
                originalDateHex +
                bcaFillerHex)
            .replaceAll(" ", ""); // Message payload

    final stx = String.fromCharCode(0x02);
    final etx = String.fromCharCode(0x03);

    final messageLength = EcrConstants.messageLength; // Length of data

    // Calculate LRC
    final lrc = EcrUtils.binToHex(
      EcrUtils.modSumAcrossRows(
        EcrUtils.hexToBinList('$messageLength$data${EcrUtils.asciiToHex(etx)}'),
      ),
    );

    // Create the final message
    final hexData =
        "${EcrUtils.asciiToHex(stx)}$messageLength$data${EcrUtils.asciiToHex(etx)}$lrc";

    // Kirim data ke Ingenico Move 2500 melalui konverter
    final binaryData = EcrUtils.hexToBytes(hexData);
    await devicePort.write(Uint8List.fromList(binaryData));

    // Tunggu balasan (opsional)
    return devicePort.inputStream;
  }

  @override
  Future<Stream<Uint8List>?> createPaymentQris({
    required UsbPort devicePort,
    required double amount,
  }) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeQris,
      amount: amount.toString(),
    );
  }

  @override
  Future<Stream<Uint8List>?> createPaymentQrisInquiry({
    required UsbPort devicePort,
    required String reffNum,
  }) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeQrisInquiry,
      reffNum: reffNum,
    );
  }

  @override
  Future<Stream<Uint8List>?> createPaymentSale({
    required UsbPort devicePort,
    required double amount,
  }) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer01,
      transType: EcrConstants.transTypeSale,
      amount: amount.toString(),
    );
  }

  @override
  Future<Stream<Uint8List>?> createPaymentTopUpFlazz({
    required UsbPort devicePort,
    required double amount,
  }) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeTopUpFlazz,
      amount: amount.toString(),
    );
  }

  @override
  Future<Stream<Uint8List>?> settlement({required UsbPort devicePort}) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeSettlement,
    );
  }

  @override
  Future<Stream<Uint8List>?> echoTest({required UsbPort devicePort}) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeEchoTest,
    );
  }

  @override
  Future<Stream<Uint8List>?> balanceInquiryFlazz({
    required UsbPort devicePort,
  }) async {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeBalanceInquiryFlazz,
    );
  }

  @override
  Future<Uint8List> ackResponse({required UsbPort devicePort}) async {
    String ack = String.fromCharCode(0x06);
    List<int> binaryData = EcrUtils.hexToBytes(EcrUtils.asciiToHex(ack));
    return Uint8List.fromList(binaryData);
  }

  @override
  Future<Uint8List> nakResponse({required UsbPort devicePort}) async {
    String nak = String.fromCharCode(0x15);
    List<int> binaryData = EcrUtils.hexToBytes(EcrUtils.asciiToHex(nak));
    return Uint8List.fromList(binaryData);
  }

  @override
  Future<Stream<Uint8List>?> createPaymentFlazzCard({
    required devicePort,
    required double amount,
  }) {
    return _sendMessage(
      devicePort: devicePort,
      ecrVer: EcrConstants.ecrVer03,
      transType: EcrConstants.transTypeFlazzCard,
      amount: amount.toString(),
    );
  }
}
