import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'utils/app_theme.dart';

// ─── Onboarding Data ──────────────────────────────────────────────────────────
class _OnboardData {
  final String gifPath;
  final String title;
  final String titleHighlight;
  final String titleSuffix;
  final bool hasSplitTitle;
  final String subtitle;

  const _OnboardData({
    required this.gifPath,
    required this.title,
    this.titleHighlight = '',
    this.titleSuffix = '',
    this.hasSplitTitle = false,
    required this.subtitle,
  });
}

const _pages = [
  _OnboardData(
    gifPath: 'assets/images/onboarding_img1.gif',
    title: 'Your ',
    titleHighlight: 'Entire Salon',
    titleSuffix: ' in Your ',
    hasSplitTitle: true,
    subtitle:
        'Manage bookings, staff, Client, Services,\nwedding Packages, products, orders, expenses,\noffers and generate reports.',
  ),
  _OnboardData(
    gifPath: 'assets/images/onboarding_img2.gif',
    title: 'Bookings that run themselves',
    subtitle:
        'Effortless booking with a visual calendar, intelligent\nstaff allocation and automated reminders—so no\nclient is ever missed.',
  ),
  _OnboardData(
    gifPath: 'assets/images/onboarding_img3.gif',
    title: 'Billing made simple',
    subtitle:
        'GST invoices, retail sales, staff commission splits\nand payment collection - one screen.',
  ),
];

// ─── Onboarding Screen ────────────────────────────────────────────────────────
class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _skip() => _navigateToLogin();

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'Login'),
        builder: (_) => const Login(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full-screen page view
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => _OnboardingPage(data: _pages[i]),
          ),

          // Dot indicators — top-center
          Positioned(
            top: 50.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => _DotIndicator(isActive: i == _currentPage),
              ),
            ),
          ),

          // Bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(
              currentPage: _currentPage,
              totalPages: _pages.length,
              onSkip: _skip,
              onNext: _goToNext,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single Onboarding Page ───────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final _OnboardData data;

  static const Color _pinkAccent = Color(0xFFA3567F);
  static const Color _darkText = Color(0xFF1A1A2E);
  static const Color _bodyText = Color(0xFF3D3D55);

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      height: double.infinity,
      // White for ~80% of screen; very soft pink only near the bottom
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFFFF), // pure white — entire upper portion
            Color(0xFFFFFFFF), // still white at 70%
            Color(0xFFFFF0FF), // light pink begins
            Color(0xFFF5CCEF), // medium blush
            Color(0xFFF5CCEF), // medium blush
            Color(0xFFF5CCEF), // medium blush
          ],
          stops: [0.0, 0.55, 0.60, 0.70, 0.80, 1.00],
        ),
      ),
      child: Column(
        children: [
          // ── GIF area
          Expanded(
            flex: 55,
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 80.h,
                  left: 28.w,
                  right: 28.w,
                  bottom: 4.h,
                ),
                child: Image.asset(
                  data.gifPath,
                  fit: BoxFit.contain,
                  width: size.width * 0.60,
                  errorBuilder: (ctx, err, stack) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 60.sp,
                    color: Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ),

          // ── Gradient-stroke wave line divider
          CustomPaint(
            size: Size(size.width, 38.h),
            painter: _GradientWavePainter(),
          ),

          // ── Text section
          Expanded(
            flex: 45,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),

                  // Title
                  if (data.hasSplitTitle)
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w700,
                          color: _darkText,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(text: data.title),
                          TextSpan(
                            text: data.titleHighlight,
                            style: GoogleFonts.poppins(
                              color: _pinkAccent,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              fontSize: 17.sp,
                            ),
                          ),
                          TextSpan(text: data.titleSuffix),
                          TextSpan(
                            text: 'Pocket',
                            style: GoogleFonts.poppins(
                              color: _pinkAccent,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              fontSize: 17.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: _darkText,
                        height: 1.35,
                      ),
                    ),

                  SizedBox(height: 25.h),

                  // Subtitle
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 9.sp,
                      color: _bodyText,
                      height: 2.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Space reserved for the floating bottom bar
          SizedBox(height: 50.h),
        ],
      ),
    );
  }
}

// ─── Gradient Wave Line Painter ───────────────────────────────────────────────
class _GradientWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * -0.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 1.2,
      size.width,
      size.height * 0.3,
    );

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: const [Color(0xFFFFFFFF), Color(0xFF422A3C), Color(0xFFFFFFFF)],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Dot Indicator ────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final bool isActive;
  const _DotIndicator({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(horizontal: 3.w),
      width: isActive ? 16.w : 6.w,
      height: 6.h,
      decoration: BoxDecoration(
        color: isActive
            ? const Color.fromARGB(255, 92, 55, 67) // active: soft rose-pink
            : const Color(0xFFFCE4EC), // inactive: very light blush
        borderRadius: BorderRadius.circular(3.r),
      ),
    );
  }
}

// ─── Bottom Bar ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  const _BottomBar({
    required this.currentPage,
    required this.totalPages,
    required this.onSkip,
    required this.onNext,
  });

  bool get isLastPage => currentPage == totalPages - 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28.w, 6.h, 28.w, 22.h),
      child: isLastPage
          // ── Last page: full-width Get Started
          ? SizedBox(
              width: double.infinity,
              height: 38.h,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMaroon,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Get Started',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          // ── Other pages: Skip (plain text) + Next (filled maroon)
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 0,
                    ),
                    minimumSize: Size(80.w, 38.h),
                    backgroundColor: Colors.white.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22.r),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                ),

                // Next
                SizedBox(
                  height: 38.h,
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMaroon,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32.w,
                        vertical: 0,
                      ),
                      minimumSize: Size(90.w, 38.h),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
