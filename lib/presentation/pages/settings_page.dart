// presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Use TextEditingController to save the value
  final TextEditingController _temperatureThresholdController = TextEditingController();
  final TextEditingController _humidityThresholdController = TextEditingController();
  final TextEditingController _pressureThresholdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _temperatureThresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Temperature Threshold (°C)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _humidityThresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Humidity Threshold (%)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pressureThresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pressure Threshold (hPa)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveThresholds,
              child: const Text('Save Thresholds'),
            ),
          ],
        ),
      ),
    );
  }
    // Function for loading thresholds
    Future<void> _loadThresholds() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _temperatureThresholdController.text = (prefs.getDouble('temperatureThreshold') ?? 0.0).toString();
        _humidityThresholdController.text = (prefs.getDouble('humidityThreshold') ?? 0.0).toString();
        _pressureThresholdController.text = (prefs.getDouble('pressureThreshold') ?? 0.0).toString();
      });
    }

  // Function for saving thresholds
  Future<void> _saveThresholds() async {
      final prefs = await SharedPreferences.getInstance();
      double temperatureThreshold = double.tryParse(_temperatureThresholdController.text) ?? 0.0;
      double humidityThreshold = double.tryParse(_humidityThresholdController.text) ?? 0.0;
      double pressureThreshold = double.tryParse(_pressureThresholdController.text) ?? 0.0;

      await prefs.setDouble('temperatureThreshold', temperatureThreshold);
      await prefs.setDouble('humidityThreshold', humidityThreshold);
      await prefs.setDouble('pressureThreshold', pressureThreshold);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thresholds saved!')),
      );
    }

  @override
  void dispose() {
    _temperatureThresholdController.dispose();
    _humidityThresholdController.dispose();
    _pressureThresholdController.dispose();
    super.dispose();
  }
}