import 'bootstrap/bootstrap.dart';
import 'app/gong_mu_talk_app.dart';

Future<void> main() async {
  await bootstrap(() => const GongMuTalkApp());
}
