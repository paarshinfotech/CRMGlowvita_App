import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'supp_drawer.dart';

class SuppShippingPage extends StatefulWidget {
  const SuppShippingPage({super.key});
  @override
  State<SuppShippingPage> createState() => _SuppShippingConfigPageState();
}

enum ChargeType { fixed, percent }

class _SuppShippingConfigPageState extends State<SuppShippingPage> {
  bool enableShipping = true;
  ChargeType chargeType = ChargeType.fixed;
  final TextEditingController amountCtrl = TextEditingController(text: '80');

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shipping settings saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SupplierDrawer(currentPage: 'Shipping'),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Text(
          'Shipping Configuration',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 16,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final cardPadding = EdgeInsets.all(isMobile ? 10 : 16);
          final fieldPadding = EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 10 : 20),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Shipping Charges',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Configure how you want to charge customers for shipping your products.',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 11 : 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Enable Shipping Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: fieldPadding,
                        title: Text(
                          'Enable Shipping Charges',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Turn off to offer free shipping on all orders',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.grey.shade600),
                        ),
                        value: enableShipping,
                        activeColor: Theme.of(context).primaryColor,
                        onChanged: (v) => setState(() => enableShipping = v),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Charge Type
                    Text(
                      'Charge Type',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        _RadioPill<ChargeType>(
                          title: 'Fixed Amount (₹)',
                          value: ChargeType.fixed,
                          groupValue: chargeType,
                          onChanged: enableShipping
                              ? (v) => setState(() => chargeType = v!)
                              : null,
                        ),
                        _RadioPill<ChargeType>(
                          title: 'Percentage (%)',
                          value: ChargeType.percent,
                          groupValue: chargeType,
                          onChanged: enableShipping
                              ? (v) => setState(() => chargeType = v!)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Amount Field
                    Text(
                      'Shipping Amount',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      enabled: enableShipping,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 6),
                          child: Text(
                            chargeType == ChargeType.fixed ? '₹' : '%',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: chargeType == ChargeType.fixed
                            ? 'e.g., 80'
                            : 'e.g., 5',
                        hintStyle: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.grey.shade500),
                        filled: true,
                        fillColor: enableShipping
                            ? Colors.white
                            : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor, width: 2),
                        ),
                        contentPadding: fieldPadding,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    Align(
                      alignment:
                          isMobile ? Alignment.center : Alignment.centerRight,
                      child: SizedBox(
                        width: isMobile ? double.infinity : 220,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RadioPill<T> extends StatelessWidget {
  final String title;
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  const _RadioPill({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final enabled = onChanged != null;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: enabled ? () => onChanged!(value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : (enabled ? Colors.grey.shade50 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<T>(
              value: value,
              groupValue: groupValue,
              activeColor: Theme.of(context).primaryColor,
              onChanged: enabled ? onChanged : null,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? (selected
                        ? Theme.of(context).primaryColor
                        : Colors.black87)
                    : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
