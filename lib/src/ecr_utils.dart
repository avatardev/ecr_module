import 'dart:convert';
import 'dart:typed_data';

class EcrUtils {
  static String padWithZero(String input, [int length = 10]) {
    // Jika panjang string sudah lebih dari atau sama dengan panjang yang diinginkan, kembalikan string seperti adanya
    if (input.length >= length) {
      return input;
    }

    // Tambahkan '0' di depan hingga mencapai panjang yang diinginkan
    return input.padLeft(length, '0');
  }

  static List<String> hexToBinList(String hex) {
    // Hapus karakter '0x' jika ada
    hex = hex.replaceAll('0x', '');

    // Jika string HEX memiliki panjang ganjil, tambahkan '0' di depan
    if (hex.length % 2 != 0) {
      hex = '0$hex';
    }

    // Mengonversi setiap pasangan karakter HEX menjadi byte dan mengubahnya menjadi binary string
    List<String> binaryList = [];

    for (int i = 0; i < hex.length; i += 2) {
      String byteHex = hex.substring(i, i + 2); // Ambil 2 karakter dari HEX
      int byteValue = int.parse(byteHex, radix: 16); // Ubah HEX ke integer
      String binaryString = byteValue
          .toRadixString(2)
          .padLeft(8, '0'); // Ubah integer ke biner dengan padding
      binaryList.add(binaryString); // Tambahkan ke daftar binary
    }

    return binaryList; // Kembalikan daftar binary
  }

  static String modSumAcrossRows(List<String> binaryList) {
    if (binaryList.isEmpty) return '';

    // Panjang biner berdasarkan baris pertama
    int length = binaryList[0].length;

    // Inisialisasi daftar untuk menghitung jumlah bit per posisi
    List<int> bitSums = List.filled(length, 0);

    // Jumlahkan bit di setiap posisi
    for (String binary in binaryList) {
      for (int i = 0; i < length; i++) {
        if (binary[i] == '1') {
          bitSums[i]++;
        }
      }
    }

    // Hitung mod 2 untuk setiap posisi dan gabungkan menjadi string
    String result = bitSums.map((sum) => (sum % 2).toString()).join('');

    return result;
  }

  static String binToHex(String binary) {
    // Pastikan panjang biner adalah kelipatan dari 4
    int paddingLength = (4 - (binary.length % 4)) % 4;
    String paddedBinary = binary.padLeft(binary.length + paddingLength, '0');

    // Daftar untuk hasil hexadecimal
    StringBuffer hexResult = StringBuffer();

    // Iterasi setiap 4-bit untuk konversi ke hexadecimal
    for (int i = 0; i < paddedBinary.length; i += 4) {
      String nibble = paddedBinary.substring(i, i + 4);
      int decimalValue = int.parse(nibble, radix: 2);
      hexResult.write(decimalValue.toRadixString(16).toUpperCase());
    }

    // Hapus awalan nol jika ada
    return hexResult.toString();
  }

  static String substringFromIndex(String str, int start, int length) {
    if (start < 0 || start >= str.length) {
      throw ArgumentError('Index start is out of bounds');
    }
    return str.substring(
      start,
      (start + length) > str.length ? str.length : (start + length),
    );
  }

  // Fungsi untuk mengonversi data hex ke format biner
  static List<int> hexToBytes(String hex) {
    final bytes = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      final byte = hex.substring(i, i + 2);
      bytes.add(int.parse(byte, radix: 16));
    }
    return bytes;
  }

  static String asciiToHex(
    String input, {
    int? lineLength,
    String padFilter = ' ',
  }) {
    // Tambahkan spasi jika panjang input kurang dari lineLength
    String paddedInput = input.padRight(lineLength ?? 0, padFilter);

    // Konversi setiap karakter ASCII dari paddedInput ke hexadecimal
    String hexData = paddedInput
        .split('')
        .map((char) => char.codeUnitAt(0).toRadixString(16).padLeft(2, '0'))
        .join(' ');

    return hexData.toUpperCase();
  }

  static String hexToAscii(String hexString) {
    // Helper function to convert hex string to bytes
    Uint8List hexToBytes(String hex) {
      final bytes = <int>[];
      for (int i = 0; i < hex.length; i += 2) {
        final byte = hex.substring(i, i + 2);
        bytes.add(int.parse(byte, radix: 16));
      }
      return Uint8List.fromList(bytes);
    }

    // Convert hex to bytes
    Uint8List bytes = hexToBytes(hexString);

    // Convert bytes to ASCII characters
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String calculateLrc(String message) {
    // Remove the STX and ETX characters if present
    // STX (Start of Text) character is usually 0x02
    // ETX (End of Text) character is usually 0x03
    if (message.startsWith('02')) {
      message = message.substring(2); // Remove STX
    }
    if (message.endsWith('03')) {
      message = message.substring(0, message.length - 2); // Remove ETX
    }

    // Convert the message to bytes
    List<int> bytes = hexToBytes(message);

    // Calculate LRC with XOR
    int lrc = 0;
    for (int byte in bytes) {
      lrc ^= byte;
    }

    // Convert LRC to hexadecimal format
    return lrc.toRadixString(16).toUpperCase().padLeft(2, '0');
  }
}
