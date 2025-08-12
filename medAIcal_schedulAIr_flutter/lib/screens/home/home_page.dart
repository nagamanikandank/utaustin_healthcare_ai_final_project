import 'package:flutter/material.dart';
import '../../core/data/mock_data.dart';
import '../../core/models/appointment.dart';
import '../../util/date_utils.dart';
import '../../widgets/schedule_day_view.dart';
import '../../widgets/app_logo.dart';
import '../analysis/analysis_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final DateTime _monday;
  List<Appointment> _appts = [];

  @override
  void initState() {
    super.initState();
    _monday = startOfWeek(DateTime.now()); // your util returns Monday
    _tabController = TabController(length: 5, vsync: this);
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    final appts = await MockData.generateWeekAppointments(_monday);
    setState(() {
      _appts = appts;
    });
  }

  String _weekdayLabel(int i) {
    final day = _monday.add(Duration(days: i));
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    // Example label: Monday \n Aug 12
    final monthNames = [
      '', 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final md = '${monthNames[day.month]} ${day.day}';
    return '${names[i]}\n$md';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(),
        bottom: TabBar(
          controller: _tabController,
          tabs: List.generate(5, (i) {
            return Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayLabel(i).split('\n')[0], // e.g., Monday
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _weekdayLabel(i).split('\n')[1], // e.g., Aug 12
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }),
          isScrollable: false,
          indicatorWeight: 3,
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            children: [
              const ListTile(
                title: Text('medAIcal schedulAIr',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Schedule (Home)'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_graph),
                title: const Text('Analysis'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/analysis');
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (i) {
          final day = _monday.add(Duration(days: i));
          final appts = _appts
              .where((a) => isSameDay(a.start, day))
              .toList()
            ..sort((a, b) => a.start.compareTo(b.start));
          return ScheduleDayView(day: day, appointments: appts);
        }),
      ),
    );
  }
}
