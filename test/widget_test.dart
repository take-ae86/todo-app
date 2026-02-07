import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_calendar/main.dart';
import 'package:task_calendar/providers/app_provider.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const TaskCalendarApp(),
      ),
    );
    expect(find.text('TODOアプリ'), findsOneWidget);
  });
}
