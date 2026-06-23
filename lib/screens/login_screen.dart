import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/gestantes_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  
  bool _senhaOculta = true;
  bool _isLoading = false;
  bool _isLoginMode = true; // Alterna entre Login e Cadastro

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _submeter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final provider = GestantesStateScope.of(context, listen: false);

    try {
      if (_isLoginMode) {
        // Realiza o Login
        await provider.fazerLogin(
          _emailController.text.trim(),
          _senhaController.text.trim(),
        );
      } else {
        // Realiza o Cadastro
        await provider.cadastrarUsuario(
          _emailController.text.trim(),
          _senhaController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso! Carregando dados...'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String msgErro = 'Ocorreu um erro. Tente novamente.';
        if (e.toString().contains('user-not-found')) {
          msgErro = 'Nenhum usuário cadastrado com este e-mail.';
        } else if (e.toString().contains('wrong-password')) {
          msgErro = 'Senha incorreta.';
        } else if (e.toString().contains('email-already-in-use')) {
          msgErro = 'Este e-mail já está sendo utilizado.';
        } else if (e.toString().contains('weak-password')) {
          msgErro = 'A senha deve conter pelo menos 6 caracteres.';
        } else if (e.toString().contains('invalid-email')) {
          msgErro = 'E-mail inválido.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msgErro),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite seu e-mail no campo acima para recuperar a senha.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final provider = GestantesStateScope.of(context, listen: false);
      await provider.recuperarSenha(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('E-mail de recuperação de senha enviado! Verifique sua caixa de entrada.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao enviar e-mail de recuperação. Verifique o e-mail digitado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade100,
              const Color(0xFFE8D3FC), // Lilás suave
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Efeitos visuais de esferas no fundo para enriquecer o glassmorphism
            Positioned(
              top: size.height * 0.15,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.pink.shade200.withAlpha(80),
                ),
              ),
            ),
            Positioned(
              bottom: size.height * 0.1,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC0A9FE).withAlpha(80), // Roxo suave
                ),
              ),
            ),
            
            // Formulário com efeito Glassmorphism
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.25),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.4),
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.05),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/nascermaisicon_login.png',
                              width: 200,  // Define a largura (substituindo o size do Icon)
                              height: 200, // Define a altura
                              fit: BoxFit.contain, // Garante que a imagem mude de tamanho sem distorcer
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isLoginMode ? 'Acessar Nascer+' : 'Criar Conta',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isLoginMode 
                                  ? 'Gerencie gestantes de qualquer lugar' 
                                  : 'Faça parte do aplicativo obstétrico',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 28),
                            
                            // Campo de E-mail
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon: const Icon(Icons.email_outlined, color: Colors.pink),
                                filled: true,
                                fillColor: const Color.fromRGBO(255, 255, 255, 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Digite seu e-mail';
                                if (!val.contains('@')) return 'E-mail inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Campo de Senha
                            TextFormField(
                              controller: _senhaController,
                              obscureText: _senhaOculta,
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                prefixIcon: const Icon(Icons.lock_outline, color: Colors.pink),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _senhaOculta ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.pink,
                                  ),
                                  onPressed: () {
                                    setState(() => _senhaOculta = !_senhaOculta);
                                  },
                                ),
                                filled: true,
                                fillColor: const Color.fromRGBO(255, 255, 255, 0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Digite sua senha';
                                if (val.length < 6) return 'Mínimo de 6 caracteres';
                                return null;
                              },
                            ),
                            
                            // Esqueci minha Senha (exibido apenas no modo login)
                            if (_isLoginMode)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _recuperarSenha,
                                  child: const Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(color: Colors.pink, fontSize: 12),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 24),
                            
                            // Botão de Envio
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submeter,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _isLoginMode ? 'Entrar' : 'Cadastrar',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Alternador entre Login e Cadastro
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLoginMode = !_isLoginMode;
                                });
                              },
                              child: Text(
                                _isLoginMode 
                                    ? 'Ainda não tem conta? Cadastre-se' 
                                    : 'Já possui conta? Faça Login',
                                style: const TextStyle(color: Colors.pink, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
