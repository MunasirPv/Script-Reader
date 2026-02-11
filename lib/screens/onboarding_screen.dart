import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'script_entry_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ScriptEntryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(fontSize: 19.0, color: Colors.white70);

    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      bodyTextStyle: bodyStyle,
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Color(0xFF1E1E1E), // Dark background matching theme
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      globalBackgroundColor: const Color(0xFF1E1E1E),
      allowImplicitScrolling: true,
      autoScrollDuration: 3000,
      infiniteAutoScroll: true,

      pages: [
        PageViewModel(
          title: "Write Your Script",
          body:
              "Type or paste your script directly into the app. Prepare your content with ease.",
          image: const Icon(
            Icons.edit_note,
            size: 100,
            color: Colors.tealAccent,
          ),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Record Like a Pro",
          body:
              "Read from the teleprompter while recording video. Control scroll speed and font size seamlessly.",
          image: const Icon(Icons.videocam, size: 100, color: Colors.redAccent),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "System Overlay",
          body:
              "Use the floating teleprompter over any other camera app for maximum flexibility.",
          image: const Icon(Icons.layers, size: 100, color: Colors.blueAccent),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Review & Share",
          body:
              "Watch your recordings instantly in the gallery and share them with the world.",
          image: const Icon(
            Icons.video_library,
            size: 100,
            color: Colors.amberAccent,
          ),
          decoration: pageDecoration,
        ),
      ],
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context), // You can override onSkip callback
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      showBackButton: false,
      //rtl: true, // Display as right-to-left
      back: const Icon(Icons.arrow_back, color: Colors.white),
      skip: const Text(
        'Skip',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      next: const Icon(Icons.arrow_forward, color: Colors.white),
      done: const Text(
        'Done',
        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Colors.white54,
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Colors.tealAccent,
      ),
    );
  }
}
