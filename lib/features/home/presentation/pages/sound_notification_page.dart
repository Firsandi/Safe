import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class SoundNotificationPage extends StatefulWidget {
  const SoundNotificationPage({super.key});

  @override
  State<SoundNotificationPage> createState() => _SoundNotificationPageState();
}

class _SoundNotificationPageState extends State<SoundNotificationPage> {
  final AudioPlayer _previewPlayer = AudioPlayer();
  String _selectedType = 'default';
  String _customPath = '';
  String _customName = '';
  String _playingSoundCode = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _previewPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingSoundCode = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedType = prefs.getString('alarm_sound_type') ?? 'default';
      _customPath = prefs.getString('alarm_sound_path') ?? '';
      _customName = prefs.getString('alarm_sound_name') ?? '';
    });
  }

  Future<void> _selectSoundType(String type, String path) async {
    setState(() {
      _selectedType = type;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alarm_sound_type', type);
    await prefs.setString('alarm_sound_path', path);
  }

  Future<void> _pickCustomFile() async {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final name = result.files.single.name;

        setState(() {
          _selectedType = 'custom';
          _customPath = path;
          _customName = name;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('alarm_sound_type', 'custom');
        await prefs.setString('alarm_sound_path', path);
        await prefs.setString('alarm_sound_name', name);

        _showSuccessSnackBar(
          isEn
              ? 'Custom alarm sound set: $name'
              : 'Berhasil mengatur nada kustom: $name'
        );
      }
    } catch (e) {
      _showErrorSnackBar(
        isEn ? 'Failed to pick audio file: $e' : 'Gagal mengambil file audio: $e'
      );
    }
  }

  Future<void> _playPreview(String code, String path, String type) async {
    if (_playingSoundCode == code) {
      await _previewPlayer.stop();
      setState(() {
        _playingSoundCode = '';
      });
      return;
    }

    try {
      await _previewPlayer.stop();
      setState(() {
        _playingSoundCode = code;
      });

      if (type == 'custom') {
        await _previewPlayer.play(DeviceFileSource(path));
      } else if (type == 'beep') {
        try {
          await _previewPlayer.play(AssetSource('sounds/high_pitch_beep.mp3'));
        } catch (_) {
          await _previewPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg'));
        }
      } else if (type == 'retro') {
        try {
          await _previewPlayer.play(AssetSource('sounds/retro_alarm.mp3'));
        } catch (_) {
          await _previewPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/mechanical_clock_ring.ogg'));
        }
      } else {
        try {
          await _previewPlayer.play(AssetSource('sounds/alarm_sound.mp3'));
        } catch (_) {
          await _previewPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/emergency_siren.ogg'));
        }
      }
    } catch (e) {
      debugPrint('Error playing preview: $e');
      setState(() {
        _playingSoundCode = '';
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEn ? 'Sound & Notifications' : 'Suara & Notifikasi',
          style: AppTextStyles.heading.copyWith(
            fontSize: 18,
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Text(
              isEn ? 'SOS Emergency Alarm Sound' : 'Suara Alarm Darurat SOS',
              style: AppTextStyles.heading.copyWith(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              isEn 
                  ? 'Choose the warning alarm tone to play when an SOS countdown starts.' 
                  : 'Pilih nada suara alarm yang berbunyi saat hitung mundur SOS terpicu.',
              style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Sound Options Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inputBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Option 1: Default Siren
                  _buildSoundOption(
                    title: isEn ? 'Emergency Siren (Default)' : 'Siren Darurat (Default)',
                    subtitle: 'sounds/alarm_sound.mp3',
                    code: 'default',
                    icon: Icons.notifications_active,
                    iconColor: AppColors.primaryRed,
                    onTap: () => _selectSoundType('default', 'sounds/alarm_sound.mp3'),
                    previewType: 'default',
                    previewPath: 'sounds/alarm_sound.mp3',
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),

                  // Option 2: High Pitch Beep
                  _buildSoundOption(
                    title: isEn ? 'High-Pitch Beep' : 'Beep Frekuensi Tinggi',
                    subtitle: 'sounds/high_pitch_beep.mp3',
                    code: 'beep',
                    icon: Icons.volume_up,
                    iconColor: const Color(0xFF193855),
                    onTap: () => _selectSoundType('beep', 'sounds/high_pitch_beep.mp3'),
                    previewType: 'beep',
                    previewPath: 'sounds/high_pitch_beep.mp3',
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),

                  // Option 3: Retro Jam Digital
                  _buildSoundOption(
                    title: isEn ? 'Retro Alarm' : 'Jam Digital Klasik',
                    subtitle: 'sounds/retro_alarm.mp3',
                    code: 'retro',
                    icon: Icons.watch_later_outlined,
                    iconColor: const Color(0xFFEA580C),
                    onTap: () => _selectSoundType('retro', 'sounds/retro_alarm.mp3'),
                    previewType: 'retro',
                    previewPath: 'sounds/retro_alarm.mp3',
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),

                  // Option 4: Custom Sound
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedType == 'custom' 
                            ? const Color(0xFFE0F2FE) 
                            : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.audiotrack,
                        color: _selectedType == 'custom' 
                            ? const Color(0xFF0284C7) 
                            : Colors.grey[600],
                        size: 22,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            isEn ? 'Custom Device Music' : 'Pilih Nada Kustom',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        if (_selectedType == 'custom')
                          const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _selectedType == 'custom' && _customName.isNotEmpty
                            ? _customName
                            : (isEn ? 'Select a music file from your device' : 'Pilih file musik dari HP Anda'),
                        style: TextStyle(
                          fontSize: 11,
                          color: _selectedType == 'custom' ? const Color(0xFF0284C7) : Colors.grey,
                          fontWeight: _selectedType == 'custom' ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedType == 'custom' && _customPath.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              _playingSoundCode == 'custom'
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: const Color(0xFF0284C7),
                              size: 26,
                            ),
                            onPressed: () => _playPreview('custom', _customPath, 'custom'),
                          ),
                        TextButton(
                          onPressed: _pickCustomFile,
                          child: Text(
                            isEn ? 'Browse' : 'Pilih',
                            style: const TextStyle(color: Color(0xFF193855), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundOption({
    required String title,
    required String subtitle,
    required String code,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String previewType,
    required String previewPath,
  }) {
    final isSelected = _selectedType == code;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? iconColor.withOpacity(0.1) : Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isSelected ? iconColor : Colors.grey[600], size: 22),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          if (isSelected)
            Icon(Icons.check_circle, color: isSelected ? iconColor : Colors.grey, size: 18),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          _playingSoundCode == code 
              ? Icons.pause_circle_filled 
              : Icons.play_circle_filled,
          color: isSelected ? iconColor : Colors.grey[600],
          size: 26,
        ),
        onPressed: () => _playPreview(code, previewPath, previewType),
      ),
    );
  }
}
