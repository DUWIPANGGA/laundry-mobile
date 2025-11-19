import 'package:flutter/material.dart';
import 'package:laundry_mobile/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final bool fromRegistration;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
    this.fromRegistration = false,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  String _message = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _setupOtpListeners();
  }

  void _setupOtpListeners() {
    for (int i = 0; i < _otpControllers.length; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1 && i < _otpControllers.length - 1) {
          _focusNodes[i + 1].requestFocus();
        }
        
        // Auto verify when all fields are filled
        if (_isOtpComplete() && !_isLoading) {
          _verifyOtp();
        }
      });
    }
  }

  bool _isOtpComplete() {
    return _otpControllers.every((controller) => controller.text.isNotEmpty);
  }

  String _getOtp() {
    return _otpControllers.map((controller) => controller.text).join();
  }

  Future<void> _verifyOtp() async {
    if (!_isOtpComplete()) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _isError = false;
    });

    final otp = _getOtp();
    
    final result = await AuthService.verifyEmail(widget.email, otp);
    
    setState(() {
      _isLoading = false;
      _message = result['message'] ?? '';
      _isError = !(result['success'] ?? false);
    });

    if (result['success'] == true) {
      // Navigate to dashboard after successful verification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/dashboard', 
          (route) => false
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Email berhasil diverifikasi!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
      _message = '';
      _isError = false;
    });

    final result = await AuthService.resendOtp(widget.email);
    
    setState(() {
      _isResending = false;
      _message = result['message'] ?? '';
      _isError = !(result['success'] ?? false);
    });

    if (result['success'] == true) {
      // Clear OTP fields
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3498db),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 40,
                  color: Color(0xFF3498db),
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text(
                'Verifikasi Email',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Kode OTP telah dikirim ke:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Masukkan 6-digit kode OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // OTP Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40,
                          height: 50,
                          child: TextField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF3498db),
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Message
                    if (_message.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isError ? Icons.error_outline : Icons.info_outline,
                              color: _isError ? Colors.red : Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _message,
                                style: TextStyle(
                                  color: _isError ? Colors.red : Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isOtpComplete() ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3498db),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verifikasi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Tidak menerima kode?',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: _isResending ? null : _resendOtp,
                          child: _isResending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Kirim Ulang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3498db),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}