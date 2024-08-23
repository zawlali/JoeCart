import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

Future<void> sendTelegramMessage() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  final botToken = '7366522858:AAHVh-RoG63PxiuPSJ3DiCaT9m2DQCqgyVQ';
  final chatId = '@JoeCartHelp';
  final message = 'User is requesting assistance';

  final url =
      'https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$message';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print('Message sent successfully');
    } else {
      print('Failed to send message. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending message: $e');
  }
}
