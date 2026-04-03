import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/subscribe/payment-success.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
const _kPrimary = Color(0xFF185FA5);
const _kPrimaryLight = Color(0xFFE6F1FB);
const _kGold = Color(0xFFBA7517);
const _kGoldLight = Color(0xFFFAEEDA);
const _kSurface = Color(0xFFF4F6FB);
const _kCard = Colors.white;
const _kText = Color(0xFF0D1B2A);
const _kSub = Color(0xFF6B7A99);
const _kBorder = Color(0xFFE2EAF4);
const _kGreen = Color(0xFF3B6D11);
const _kGreenLight = Color(0xFFEAF3DE);

class PaymentCardPage extends StatefulWidget {
  final String price;
  final bool isYearly;
  const PaymentCardPage(
      {Key? key, required this.price, this.isYearly = false})
      : super(key: key);

  @override
  State<PaymentCardPage> createState() => _PaymentCardPageState();
}

class _PaymentCardPageState extends State<PaymentCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _isLoading = false;
  int _selectedMethod = 0; // 0=card, 1=promptpay

  final List<Map<String, dynamic>> _paymentMethods = [
    {'label': 'บัตรเครดิต/เดบิต', 'icon': Icons.credit_card_rounded},
    {'label': 'PromptPay', 'icon': Icons.qr_code_rounded},
  ];

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  String _formatCardNumber(String value) {
    value = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < value.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(value[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    value = value.replaceAll('/', '');
    if (value.length >= 2) {
      return '${value.substring(0, 2)}/${value.substring(2)}';
    }
    return value;
  }

  Future<void> _submit() async {
    if (_selectedMethod == 0 && !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // simulate API
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
              price: widget.price, isYearly: widget.isYearly)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      // appBar: AppBar(
      //   backgroundColor: _kCard,
      //   elevation: 0,
      //   leading: IconButton(
      //     icon: const Icon(Icons.arrow_back_ios_new_rounded,
      //         size: 18, color: _kText),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      //   title: Text('ชำระเงิน',
      //       style: GoogleFonts.prompt(
      //           fontSize: 16, fontWeight: FontWeight.w600, color: _kText)),
      //   centerTitle: true,
      //   actions: [
      //     Padding(
      //       padding: const EdgeInsets.only(right: 16),
      //       child: Row(children: [
      //         const Icon(Icons.lock_rounded, size: 14, color: _kGreen),
      //         const SizedBox(width: 4),
      //         Text('SSL',
      //             style: GoogleFonts.prompt(
      //                 fontSize: 11,
      //                 fontWeight: FontWeight.w600,
      //                 color: _kGreen)),
      //       ]),
      //     ),
      //   ],
      // ),
      appBar: appBar(
        title: "ชำระเงิน",
        backBtn: true,
        rightBtn: false,
        backAction: () => goBack(),
        rightAction: () => {},
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // ── Payment method selector ──
          Row(
            children: _paymentMethods.asMap().entries.map((e) {
              final selected = _selectedMethod == e.key;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMethod = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: e.key == 0 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimaryLight : _kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? _kPrimary : _kBorder,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(children: [
                      Icon(e.value['icon'] as IconData,
                          size: 22,
                          color: selected ? _kPrimary : _kSub),
                      const SizedBox(height: 4),
                      Text(e.value['label'] as String,
                          style: GoogleFonts.prompt(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected ? _kPrimary : _kSub)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // ── Order summary mini ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kPrimary.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pro Plan · ${widget.isYearly ? "รายปี" : "รายเดือน"}',
                    style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary)),
                Text(widget.price,
                    style: GoogleFonts.prompt(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary)),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_selectedMethod == 0) ...[
            // ── Card form ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('หมายเลขบัตร'),
                      const SizedBox(height: 6),
                      _cardInput(
                        controller: _cardNumberCtrl,
                        hint: '0000 0000 0000 0000',
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        prefixIcon: Icons.credit_card_rounded,
                        onChanged: (v) {
                          final formatted = _formatCardNumber(
                              v.replaceAll(' ', ''));
                          if (formatted != v) {
                            _cardNumberCtrl.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                        },
                        validator: (v) => (v ?? '').replaceAll(' ', '').length < 16
                            ? 'กรุณากรอกหมายเลขบัตรให้ครบ'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _label('ชื่อบนบัตร'),
                      const SizedBox(height: 6),
                      _cardInput(
                        controller: _nameCtrl,
                        hint: 'FIRSTNAME LASTNAME',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) => (v ?? '').isEmpty
                            ? 'กรุณากรอกชื่อบนบัตร'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('วันหมดอายุ'),
                                const SizedBox(height: 6),
                                _cardInput(
                                  controller: _expiryCtrl,
                                  hint: 'MM/YY',
                                  keyboardType: TextInputType.number,
                                  maxLength: 5,
                                  onChanged: (v) {
                                    final formatted = _formatExpiry(
                                        v.replaceAll('/', ''));
                                    if (formatted != v) {
                                      _expiryCtrl.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                            offset: formatted.length),
                                      );
                                    }
                                  },
                                  validator: (v) => (v ?? '').length < 5
                                      ? 'MM/YY'
                                      : null,
                                ),
                              ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('CVV'),
                                const SizedBox(height: 6),
                                _cardInput(
                                  controller: _cvvCtrl,
                                  hint: '•••',
                                  keyboardType: TextInputType.number,
                                  maxLength: 3,
                                  obscure: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  validator: (v) => (v ?? '').length < 3
                                      ? 'CVV ไม่ถูกต้อง'
                                      : null,
                                ),
                              ]),
                        ),
                      ]),
                    ]),
              ),
            ),
          ] else ...[
            // ── PromptPay QR ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: Column(children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Center(
                    child: Icon(Icons.qr_code_rounded,
                        size: 100, color: _kText),
                  ),
                ),
                const SizedBox(height: 14),
                Text('สแกน QR เพื่อชำระเงิน',
                    style: GoogleFonts.prompt(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kText)),
                const SizedBox(height: 4),
                Text('QR มีอายุ 15 นาที',
                    style: GoogleFonts.prompt(
                        fontSize: 12, color: _kSub)),
              ]),
            ),
          ],

          const SizedBox(height: 20),

          // ── Submit button ──
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kPrimary.withOpacity(0.6),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text('ยืนยันการชำระเงิน ${widget.price}',
                      style: GoogleFonts.prompt(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: GoogleFonts.prompt(
          fontSize: 12, fontWeight: FontWeight.w600, color: _kText));

  Widget _cardInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool obscure = false,
    IconData? prefixIcon,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.prompt(fontSize: 14, color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.prompt(fontSize: 14, color: _kSub),
        counterText: '',
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _kSub)
            : null,
        filled: true,
        fillColor: _kSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
      ),
    );
  }

  void goBack() async {
    Navigator.pop(context, false);
  }

}