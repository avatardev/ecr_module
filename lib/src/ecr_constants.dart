class EcrConstants {
  // ECR Versions
  static const String ecrVer01 = '01';
  static const String ecrVer03 = '03';

  // Transaction Types
  static const String transTypeQris = '31';
  static const String transTypeQrisInquiry = '32';
  static const String transTypeSale = '01';
  static const String transTypeTopUpFlazz = '21';
  static const String transTypeSettlement = '10';
  static const String transTypeEchoTest = '17';
  static const String transTypeBalanceInquiryFlazz = '36';
  static const String transTypeFlazzCard = '06';

  // Default Card Info
  static const String defaultPan = '5432480089691688';
  static const String defaultExpiryDate = '2806';
  static const String expiryDateForTest = '0';

  // Flags
  static const String dccFlagNo = 'N';

  // Message constants
  static const String messageLength = '0150';
}
