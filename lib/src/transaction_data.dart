import 'ecr_utils.dart';

class TransactionData {
  final String? stx;
  final String? messageLength;
  final String? ecrVer;
  final String? transType;
  final String? transAmount;
  final String? otherAmount;
  final String? pan;
  final String? expiredDate;
  final String? resCode;
  final String? rrn;
  final String? approvalCode;
  final String? transDate;
  final String? transTime;
  final String? merchantId;
  final String? terminalId;
  final String? offlineFlag;
  final String? cardHolder;
  final String? panCashierCard;
  final String? invoiceNumber;
  final String? batchNumber;
  final String? issuerId;
  final String? installmentFlag;
  final String? dccFlag;
  final String? rewardFlag;
  final String? infoAmount;
  final String? dccDecimalPlace;
  final String? dccCurrencyName;
  final String? dccExchangeRate;
  final String? couponFlag;
  final String? filler;
  final String? etx;
  final String? crc;

  TransactionData({
    this.stx,
    this.messageLength,
    this.ecrVer,
    this.transType,
    this.transAmount,
    this.otherAmount,
    this.pan,
    this.expiredDate,
    this.resCode,
    this.rrn,
    this.approvalCode,
    this.transDate,
    this.transTime,
    this.merchantId,
    this.terminalId,
    this.offlineFlag,
    this.cardHolder,
    this.panCashierCard,
    this.invoiceNumber,
    this.batchNumber,
    this.issuerId,
    this.installmentFlag,
    this.dccFlag,
    this.rewardFlag,
    this.infoAmount,
    this.dccDecimalPlace,
    this.dccCurrencyName,
    this.dccExchangeRate,
    this.couponFlag,
    this.filler,
    this.etx,
    this.crc,
  });

  factory TransactionData.fromHexString(String hexString) {
    String? parse(int start, int length) {
      if (hexString.length >= start + length) {
        final hex = EcrUtils.substringFromIndex(hexString, start, length);
        return EcrUtils.hexToAscii(hex).trim();
      }
      return null;
    }

    return TransactionData(
      stx: parse(0, 2),
      messageLength: parse(2, 4),
      ecrVer: parse(6, 2),
      transType: parse(8, 4),
      transAmount: parse(12, 24),
      otherAmount: parse(36, 24),
      pan: parse(60, 38),
      expiredDate: parse(98, 8),
      resCode: parse(106, 4),
      rrn: parse(110, 24),
      approvalCode: parse(134, 12),
      transDate: parse(146, 16),
      transTime: parse(162, 12),
      merchantId: parse(174, 30),
      terminalId: parse(204, 16),
      offlineFlag: parse(220, 2),
      cardHolder: parse(222, 52),
      panCashierCard: parse(274, 32),
      invoiceNumber: parse(306, 12),
      batchNumber: parse(318, 12),
      issuerId: parse(330, 4),
      installmentFlag: parse(334, 2),
      dccFlag: parse(336, 2),
      rewardFlag: parse(338, 2),
      infoAmount: parse(340, 24),
      dccDecimalPlace: parse(364, 2),
      dccCurrencyName: parse(366, 6),
      dccExchangeRate: parse(372, 16),
      couponFlag: parse(388, 2),
      filler: parse(390, 16),
      etx: parse(406, 2),
      crc: parse(408, 2),
    );
  }
}
