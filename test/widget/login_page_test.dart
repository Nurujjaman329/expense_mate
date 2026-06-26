import 'package:expense_mate/core/errors/failures.dart';
import 'package:expense_mate/core/errors/result.dart';
import 'package:expense_mate/core/services/local_storage_service.dart';
import 'package:expense_mate/core/theme/app_theme.dart';
import 'package:expense_mate/features/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LoginPage renders email and password fields', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextFormField), findsAtLeast(2));
  });

  test('Result Success holds data', () {
    const result = Success<String>('test');
    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull, 'test');
  });

  test('Result Error holds failure', () {
    const result = Error<String>(AuthFailure(message: 'failed'));
    expect(result.isFailure, isTrue);
    expect(result.dataOrNull, isNull);
  });
}
