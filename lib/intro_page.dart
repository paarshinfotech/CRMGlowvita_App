import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'package:timeline_tile/timeline_tile.dart'; // import this

// ─── COLORS ──────────────────────────────────────────────────────────────────
class C {
  static const maroon = Color(0xFF4A2C3C);
  static const maroonMid = Color(0xFF5C3C4C);
  static const maroonLight = Color(0xFF9B7A8A);
  static const maroonPale = Color(0xFFF6F0F2);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFF9F9FB);
  static const black = Color(0xFF121212);
  static const dark = Color(0xFF1A0F15);
  static const grey = Color(0xFF71717A);
  static const greyMid = Color(0xFFA1A1AA);
  static const greyLight = Color(0xFFE4E4E7);
  static const greyBg = Color(0xFFF4F4F5);
  static const iconBg = Color(0xFFF6F0F2);
  static const footerBg = Color(0xFF09090B);
}

// ─── RESPONSIVE ──────────────────────────────────────────────────────────────
class R {
  static double w(BuildContext c) => MediaQuery.of(c).size.width;
  static bool mob(BuildContext c) => w(c) < 600;
  static EdgeInsets hPad(BuildContext c) {
    final wd = w(c);
    if (wd < 600) return EdgeInsets.symmetric(horizontal: 16.w);
    return EdgeInsets.symmetric(horizontal: wd * 0.08);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LANDING PAGE
// ═══════════════════════════════════════════════════════════════════════════════
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _scroll = ScrollController();
  bool _solid = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final s = _scroll.offset > 40;
      if (s != _solid) setState(() => _solid = s);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => Scaffold(
        backgroundColor: C.white,
        body: Stack(children: [
          SingleChildScrollView(
            controller: _scroll,
            child: Column(children: [
              const _HeroSection(),
              const _CoreCRMSection(),
              const _TestimonialsSection(),
              const _BuiltInSection(),
              const _HowItWorksSection(),
              const _SecuritySection(),
              const _VendorCRMSection(),
              const _CTASection(),
            ]),
          ),
          _NavBar(solid: _solid),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// NAV BAR
// ═══════════════════════════════════════════════════════════════════════════════
class _NavBar extends StatelessWidget {
  final bool solid;
  const _NavBar({required this.solid});

  @override
  Widget build(BuildContext ctx) {
    final mob = R.mob(ctx);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: solid ? C.white : Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: R.hPad(ctx).copyWith(top: 8.h, bottom: 8.h),
          decoration: solid
              ? BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: C.greyLight, width: 0.5)))
              : null,
          child: Row(children: [
            // Logo
            Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: Image.asset(
                  'assets/images/favicon.jpg',
                  width: 28.w,
                  height: 28.w,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                        color: C.maroon,
                        borderRadius: BorderRadius.circular(4.r)),
                    child: Center(
                        child: Text('G',
                            style: TextStyle(
                                color: C.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              if (!mob) ...[
                SizedBox(width: 8.w),
                Text('GLOWVITA',
                    style: GoogleFonts.poppins(
                        color: solid ? C.maroon : C.white,
                        fontSize: 10.sp,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700)),
              ]
            ]),
            const Spacer(),
            if (!mob) ...[
              _nl('Solutions', solid),
              SizedBox(width: 24.w),
              _nl('Pricing', solid),
              SizedBox(width: 24.w),
              _nl('Company', solid),
              SizedBox(width: 24.w),
            ],
            GestureDetector(
              onTap: () => Navigator.push(
                  ctx, MaterialPageRoute(builder: (_) => const Login())),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                    color: C.maroon, borderRadius: BorderRadius.circular(25.r)),
                child: Text('Sign In',
                    style: GoogleFonts.poppins(
                        color: C.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _nl(String t, bool solid) => Text(t,
      style: GoogleFonts.poppins(
          color: solid ? C.black : C.white,
          fontSize: 10.sp,
          fontWeight: FontWeight.w500));
}

// ═══════════════════════════════════════════════════════════════════════════════
// HERO section
// ═══════════════════════════════════════════════════════════════════════════════
class _HeroSection extends StatefulWidget {
  const _HeroSection();
  @override
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeIn);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final mob = R.mob(ctx);
    return FadeTransition(
      opacity: _fade,
      child: Container(
        height: mob ? 380.h : 300.h,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          Padding(
            padding: R.hPad(ctx),
            child: mob
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [_leftText(ctx)])
                : Row(children: [
                    Expanded(flex: 5, child: _leftText(ctx)),
                  ]),
          ),
        ]),
      ),
    );
  }

  Widget _leftText(BuildContext ctx) {
    final mob = R.mob(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('INTRODUCING GLOWVITA',
            style: GoogleFonts.poppins(
                color: C.maroonLight,
                fontSize: 8.sp,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 10.h),
        Text('Streamline your\nsalon operations.',
            style: GoogleFonts.poppins(
                color: C.maroon,
                fontSize: mob ? 22.sp : 30.sp,
                fontWeight: FontWeight.w700,
                height: 1.1)),
        SizedBox(height: 12.h),
        Text(
          'Unified platform for appointments, CRM, and business growth analytics.',
          style: GoogleFonts.poppins(
              color: C.greyMid, fontSize: 10.sp, height: 1.5),
        ),
        SizedBox(height: 18.h),
        GestureDetector(
          onTap: () => Navigator.push(
              ctx, MaterialPageRoute(builder: (_) => const Login())),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
            decoration: BoxDecoration(
                color: C.maroon, borderRadius: BorderRadius.circular(25.r)),
            child: Text('Get Started Free',
                style: GoogleFonts.poppins(
                    color: C.white,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CORE CRM FEATURES
// ═══════════════════════════════════════════════════════════════════════════════
class _CoreCRMSection extends StatelessWidget {
  const _CoreCRMSection();

  static const _features = [
    _CF(Icons.person_pin_outlined, 'Lead Manager',
        'Track every potential client.'),
    _CF(Icons.stacked_line_chart, 'Pipeline', 'Visualize deal progression.'),
    _CF(Icons.history, 'History', 'Full client service logs.'),
    _CF(Icons.bolt, 'Automation', 'Auto follow-ups & alerts.'),
    _CF(Icons.pie_chart_outline, 'Insights', 'Deep business analytics.'),
    _CF(Icons.speed, 'Success', 'KPI & team tracking.'),
  ];

  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: C.white,
      width: double.infinity,
      padding: R.hPad(ctx).copyWith(top: 40.h, bottom: 40.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Core Features',
            style: GoogleFonts.poppins(
                fontSize: 14.sp, fontWeight: FontWeight.w700, color: C.dark)),
        SizedBox(height: 2.h),
        Text('Everything you need in one line.',
            style: GoogleFonts.poppins(fontSize: 10.sp, color: C.grey)),
        SizedBox(height: 14.h),
        _crmGrid(),
      ]),
    );
  }

  Widget _crmGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        childAspectRatio: 0.9,
      ),
      itemCount: _features.length,
      itemBuilder: (ctx, i) => _CRMCard(f: _features[i]),
    );
  }
}

class _CF {
  final IconData icon;
  final String title, desc;
  const _CF(this.icon, this.title, this.desc);
}

class _CRMCard extends StatelessWidget {
  final _CF f;
  const _CRMCard({required this.f});

  @override
  Widget build(BuildContext ctx) => Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: C.offWhite,
          borderRadius: BorderRadius.circular(4.r),
          border: Border.all(color: C.greyLight, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(f.icon, size: 16.sp, color: C.maroon),
            const Spacer(),
            Text(f.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    color: C.dark)),
            SizedBox(height: 2.h),
            Text(f.desc,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 8.sp, color: C.grey)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// REVIEWS / TESTIMONIALS
// ═══════════════════════════════════════════════════════════════════════════════
class _TestimonialsSection extends StatelessWidget {
  const _TestimonialsSection();

  static const _revs = [
    _Rev('Emma R.', 'Elite Salon', 'Unmatched clarity in business tracking.'),
    _Rev('Olivia C.', 'Studio 22', 'Client retention increased by 30%.'),
    _Rev('Priya S.', 'Zen Spa', 'Seamless booking for our team.'),
  ];

  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: C.greyBg,
      padding: R.hPad(ctx).copyWith(top: 40.h, bottom: 40.h),
      child: Column(children: [
        Text('CLIENT FEEDBACK',
            style: GoogleFonts.poppins(
                fontSize: 8.sp,
                color: C.grey,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700)),
        SizedBox(height: 20.h),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _revs.map((r) => _revCard(ctx, r)).toList()),
        ),
      ]),
    );
  }

  Widget _revCard(BuildContext ctx, _Rev r) => Container(
        width: 200.w,
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
            color: C.white, borderRadius: BorderRadius.circular(3.r)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('"${r.quote}"',
              style: GoogleFonts.poppins(
                  fontSize: 10.sp, color: C.dark, fontStyle: FontStyle.italic)),
          SizedBox(height: 12.h),
          Row(children: [
            CircleAvatar(
                radius: 8.r,
                backgroundColor: C.maroonPale,
                child: Text(r.name[0],
                    style: TextStyle(fontSize: 8.sp, color: C.maroon))),
            SizedBox(width: 8.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name,
                  style: GoogleFonts.poppins(
                      fontSize: 9.sp, fontWeight: FontWeight.bold)),
              Text(r.role,
                  style: GoogleFonts.poppins(fontSize: 8.sp, color: C.greyMid)),
            ]),
          ]),
        ]),
      );
}

class _Rev {
  final String name, role, quote;
  const _Rev(this.name, this.role, this.quote);
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUILT-IN FEATURES
// ═══════════════════════════════════════════════════════════════════════════════
class _BuiltInSection extends StatelessWidget {
  const _BuiltInSection();

  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: C.white,
      padding: R.hPad(ctx).copyWith(top: 40.h, bottom: 40.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Built-in Modules',
            style: GoogleFonts.poppins(
                fontSize: 14.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            'Calendar',
            'Payments',
            'Inventory',
            'Reports',
            'Marketing',
            'Staff'
          ]
              .map((t) => Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                        color: C.greyBg,
                        borderRadius: BorderRadius.circular(2.r)),
                    child: Text(t,
                        style:
                            GoogleFonts.poppins(fontSize: 9.sp, color: C.dark)),
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HOW IT WORKS - Vertical Timeline (similar to GlowVita reference)
// ═══════════════════════════════════════════════════════════════════════════════
class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  static const _steps = [
    _WStep(
      number: '1',
      icon: Icons.person_add_alt_1_rounded,
      title: 'Sign Up & Setup',
      desc:
          'Create your account and set up your salon services, staff, and schedule in minutes.',
      isLeft: true,
    ),
    _WStep(
      number: '2',
      icon: Icons.calendar_today_rounded,
      title: 'Client Bookings',
      desc:
          'Clients book appointments 24/7 through the GlowVita app or your website, with automated reminders.',
      isLeft: false,
    ),
    _WStep(
      number: '3',
      icon: Icons.manage_accounts_rounded,
      title: 'Manage Operations',
      desc:
          'Track appointments, manage staff schedules, and handle payments seamlessly in one place.',
      isLeft: true,
    ),
    _WStep(
      number: '4',
      icon: Icons.trending_up_rounded,
      title: 'Grow & Analyze',
      desc:
          'Use analytics and marketing tools to grow your business and increase revenue.',
      isLeft: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Assuming you have responsive helpers like R.hPad, .h, .sp – adjust as needed
    final padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 40);

    return Container(
      color: Colors.white,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Text(
            'How It Works',
            style: GoogleFonts.poppins(
              fontSize: 14.sp, // adjust with .sp if using responsive
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Our simple 4-step process to transform your salon business with our CRM platform.',
            style: GoogleFonts.poppins(
              fontSize: 9.sp,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),

          // Vertical Timeline
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            separatorBuilder: (_, __) => const SizedBox(height: 32),
            itemBuilder: (context, index) {
              final step = _steps[index];
              return TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY:
                    0.1, // controls how far left the line is (0.1 = left-ish)
                isFirst: index == 0,
                isLast: index == _steps.length - 1,
                indicatorStyle: IndicatorStyle(
                  width: 40,
                  height: 40,
                  indicatorXY: 0.5,
                  drawGap: true,
                  color: C.maroon,
                  iconStyle: IconStyle(
                    color: Colors.white,
                    iconData: step.icon,
                    fontSize: 13.sp,
                  ),
                ),
                beforeLineStyle: const LineStyle(
                  color: Colors.grey,
                  thickness: 3,
                ),
                afterLineStyle: const LineStyle(
                  color: Colors.grey,
                  thickness: 3,
                ),
                endChild: Container(
                  constraints: const BoxConstraints(minHeight: 120),
                  child: _buildStepCard(step, isLeft: step.isLeft),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(_WStep step, {required bool isLeft}) {
    final card = Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              step.title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              step.desc,
              style: GoogleFonts.poppins(
                fontSize: 8,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );

    // Alternate alignment using padding or Align
    return Padding(
      padding: EdgeInsets.only(
        left: isLeft ? 60 : 0,
        right: isLeft ? 0 : 60,
      ),
      child: card,
    );
  }
}

class _WStep {
  final String number;
  final IconData icon;
  final String title;
  final String desc;
  final bool isLeft;

  const _WStep({
    required this.number,
    required this.icon,
    required this.title,
    required this.desc,
    required this.isLeft,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SECURITY
// ═══════════════════════════════════════════════════════════════════════════════
class _SecuritySection extends StatelessWidget {
  const _SecuritySection();
  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: C.offWhite,
      padding: R.hPad(ctx).copyWith(top: 30.h, bottom: 30.h),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.verified_user, size: 12.sp, color: C.greyMid),
        SizedBox(width: 8.w),
        Text('Secure, encrypted & cloud-ready',
            style: GoogleFonts.poppins(fontSize: 9.sp, color: C.grey)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// VENDOR APP
// ═══════════════════════════════════════════════════════════════════════════════
class _VendorCRMSection extends StatelessWidget {
  const _VendorCRMSection();

  @override
  Widget build(BuildContext ctx) {
    return Container(
      color: C.white,
      padding: R.hPad(ctx).copyWith(top: 40.h, bottom: 40.h),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mobile First',
              style: GoogleFonts.poppins(
                  fontSize: 10.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 8.h),
          Text('Manage your business from anywhere with the single touch.',
              style: GoogleFonts.poppins(fontSize: 10.sp, color: C.grey)),
        ])),
        SizedBox(width: 20.w),
        Container(
          width: 80.w,
          height: 140.h,
          decoration: BoxDecoration(
              color: C.black, borderRadius: BorderRadius.circular(8.r)),
          child:
              Center(child: Icon(Icons.spa, color: C.maroonLight, size: 24.sp)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// CTA
// ═══════════════════════════════════════════════════════════════════════════════
class _CTASection extends StatelessWidget {
  const _CTASection();
  @override
  Widget build(BuildContext ctx) {
    return Container(
      width: double.infinity,
      color: C.maroon,
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(children: [
        Text('Ready to Transform Your Salon Business?',
            style: GoogleFonts.poppins(
                color: C.white, fontSize: 10.sp, fontWeight: FontWeight.bold)),
        SizedBox(height: 10.h),
        Text(
          '      Join thousands of salon owners using GlowVita CRM to streamline operations and boost revenue.',
          style: GoogleFonts.poppins(
              color: C.greyMid, fontSize: 8.sp, height: 1.2),
        ),
        SizedBox(height: 16.h),
        GestureDetector(
          onTap: () => Navigator.push(
              ctx, MaterialPageRoute(builder: (_) => const Login())),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
            decoration: BoxDecoration(
                color: C.white, borderRadius: BorderRadius.circular(25.r)),
            child: Text('Get Started Now',
                style: GoogleFonts.poppins(
                    color: C.maroon,
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}
