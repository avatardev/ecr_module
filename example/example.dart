import 'package:ecr_module/ecr_module.dart';

void main() {
  print('Initializing ECR Payment Module...');
  final ecrModule = EcrPaymentModule();

  // --- Example 1: Create a Sale Transaction ---
  print('Starting a sale transaction for Rp 15.000...');
  ecrModule.doCreateSale(
    amount: 15000,
    onFinished: (response) {
      print('\n--- Sale Transaction Finished ---');
      print('Status: ${response.status}');
      print('Message: ${response.message}');
      if (response.data != null) {
        print('Invoice Number: ${response.data?.invoiceNumber}');
      }
      print('---------------------------------\n');
    },
  );

  print('\nWaiting for EDC response...\n');

  // --- Other Examples (uncomment to use) ---

  /*
  // --- Example 2: Create a QRIS Transaction ---
  print('Starting a QRIS transaction for Rp 20.000...');
  ecrModule.doCreateQris(
    amount: 20000,
    onFinished: (response) {
      print('\n--- QRIS Transaction Finished ---');
      print('Status: ${response.status}');
      print('Message: ${response.message}');
      if (response.data != null) {
        print('Data: ${response.data}');
      }
      print('---------------------------------\n');
    },
  );
  */

  /*
  // --- Example 3: Perform a Settlement ---
  print('Starting a settlement...');
  ecrModule.doSettlement(
    onFinished: (response) {
      print('\n--- Settlement Finished ---');
      print('Status: ${response.status}');
      print('Message: ${response.message}');
      if (response.data != null) {
        print('Data: ${response.data}');
      }
      print('---------------------------\n');
    },
  );
  */

  /*
  // --- Example 4: Perform an Echo Test ---
  print('Starting an echo test...');
  ecrModule.doEchoTest(
    onFinished: (response) {
      print('\n--- Echo Test Finished ---');
      print('Status: ${response.status}');
      print('Message: ${response.message}');
      if (response.data != null) {
        print('Data: ${response.data}');
      }
      print('--------------------------\n');
    },
  );
  */
}
