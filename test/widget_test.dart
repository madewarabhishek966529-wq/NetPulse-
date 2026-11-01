import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse/core/theme/app_colors.dart';
import 'package:netpulse/features/dashboard/widgets/stat_card.dart';
import 'package:netpulse/widgets/status_badge.dart';
import 'package:netpulse/models/download_item.dart';

void main() {
  testWidgets('StatCard renders title, value, and subtitle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatCard(
            title: 'Current Speed',
            value: '12.5 MB/s',
            subtitle: '8 active connections',
            icon: Icons.speed_rounded,
            accentColor: AppColors.electricBlue,
          ),
        ),
      ),
    );

    expect(find.text('Current Speed'), findsOneWidget);
    expect(find.text('12.5 MB/s'), findsOneWidget);
    expect(find.text('8 active connections'), findsOneWidget);
  });

  testWidgets('StatusBadge renders appropriate label and icon for active status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: DownloadStatus.active),
        ),
      ),
    );

    expect(find.text('Downloading'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
  });

  testWidgets('StatusBadge renders appropriate label for completed status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: DownloadStatus.completed),
        ),
      ),
    );

    expect(find.text('Completed'), findsOneWidget);
  });
}
