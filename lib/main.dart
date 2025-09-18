import 'package:flutter/widgets.dart';

import 'bootstrap/bootstrap.dart';
import 'app/gong_mu_talk_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(() => const GongMuTalkApp());
}
