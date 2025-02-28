import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/auto3.png',
      'title': 'Conéctate con el mundo',
      'description': 'Comparte momentos y descubre historias increíbles.'
    },
    {
      'image': 'assets/auto2.png',
      'title': 'Explora contenido único',
      'description': 'Sigue a tus amigos y mantente informado.'
    },
    {
      'image': 'assets/auto4.png',
      'title': 'Únete ahora',
      'description': 'Regístrate y forma parte de nuestra comunidad.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(_pages[index]['image']!, height: 300),
                  const SizedBox(height: 20),
                  Text(
                    _pages[index]['title']!,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      _pages[index]['description']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 30,
            right: 30,
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage == _pages.length - 1) {
                  Navigator.pushReplacementNamed(context, '/login');
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Empezar' : 'Siguiente',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
