import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';
import '../../buyer/pages/buyer_dashboard_page.dart';
import '../../seller/pages/seller_dashboard_page.dart';
import '../../volunteer/pages/volunteer_dashboard_page.dart';
import 'register_selection_page.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../core/localization/language_provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LanguageProvider>(context, listen: false)
          .confirmCurrentLanguage();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //-------------------------------------------------------------
  /// LOGIN
  //-------------------------------------------------------------

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AppAuthProvider>();

    try {
      final user = await auth.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        final role = await auth.getUserRole(user.uid);

        if (!mounted) return;

        Widget destination;

        switch (role?.toLowerCase()) {
          case 'seller':
            destination = const SellerDashboardPage();
            break;
          case 'volunteer':
            destination = const VolunteerDashboardPage();
            break;
          case 'buyer':
          default:
            destination = const BuyerDashboardPage();
            break;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      }
    } on fb.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  //-------------------------------------------------------------
  /// GOOGLE SIGN IN
  //-------------------------------------------------------------

  Future<void> _handleGoogleSignIn() async {
  if (_isLoading) return;

  setState(() => _isLoading = true);

  final auth = context.read<AppAuthProvider>();

  try {
    final user = await auth.signInWithGoogle();

    if (!mounted) return;

    if (user != null) {
      final role = await auth.getUserRole(user.uid);

      if (!mounted) return;

      Widget destination;

      switch (role?.toLowerCase()) {
        case 'seller':
          destination = const SellerDashboardPage();
          break;
        case 'volunteer':
          destination = const VolunteerDashboardPage();
          break;
        case 'buyer':
        default:
          destination = const BuyerDashboardPage();
          break;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    }
  } on fb.FirebaseAuthException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.message ?? "Google Sign-In Failed")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Google Sign-In Failed")),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  //-------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                "Login to continue your journey with Ahara and help the community.",
                style: TextStyle(
                  color: AppColors.textLight.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              _buildLabel("EMAIL ADDRESS"),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "name@example.com",
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  if (!value.contains('@')) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              _buildLabel("PASSWORD"),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your password";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
  width: double.infinity,
  height: 55,
  child: OutlinedButton(
    onPressed: _isLoading ? null : _handleGoogleSignIn,
    child: _isLoading
        ? const CircularProgressIndicator()
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                "https://cdn-icons-png.flaticon.com/512/2991/2991148.png",
                height: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                "Sign in with Google",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
  ),
),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterSelectionPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(label,
          style: Theme.of(context).textTheme.labelMedium),
    );
  }
}
