import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'select_floor_screen.dart';

class SetPulseScreen extends StatefulWidget {
  const SetPulseScreen({Key? key}) : super(key: key);

  @override
  State<SetPulseScreen> createState() => _SetPulseScreenState();
}

class _SetPulseScreenState extends State<SetPulseScreen> {
  final Map<String, int> buildingsWithFloors = {
    'Central Library Building': 4,
    'Academic 1': 5,
    'Academic 2': 10,
    'Academic 3': 3,
    'Auditorium Building': 5,
    'Proshashonic Building': 5,
    'Bibi Khadiza Hall': 4,
    'July Shahid Smriti Chatri Hall': 5,
    'Nowab Faizunnesa Chowdhurani Hall': 5,
    'Abdul Malek Ukil Hall': 5,
    'Abdus Salam Hall': 4,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2D7BF2),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: const [
            Icon(Icons.business, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Text(
              'Select Building',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: isDark ? const Color(0xFF0F1115) : const Color(0xFFF5F8FA),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: buildingsWithFloors.length,
                itemBuilder: (context, index) {
                  final buildingName = buildingsWithFloors.keys.elementAt(index);
                  final floorCount = buildingsWithFloors[buildingName]!;
                  return _buildingTile(
                    buildingName,
                    isDark,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SelectFloorScreen(
                            buildingName: buildingName,
                            floorCount: floorCount,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D7BF2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildingTile(String name, bool isDark, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF2D7BF2).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.business,
            color: Color(0xFF2D7BF2),
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Color(0xFF2D7BF2),
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}
