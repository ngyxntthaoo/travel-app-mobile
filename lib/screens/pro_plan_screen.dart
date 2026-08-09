import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/snackbars.dart';

class ProPlanScreen extends StatefulWidget {
  const ProPlanScreen({super.key});

  @override
  State<ProPlanScreen> createState() => _ProPlanScreenState();
}

class _ProPlanScreenState extends State<ProPlanScreen> {
  int _selectedIndex = 1;

  static const _plans = [
    _Plan(
      name: 'Gói Basic',
      priceLabel: 'Free',
      period: '',
      features: [
        'Đầy đủ tính năng quản lý lịch trình cơ bản',
        'Tối đa giới hạn 3 thành viên trên mỗi trip',
        'Bản đồ & gom nhóm địa điểm cơ bản',
        'Chia tiền nợ (Split Bills) cơ bản',
      ],
    ),
    _Plan(
      name: 'Gói Premium',
      priceLabel: '29.000',
      period: 'VNĐ/tháng',
      featured: true,
      features: [
        'Không giới hạn số người được chia sẻ trên cùng 1 trip',
        'Mở khóa toàn bộ giới hạn API Mapbox',
        'Tối ưu lộ trình với số lượng điểm đến cực lớn',
        'Tracking chuyến bay Realtime (Thời gian thực)',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Gói dịch vụ'),
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Chọn gói dịch vụ của bạn',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.navyDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mở khóa toàn bộ giới hạn bản đồ, lộ trình thông minh và chia sẻ chuyến đi không giới hạn.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
          ),
          const SizedBox(height: 24),
          ...List.generate(_plans.length, (i) {
            final plan = _plans[i];
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlanCard(
                plan: plan,
                selected: selected,
                onTap: () => setState(() => _selectedIndex = i),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final plan = _plans[_selectedIndex];
                if (plan.priceLabel == 'Free') {
                  showSuccessToast(context, 'You are on Basic plan');
                  return;
                }
                showSuccessToast(context, 'Subscribed to ${plan.name}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _plans[_selectedIndex].priceLabel == 'Free'
                    ? 'Bắt đầu với Gói Basic'
                    : 'Đăng ký ${_plans[_selectedIndex].name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hủy đăng ký bất kỳ lúc nào. Giá đã bao gồm VAT.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  const _Plan({
    required this.name,
    required this.priceLabel,
    required this.period,
    required this.features,
    this.featured = false,
    this.badge,
  });

  final String name;
  final String priceLabel;
  final String period;
  final List<String> features;
  final bool featured;
  final String? badge;
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.featured;
    final bgColor = isPremium ? const Color(0xFF1F8CB6) : Colors.white;
    final textColor = isPremium ? Colors.white : AppColors.navyDark;
    final subtitleColor = isPremium ? Colors.white.withOpacity(0.8) : Colors.grey.shade600;
    final checkColor = isPremium ? const Color(0xFFFFD54F) : AppColors.teal;
    final borderColor = selected 
        ? (isPremium ? Colors.white : AppColors.teal)
        : (isPremium ? Colors.transparent : AppColors.divider);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (plan.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPremium ? Colors.white.withOpacity(0.2) : AppColors.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.badge!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPremium ? Colors.white : AppColors.teal,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: selected 
                        ? (isPremium ? Colors.white : AppColors.teal) 
                        : (isPremium ? Colors.white.withOpacity(0.5) : Colors.grey.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.priceLabel,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      plan.period,
                      style: TextStyle(
                        fontSize: 13, 
                        color: subtitleColor,
                        fontWeight: isPremium ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...plan.features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 18, color: checkColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 14, 
                            color: isPremium ? Colors.white.withOpacity(0.95) : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
