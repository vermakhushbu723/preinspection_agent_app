import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../state/claim_flow_provider.dart';

const _declarationText =
    'I hereby confirm that I have conducted the pre-inspection of the vehicle and '
    'personally captured the submitted photos/videos. The images/videos are genuine, '
    'captured at the stated location and time, and accurately represent the current '
    'condition concealed, altered, or misrepresented any visible damages. I understand '
    'that any false declaration or manipulation may lead to rejection of the '
    'inspection, blacklisting, and/or legal action.';

/// Port of `InspectorDeclarationPage.jsx`. The web version never renders
/// `AppHeader` on this route (it's imported but unused in the JSX) --
/// matched here by simply not including it.
class InspectorDeclarationPage extends ConsumerStatefulWidget {
  const InspectorDeclarationPage({super.key});

  @override
  ConsumerState<InspectorDeclarationPage> createState() => _InspectorDeclarationPageState();
}

class _InspectorDeclarationPageState extends ConsumerState<InspectorDeclarationPage> {
  bool _agreed = false;

  void _continue() {
    ref.read(claimFlowProvider.notifier).setInspectorDeclarationAccepted(true);
    context.go(AppRoutes.vehicleInformation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'INSPECTOR DECLARATION',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF111827), letterSpacing: 1.1),
              ),
              const SizedBox(height: 32),
              const Text(
                _declarationText,
                style: TextStyle(fontSize: 15, height: 1.8, color: Color(0xFF1F2937)),
              ),
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Row(
                    children: [
                      Checkbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false)),
                      const SizedBox(width: 2),
                      const Text('I Agree', style: TextStyle(fontSize: 14, color: Color(0xFF374151))),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: ElevatedButton(
                  onPressed: _agreed ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
