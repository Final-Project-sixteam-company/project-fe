// lib/controllers/game_session_provider.dart
import 'package:flutter/widgets.dart';
import 'game_session_controller.dart';

/// InheritedNotifier: CaseScreen 트리 전체에서 GameSessionController 접근
class GameSessionProvider
    extends InheritedNotifier<GameSessionController> {
  const GameSessionProvider({
    required GameSessionController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// context.session — 어느 자식 위젯에서도 호출 가능
  static GameSessionController of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<GameSessionProvider>();
    assert(
    provider != null,
    'GameSessionProvider를 찾을 수 없습니다. '
        'CaseScreen 위에 GameSessionProvider가 있는지 확인하세요.',
    );
    return provider!.notifier!;
  }

  /// 리빌드 없이 읽기만 할 때
  static GameSessionController read(BuildContext context) {
    final provider = context
        .findAncestorWidgetOfExactType<GameSessionProvider>();
    assert(provider != null, 'GameSessionProvider not found.');
    return provider!.notifier!;
  }
}

extension GameSessionX on BuildContext {
  GameSessionController get session => GameSessionProvider.of(this);
  GameSessionController get sessionRead =>
      GameSessionProvider.read(this);
}