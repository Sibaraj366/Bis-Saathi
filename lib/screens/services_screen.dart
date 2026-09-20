import 'package:flutter/material.dart' hide Text;
import '../services/api_service.dart';
import '../services/app_language.dart';
import 'package:url_launcher/url_launcher.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  Future<void> _openService(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (opened) {
        // Record the service view only after the official
        // BIS service has been successfully opened.
        await ApiService.recordActivity('service_view');
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the official BIS service.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the BIS service. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLanguage.of(context);

    final services = [
      {
        'title': 'Apply for BIS Licence',
        'description':
            'Apply online for BIS product certification through the official BIS portal.',
        'icon': Icons.verified_outlined,
        'url': 'https://www.manakonline.in/',
      },
      {
        'title': 'Renew BIS Licence',
        'description':
            'Access the official BIS portal to renew an existing licence.',
        'icon': Icons.autorenew,
        'url': 'https://www.manakonline.in/',
      },
      {
        'title': 'eBIS / Manakonline',
        'description':
            'Access BIS online services and conformity assessment activities.',
        'icon': Icons.language,
        'url': 'https://www.manakonline.in/',
      },
      {
        'title': 'BIS Care App',
        'description':
            'Verify BIS marks, HUID, licences and access consumer services.',
        'icon': Icons.phone_android,
        'url': 'https://www.bis.gov.in/bis-apps/?lang=en',
      },
      {
        'title': 'Consumer Complaints',
        'description':
            'Access official BIS channels for complaints and grievance handling.',
        'icon': Icons.report_problem_outlined,
        'url':
            'https://www.bis.gov.in/consumer-overview/online-complaint-registration/?lang=en',
      },
      {
        'title': 'BIS Training',
        'description':
            'Explore BIS training programmes and registration information.',
        'icon': Icons.school_outlined,
        'url':
            'https://www.bis.gov.in/training-2/procedure-for-applying-for-a-training-programme/?lang=en',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BIS Services',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BIS Services',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Access important BIS services and official resources.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0B5ED7), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Use the official BIS resources below for applications, consumer services, training and other BIS activities.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            ...services.map((service) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ServiceCard(
                  title: service['title'] as String,
                  description: service['description'] as String,
                  icon: service['icon'] as IconData,
                  onOpenService: () {
                    _openService(context, service['url'] as String);
                  },
                ),
              );
            }),
            const SizedBox(height: 10),
            const Text(
              'Official BIS Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'BIS Saathi opens these services using official BIS websites and portals.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onOpenService;

  const _ServiceCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onOpenService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0B5ED7), size: 27),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onOpenService,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Open Official Service',
                          style: TextStyle(
                            color: Color(0xFF0B5ED7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 5),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Color(0xFF0B5ED7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
