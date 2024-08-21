import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const ThimblesGame());
}

class ThimblesGame extends StatelessWidget {
  const ThimblesGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thimbles Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ThimblesHomePage(),
    );
  }
}

class ThimblesHomePage extends StatefulWidget {
  const ThimblesHomePage({super.key});

  @override
  _ThimblesHomePageState createState() => _ThimblesHomePageState();
}

class _ThimblesHomePageState extends State<ThimblesHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _positionAnimations;
  late Animation<Offset> _liftAnimation;
  List<int> cupOrder = [0, 1, 2];
  int ballPosition = 0;
  int liftedCupIndex = -1;
  bool isShuffling = false;
  bool isGuessing = false;
  String message = '';
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    initializeAnimations();
  }

  void initializeAnimations() {
    _positionAnimations = List.generate(3, (_) =>
        Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 0))
            .animate(_controller));

    _liftAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -1.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void startShuffle() async {
    setState(() {
      isShuffling = true;
      isGuessing = false;
      liftedCupIndex = -1;
      message = '';
      ballPosition = random.nextInt(3);
    });

    for (int i = 0; i < 5; i++) {
      await shuffleOnce();
    }

    setState(() {
      isShuffling = false;
      isGuessing = true;
      resetCupPositions();
    });
  }

  Future<void> shuffleOnce() async {
    int firstCup = random.nextInt(3);
    int secondCup = (firstCup + random.nextInt(2) + 1) % 3;

    Offset firstCupOffset = getCupPosition(firstCup);
    Offset secondCupOffset = getCupPosition(secondCup);

    _positionAnimations[firstCup] = Tween<Offset>(
      begin: firstCupOffset,
      end: secondCupOffset,
    ).animate(_controller);

    _positionAnimations[secondCup] = Tween<Offset>(
      begin: secondCupOffset,
      end: firstCupOffset,
    ).animate(_controller);

    _controller.reset();
    await _controller.forward();

    setState(() {
      int temp = cupOrder[firstCup];
      cupOrder[firstCup] = cupOrder[secondCup];
      cupOrder[secondCup] = temp;
    });
  }

  void resetCupPositions() {
    _positionAnimations = List.generate(3, (index) =>
        Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 0))
            .animate(_controller));

    _controller.reset();
    _controller.forward();
  }

  Offset getCupPosition(int index) {
    // Calculate positions based on screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double offset = (screenWidth - 300) / 2; // Adjust the offset based on your cup size

    switch (index) {
      case 0:
        return  Offset(-(offset / 100), 0);
      case 1:
        return const Offset(0, 0);
      case 2:
        return Offset((offset / 100), 0);
      default:
        return const Offset(0, 0);
    }
  }

  void selectCup(int index) {
    if (!isGuessing) return;

    setState(() {
      isGuessing = false;
      liftedCupIndex = index;

      if (cupOrder[index] == ballPosition) {
        message = 'You guessed right!';
      } else {
        message = 'Wrong guess! Try again.';
      }

      _controller.reset();
      _controller.forward();
    });
  }

  Widget buildCup(int index) {
    return GestureDetector(
      onTap: () => selectCup(index),
      child: SlideTransition(
        position: _positionAnimations[index],
        child: SlideTransition(
          position: index == liftedCupIndex ? _liftAnimation : const AlwaysStoppedAnimation(Offset(0, 0)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/cup.png',
                width: 100,
              ),
              if (index == liftedCupIndex && cupOrder[index] == ballPosition)
                Positioned(
                  bottom: -50,
                  child: Image.asset(
                    'assets/ball.png',
                    width: 30,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thimbles Game'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Find the ball!',
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 50),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => buildCup(index)),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: isShuffling || isGuessing ? null : startShuffle,
            child: const Text('Shuffle Cups'),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: const TextStyle(fontSize: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
