import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hishabify/core/security/app_lock_view.dart';

void main() {
  testWidgets(
    'Navigator stack is preserved when locked with Stack builder overlay',
    (tester) async {
      bool isLocked = false;
      late StateSetter setLockedState;

      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            setLockedState = setState;
            return MaterialApp(
              navigatorKey: navKey,
              home: Scaffold(
                body: const Text('Home Screen'),
                floatingActionButton: Builder(
                  builder: (ctx) => FloatingActionButton(
                    onPressed: () {
                      Navigator.of(ctx).push(
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: Text('Detail Screen In Stack'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              builder: (context, child) {
                if (child == null) return const SizedBox.shrink();
                return Stack(
                  children: [
                    IgnorePointer(
                      ignoring: isLocked,
                      child: ExcludeSemantics(
                        excluding: isLocked,
                        child: child,
                      ),
                    ),
                    if (isLocked)
                      Positioned.fill(
                        child: PopScope(
                          canPop: false,
                          child: AppLockView(onUnlockPressed: () {}),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify Home Screen is present
      expect(find.text('Home Screen'), findsOneWidget);

      // Push Detail Screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify Detail Screen is now showing
      expect(find.text('Detail Screen In Stack'), findsOneWidget);

      // Now simulate app locking (minimizing and setting isLocked = true)
      setLockedState(() {
        isLocked = true;
      });
      await tester.pump();

      // AppLockView should now be visible on top
      expect(find.byType(AppLockView), findsOneWidget);
      expect(find.text('Hishabify Locked'), findsOneWidget);

      // Detail Screen is still alive in the tree behind the lock
      expect(find.text('Detail Screen In Stack'), findsOneWidget);

      // Now unlock
      setLockedState(() {
        isLocked = false;
      });
      await tester.pumpAndSettle();

      // AppLockView is gone
      expect(find.byType(AppLockView), findsNothing);

      // Detail Screen is STILL on top, NOT kicked back to Home Screen
      expect(find.text('Detail Screen In Stack'), findsOneWidget);
    },
  );
}
