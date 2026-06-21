import 'package:go_router/go_router.dart';

import '../features/quiz/screens/quiz_screen.dart';
import 'home_screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/quiz', builder: (context, state) => const QuizScreen()),
  ],
);
