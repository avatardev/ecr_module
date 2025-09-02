import 'dart:async';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

abstract class EcrService {
  Future<List<UsbDevice>> getUsbDevices();
  Future<void> initDevice(UsbDevice device);
  Future<UsbPort?> connectDevices(UsbDevice device);
  Future<void> disconnectDevices(UsbPort devicePort);
  Future<Stream<Uint8List>?> createPaymentSale({
    required UsbPort devicePort,
    required int amount,
  });
  Future<Stream<Uint8List>?> createPaymentQris({
    required UsbPort devicePort,
    required int amount,
  });
  Future<Stream<Uint8List>?> createPaymentQrisInquiry({
    required UsbPort devicePort,
    required String reffNum,
  });
  Future<Stream<Uint8List>?> createPaymentTopUpFlazz({
    required UsbPort devicePort,
    required int amount,
  });

  Future<Stream<Uint8List>?> settlement({required UsbPort devicePort});

  Future<Stream<Uint8List>?> echoTest({required UsbPort devicePort});

  Future<Stream<Uint8List>?> balanceInquiryFlazz({required UsbPort devicePort});

  Future<Stream<Uint8List>?> createPaymentFlazzCard({
    required UsbPort devicePort,
    required int amount,
  });
}
