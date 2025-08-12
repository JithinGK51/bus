import 'package:flutter/material.dart';
import 'package:ksrtc_users/config/api_config.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiUrlController = TextEditingController();
  bool _isSaving = false;
  String? _saveError;
  String? _currentApiUrl;

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  // Load the current API URL from shared preferences
  Future<void> _loadApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_base_url') ?? ApiConfig.baseUrl;
    setState(() {
      _currentApiUrl = savedUrl;
      _apiUrlController.text = savedUrl;
    });
  }

  // Save the API URL to shared preferences
  Future<void> _saveApiUrl() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', _apiUrlController.text);

      // Update the API config
      ApiConfig.updateBaseUrl(_apiUrlController.text);

      setState(() {
        _currentApiUrl = _apiUrlController.text;
        _isSaving = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API URL updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _saveError = 'Failed to save API URL: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.primaryDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // API Configuration section
              const Text(
                'API Configuration',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure the base URL for the bus tracking API',
                style: TextStyle(color: AppTheme.textGrey),
              ),
              const SizedBox(height: 16),

              // API URL input field
              TextFormField(
                controller: _apiUrlController,
                decoration: InputDecoration(
                  labelText: 'API Base URL',
                  hintText: 'http://192.168.1.1:8000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the API URL';
                  }

                  // Basic URL validation
                  if (!value.startsWith('http://') &&
                      !value.startsWith('https://')) {
                    return 'URL must start with http:// or https://';
                  }

                  return null;
                },
              ),

              if (_saveError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _saveError!,
                  style: const TextStyle(color: AppTheme.accentRed),
                ),
              ],

              const SizedBox(height: 16),

              // Current API URL display
              if (_currentApiUrl != null) ...[
                const Text(
                  'Current API URL:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentApiUrl!,
                  style: const TextStyle(color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
              ],

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveApiUrl,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child:
                      _isSaving
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Save API Configuration'),
                ),
              ),

              const SizedBox(height: 24),

              // Reset button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _apiUrlController.text = 'http://192.168.1.1:8000';
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentBlue,
                    side: const BorderSide(color: AppTheme.accentBlue),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reset to Default'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
