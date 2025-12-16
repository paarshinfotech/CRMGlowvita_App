import 'package:flutter/material.dart';
import 'widgets/custom_drawer.dart';

class ShippingPage extends StatefulWidget {
  const ShippingPage({super.key});

  @override
  State<ShippingPage> createState() => _ShippingConfigPageState();
}

enum ChargeType { fixed, percent }

class _ShippingConfigPageState extends State<ShippingPage> {
  bool enableShipping = true;
  ChargeType chargeType = ChargeType.fixed;
  final TextEditingController amountCtrl = TextEditingController(text: '80');

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    // TODO: persist settings or call API
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shipping settings saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(currentPage: 'Shipping'),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: const Text('Shipping Configuration',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final isMobile = c.maxWidth < 600;
          final cardPadding = EdgeInsets.all(isMobile ? 10 : 16);
          final fieldPadding = EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 16,
            vertical: isMobile ? 8 : 10,
          );

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 10 : 20),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0.8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + subtitle
                    Text('Shipping Charges',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      'Set up how you want to charge for shipping on product orders.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: isMobile ? 10 : 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Enable toggle (adaptive)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile.adaptive(
                        contentPadding: fieldPadding,
                        title: const Text('Enable Shipping Charges',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            )),
                        value: enableShipping,
                        onChanged: (v) => setState(() => enableShipping = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Charge Type
                    Text('Charge Type',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 12 : 13,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
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
                    const SizedBox(height: 16),

                    // Amount
                    Text('Amount',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: isMobile ? 12 : 13,
                        )),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountCtrl,
                      enabled: enableShipping,
                      keyboardType: const TextInputType.numberWithOptions(
                          signed: false, decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
                          child: Text(
                            chargeType == ChargeType.fixed ? '₹' : '%',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText:
                            chargeType == ChargeType.fixed ? '80' : '5',
                        filled: true,
                        fillColor:
                            enableShipping ? Colors.white : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: Colors.grey.shade300, width: 1),
                        ),
                        contentPadding: fieldPadding,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Save button aligned right on wide, full width on mobile
                    Align(
                      alignment: isMobile
                          ? Alignment.center
                          : Alignment.centerRight,
                      child: SizedBox(
                        width: isMobile ? double.infinity : null,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 16 : 20,
                                vertical: isMobile ? 14 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Save Changes',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                          )),
                        ),
                      ),
                    ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onChanged == null ? null : () => onChanged!(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F0FE) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF2563EB) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<T>(
              value: value,
              activeColor: Colors.blue,
              groupValue: groupValue,
              onChanged: onChanged,
              toggleable: false,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
