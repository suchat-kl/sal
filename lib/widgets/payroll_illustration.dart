import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/theme.dart';

/// ภาพประกอบหน้าแรก วาดด้วย widget ล้วน (ไม่ใช้ไฟล์รูป): ใบรับรองภาษี + สลิปเงินเดือน + กองเหรียญ
/// ขยายตามขนาดที่ได้รับ คมชัดทุกความละเอียดหน้าจอ
class PayrollIllustration extends StatelessWidget {
  const PayrollIllustration({super.key});

  // ออกแบบไว้ที่ขนาดนี้ แล้วย่อ/ขยายด้วย FittedBox
  static const double _w = 420;
  static const double _h = 320;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: _w,
        height: _h,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // วงกลมตกแต่งด้านหลัง
            Positioned(
              left: 40,
              top: 10,
              child: _blob(260, Colors.white.withValues(alpha: 0.10)),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: _blob(160, Colors.white.withValues(alpha: 0.08)),
            ),
            // ใบรับรองภาษี (ด้านหลัง เอียงขวา)
            Positioned(
              left: 175,
              top: 22,
              child: Transform.rotate(angle: 0.10, child: const _TaxCard()),
            ),
            // สลิปเงินเดือน (ด้านหน้า เอียงซ้าย)
            Positioned(
              left: 70,
              top: 40,
              child: Transform.rotate(angle: -0.06, child: const _SlipCard()),
            ),
            // กองเหรียญ
            const Positioned(left: 22, bottom: 8, child: _CoinStack()),
            // ป้ายยืนยัน
            Positioned(
              right: 38,
              top: 8,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _blob(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// เส้นแทนบรรทัดข้อความ
Widget _line(
  double width, {
  Color color = const Color(0xFFE2E8F0),
  double height = 8,
}) => Container(
  width: width,
  height: height,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(height / 2),
  ),
);

class _SlipCard extends StatelessWidget {
  const _SlipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 250,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'สลิปเงินเดือน',
                        style: AppTheme.heading(14, weight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _line(70, height: 6),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final w in const [120.0, 95.0, 135.0]) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _line(w),
                _line(36, color: const Color(0xFFCBD5E1)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          const Divider(height: 14, color: Color(0xFFE2E8F0)),
          const Spacer(),
          // ชิดขวา เพราะมุมซ้ายล่างของสลิปมีกองเหรียญบังอยู่
          Align(
            alignment: Alignment.bottomRight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'รับสุทธิ',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '฿ 35,800',
                    style: AppTheme.heading(
                      22,
                      color: AppTheme.primary,
                      weight: FontWeight.w700,
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

class _TaxCard extends StatelessWidget {
  const _TaxCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 230,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '50 ทวิ',
              style: AppTheme.heading(
                12,
                color: const Color(0xFFB45309),
                weight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'ใบรับรองภาษี',
            style: AppTheme.heading(13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          for (final w in const [140.0, 110.0, 150.0, 90.0]) ...[
            _line(w, height: 6),
            const SizedBox(height: 10),
          ],
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.approval_rounded,
                color: AppTheme.primary.withValues(alpha: 0.7),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoinStack extends StatelessWidget {
  const _CoinStack();

  @override
  Widget build(BuildContext context) {
    // กองเหรียญซ้อนกัน 4 เหรียญ + เหรียญตั้งอีก 1 เหรียญ
    return SizedBox(
      width: 150,
      height: 120,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < 4; i++)
            Positioned(left: 0, bottom: i * 13.0, child: _coinEdge()),
          Positioned(
            left: 70,
            bottom: 0,
            child: Transform.rotate(angle: -math.pi / 14, child: _coinFace(64)),
          ),
        ],
      ),
    );
  }

  Widget _coinEdge() => Container(
    width: 80,
    height: 26,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ),
      borderRadius: BorderRadius.circular(40),
      border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
  );

  Widget _coinFace(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFB45309)],
      ),
      border: Border.all(color: const Color(0xFFFEF3C7), width: 3),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    alignment: Alignment.center,
    child: Text(
      '฿',
      style: AppTheme.heading(
        size * 0.45,
        color: const Color(0xFF78350F),
        weight: FontWeight.w700,
      ),
    ),
  );
}
