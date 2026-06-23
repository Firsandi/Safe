import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // FAQ List mapping category to ID and EN versions
  List<Map<String, String>> _getFaqs(bool isIndonesian) {
    if (isIndonesian) {
      return [
        {
          'category': 'SOS & Deteksi',
          'question': 'Bagaimana cara kerja Deteksi Tabrakan?',
          'answer': 'SAFE menggunakan sensor akselerometer pada HP Anda untuk mendeteksi guncangan kuat (>4G) secara berkelanjutan yang biasanya terjadi saat tabrakan kendaraan. Setelah guncangan, aplikasi memverifikasi apakah gerakan berhenti mendadak untuk memastikan akurasi sebelum memicu countdown SOS.'
        },
        {
          'category': 'SOS & Deteksi',
          'question': 'Apa yang harus dilakukan saat alarm palsu terpicu?',
          'answer': 'Jika sensor mendeteksi guncangan namun Anda baik-baik saja (misalnya HP terlempar keras), Anda cukup mengusap tombol "GESER KE ATAS UNTUK BATAL" pada layar countdown dalam waktu 15 detik untuk membatalkan pengiriman peringatan darurat.'
        },
        {
          'category': 'Kontak',
          'question': 'Bagaimana cara menambahkan kontak darurat?',
          'answer': 'Buka tab "Kontak" dari menu bawah, tekan tombol tambah (+), masukkan nomor HP rekan/keluarga Anda, lalu kirim permintaan. Kontak akan aktif setelah mereka menerima permintaan Anda di aplikasi SAFE mereka.'
        },
        {
          'category': 'Akun & Keamanan',
          'question': 'Apakah data medis saya aman?',
          'answer': 'Ya, seluruh data medis awal dan riwayat Anda dienkripsi secara aman. Data medis hanya akan dibagikan kepada kontak darurat terpilih saat alarm SOS terpicu untuk mempermudah pertolongan pertama.'
        },
        {
          'category': 'Akun & Keamanan',
          'question': 'Bagaimana cara mengganti kata sandi?',
          'answer': 'Buka profil Anda, lalu cari menu edit profile atau kata sandi. Masukkan kata sandi lama Anda dan kata sandi baru Anda untuk memperbarui kredensial akun Anda.'
        }
      ];
    } else {
      return [
        {
          'category': 'SOS & Detection',
          'question': 'How does Crash Detection work?',
          'answer': 'SAFE uses your phone\'s accelerometer sensor to detect sustained high-impact forces (>4G) typical of vehicle accidents. Post-impact, the app verifies sudden stillness to ensure accuracy before starting the SOS countdown.'
        },
        {
          'category': 'SOS & Detection',
          'question': 'What should I do during a false alarm?',
          'answer': 'If the sensor triggers but you are safe (e.g. phone dropped), simply swipe the "SWIPE UP TO CANCEL" button upwards on the countdown screen within 15 seconds to abort the alert.'
        },
        {
          'category': 'Contacts',
          'question': 'How do I add emergency contacts?',
          'answer': 'Navigate to the "Contacts" tab, tap the add (+) button, enter your contact\'s phone number, and send a request. They will appear as active contacts once they accept the request on their SAFE app.'
        },
        {
          'category': 'Account & Security',
          'question': 'Is my medical data secure?',
          'answer': 'Yes, all your initial medical profiles and history are encrypted and stored under strict security protocols. Medical data is only shared with your designated emergency contacts when an SOS is triggered.'
        },
        {
          'category': 'Account & Security',
          'question': 'How do I change my password?',
          'answer': 'Navigate to your Profile page and check the security or password settings. Enter your current password followed by your new password to update your login credentials.'
        }
      ];
    }
  }

  Future<void> _contactWhatsApp() async {
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final Uri whatsappUrl = Uri.parse("https://wa.me/6281358485648?text=Halo%20SAFE%20Support,%20saya%20butuh%20bantuan...");
    try {
      if (!await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $whatsappUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndonesian 
                  ? 'Tidak dapat membuka WhatsApp. Pastikan aplikasi WhatsApp sudah terinstal.'
                  : 'Could not open WhatsApp. Please make sure the app is installed.',
            ),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _contactEmail() async {
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final Uri emailUrl = Uri(
      scheme: 'mailto',
      path: 'safe.app.otp@gmail.com',
      queryParameters: {
        'subject': 'SAFE App Support Request',
        'body': 'Halo Tim Support SAFE,\n\nSaya memerlukan bantuan terkait...',
      },
    );
    try {
      if (!await launchUrl(emailUrl)) {
        throw 'Could not launch $emailUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndonesian
                  ? 'Tidak dapat membuka aplikasi Email.'
                  : 'Could not open email application.',
            ),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _contactPhone() async {
    final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
    final Uri phoneUrl = Uri(
      scheme: 'tel',
      path: '+6281358485648',
    );
    try {
      if (!await launchUrl(phoneUrl)) {
        throw 'Could not launch $phoneUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isIndonesian
                  ? 'Tidak dapat melakukan panggilan. Pastikan perangkat mendukung panggilan telepon.'
                  : 'Could not launch phone dialer. Please make sure your device supports calls.',
            ),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isIndonesian = locale.languageCode == 'id';
    final faqs = _getFaqs(isIndonesian);

    final categories = isIndonesian 
        ? ['Semua', 'SOS & Deteksi', 'Kontak', 'Akun & Keamanan']
        : ['All', 'SOS & Detection', 'Contacts', 'Account & Security'];

    // Map selected category when language changes
    if (_selectedCategory == 'Semua' && !isIndonesian) _selectedCategory = 'All';
    if (_selectedCategory == 'All' && isIndonesian) _selectedCategory = 'Semua';

    // Filter FAQs based on query & category
    final filteredFaqs = faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'Semua' || 
          _selectedCategory == 'All' || 
          faq['category'] == _selectedCategory;
      final matchesSearch = faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isIndonesian ? 'Pusat Bantuan' : 'Help Center',
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
      body: CustomScrollView(
        slivers: [
          // Header Search Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIndonesian ? 'Ada yang bisa kami bantu?' : 'How can we help you?',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: isIndonesian ? 'Cari pertanyaan...' : 'Search questions...',
                        hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                        suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textGrey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories Filter Horizontal List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategory == cat;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textDark,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryRed,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : AppColors.inputBorder,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // FAQ Expansion Tiles
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: filteredFaqs.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_outline, size: 60, color: AppColors.textGrey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            isIndonesian ? 'Pertanyaan tidak ditemukan' : 'No results found',
                            style: AppTextStyles.heading.copyWith(fontSize: 16, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isIndonesian 
                                ? 'Cobalah cari kata kunci lain.'
                                : 'Try searching for other keywords.',
                            style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final faq = filteredFaqs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                leading: Icon(
                                  faq['category']!.startsWith('SOS') 
                                      ? Icons.warning_amber_rounded 
                                      : faq['category']!.startsWith('Kontak') || faq['category']!.startsWith('Contact')
                                          ? Icons.people_outline 
                                          : Icons.security_outlined,
                                  color: AppColors.primaryRed,
                                  size: 22,
                                ),
                                title: Text(
                                  faq['question']!,
                                  style: AppTextStyles.subHeading.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    fontSize: 14,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                    child: Text(
                                      faq['answer']!,
                                      style: AppTextStyles.subHeading.copyWith(
                                        color: Colors.black54,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: filteredFaqs.length,
                    ),
                  ),
          ),

          // Contact Support Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIndonesian ? 'Masih Butuh Bantuan?' : 'Still Need Help?',
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 16,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isIndonesian 
                          ? 'Hubungi kami secara langsung melalui kontak dukungan di bawah.'
                          : 'Reach out to our team directly through the channels below.',
                      style: AppTextStyles.subHeading.copyWith(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // WhatsApp Row
                    _buildSupportChannel(
                      icon: Icons.chat_bubble_outline,
                      iconBg: const Color(0xFFE8F8EF),
                      iconColor: const Color(0xFF22C55E),
                      title: 'WhatsApp Chat',
                      subtitle: isIndonesian ? 'Respon cepat 24 jam' : '24-hour fast response',
                      onTap: _contactWhatsApp,
                    ),
                    const Divider(height: 20),
                    // Email Row
                    _buildSupportChannel(
                      icon: Icons.mail_outline,
                      iconBg: const Color(0xFFEDF4FE),
                      iconColor: const Color(0xFF193855),
                      title: 'Email Support',
                      subtitle: 'safe.app.otp@gmail.com',
                      onTap: _contactEmail,
                    ),
                    const Divider(height: 20),
                    // Phone Call Row
                    _buildSupportChannel(
                      icon: Icons.phone_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: isIndonesian ? 'Panggilan Telepon' : 'Phone Call',
                      subtitle: 'Hotline: +62 813-5848-5648',
                      onTap: _contactPhone,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportChannel({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subHeading.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.inputLabel.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.textGrey, size: 14),
          ],
        ),
      ),
    );
  }
}
