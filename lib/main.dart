import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/categories_screen.dart';
import 'screens/daily_screen.dart';
import 'screens/home_screen.dart';
import 'screens/summary_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  runApp(MoneyApp(store: store));
}

class MoneyApp extends StatelessWidget {
  final AppStore store;
  const MoneyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'บันทึกรายรับรายจ่าย',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('th', 'TH'),
        supportedLocales: const [Locale('th', 'TH'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  DateTime _date = dateOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    // ปุ่มย้อนกลับ (Android): ถ้าอยู่แท็บอื่น ให้กลับหน้าหลักก่อนออกจากแอป
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onOpenTab: (i) => setState(() => _index = i)),
            DailyScreen(
              date: _date,
              onDateChanged: (d) => setState(() => _date = dateOnly(d)),
            ),
            SummaryScreen(
              onOpenDay: (d) => setState(() {
                _date = dateOnly(d);
                _index = 1;
              }),
            ),
            const CategoriesScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'หน้าหลัก'),
            NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: 'รายวัน'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: 'รายเดือน'),
            NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'หมวดหมู่'),
          ],
        ),
      ),
    );
  }
}
