import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final TextEditingController _numberController = TextEditingController();
  String _method = 'M-Pesa';

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShayaScreenScaffold(
      title: 'Payment',
      subtitle:
          'Prepare the local payment flow while store billing is finalized.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'M-Pesa', label: Text('M-Pesa')),
              ButtonSegment(value: 'Card', label: Text('Card')),
              ButtonSegment(value: 'Airtel Money', label: Text('Airtel Money')),
            ],
            selected: {_method},
            onSelectionChanged: (selection) {
              setState(() => _method = selection.first);
            },
          ),
          const SizedBox(height: 12),
          ShayaTextField(
            controller: _numberController,
            label: _method == 'Card' ? 'Card reference' : 'Phone number',
            hint: _method == 'Card' ? '4111 1111 1111 1111' : '+255...',
          ),
          const SizedBox(height: 20),
          PrimaryGradientButton(
            label: 'Confirm payment',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Payment UI is ready. Gateway confirmation remains for Phase 3.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
