import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/custom_drawer.dart';

class ReferralProg extends StatelessWidget {
  const ReferralProg({super.key});

  @override
  Widget build(BuildContext context) {
    Color lightBlue = const Color(0xFFF1F6FF);
    Color cardBlue = Theme.of(context).primaryColor;
    double cardPadding = 16.0;

    return Scaffold(
      drawer: const CustomDrawer(currentPage: 'Referrals'),
      backgroundColor: lightBlue,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 45),
                    Container(
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: AssetImage('assets/images/referrals.png'),
                          fit: BoxFit.cover,
                          opacity: 0.2, // Optional: lower to make text pop more
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: cardBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Refer & Earn",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Invite your friends to GlowvitaSalon",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.currency_rupee,
                                            size: 15, color: Colors.black87),
                                        const SizedBox(width: 2),
                                        const Expanded(
                                          child: Text(
                                            "Earn a commission on every completed online purchase of a GlowvitaSalon service.",
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      "OR",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      "Invite salons to GlowvitaSalon CRM and earn a commission when they sell any GlowvitaSalon service online.",
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              width: 220,
                              height: 40,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(Icons.share,
                                    color: Theme.of(context).primaryColor,
                                    size: 17),
                                label: Text(
                                  'Share Now',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                onPressed: () {
                                  //  share
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Stats grid
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 9,
                      mainAxisSpacing: 9,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _statTile(Icons.person_outline, "Your commission", "0",
                            cardBlue),
                        _statTile(Icons.currency_rupee, "Total commission",
                            "0.00", cardBlue),
                        _statTile(Icons.timer_rounded, "Current commission",
                            "0.00", cardBlue),
                        _statTile(Icons.currency_rupee, "Current month invites",
                            "0", cardBlue),
                        _statTile(Icons.timer, "Total invites", "0", cardBlue),
                        Container(), // Empty for grid symmetry
                      ],
                    ),
                    const SizedBox(height: 18),
                    _criteriaCard(context),
                    const SizedBox(height: 22),
                    _referralDetailsCard(context, cardBlue),
                    const SizedBox(height: 22),
                    _rewardsCard(context, cardBlue),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black87, size: 29),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  tooltip: 'Menu',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(IconData icon, String label, String value, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.09),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 15, color: iconColor, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  Widget _criteriaCard(BuildContext context) {
    Widget _numberCircle(BuildContext context, String number) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          number,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Criteria for New Referrals",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: Colors.black54,
            iconColor: Colors.black54,
            title: Row(
              children: [
                _numberCircle(context, "1"),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "New Users Only",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  "The person you're sharing the link to cannot have any existing account at GlowvitaSalon.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: Colors.black54,
            iconColor: Colors.black54,
            title: Row(
              children: [
                _numberCircle(context, "2"),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Service Purchases Only",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  "Points are only eligible for first-time purchases of Service. Cancelled appointments do not qualify.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: Colors.black54,
            iconColor: Colors.black54,
            title: Row(
              children: [
                _numberCircle(context, "3"),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "How is the commission used",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  "Some amount of commission can be redeemed while booking appointment at any salon. Remaining amount should be paid by you.",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _referralDetailsCard(BuildContext context, Color cardBlue) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Reference Details",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          const Text(
            "Your Referral Code",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _copyRow(context, value: "CRM242", icon: Icons.copy_rounded),
          const SizedBox(height: 20),
          const Text(
            "Your Referral Link",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _copyRow(context,
              value: "https://www.glowvitasalon.com?ref=CRM242",
              icon: Icons.copy_rounded),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cardBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7)),
                  ),
                  icon: const Icon(Icons.share, color: Colors.white, size: 18),
                  label: const Text('Share via Social Media',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _copyRow(BuildContext context,
      {required String value, required IconData icon}) {
    return Transform.translate(
      offset: Offset(10, 7),
      child: Container(
        height: 80, // Taller to fit text and icon nicely
        width: 400,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/coupon.png'),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(icon, size: 24, color: Colors.white),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Copied to clipboard!"),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardsCard(BuildContext context, Color cardBlue) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rewards You'll Both Receive",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
              shadows: [
                Shadow(
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.3),
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.5,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _rewardTile(
                  context,
                  Icons.percent,
                  "20% Discount",
                  "Your friend gets 20% off their first course purchase",
                  cardBlue),
              _rewardTile(
                  context,
                  Icons.currency_rupee_rounded,
                  "₹500 Cashback",
                  "You earn ₹500 when your friend completes their first course",
                  cardBlue),
              _rewardTile(context, Icons.all_inclusive, "Unlimited Referrals",
                  "No limit on referrals", cardBlue),
              _rewardTile(context, Icons.flash_on, "Quick Rewards",
                  "Rewards credited within 48 hours ", cardBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rewardTile(BuildContext context, IconData icon, String title,
      String subtitle, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FD),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 9),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
