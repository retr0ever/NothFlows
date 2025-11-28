import 'package:flutter_test/flutter_test.dart';
import 'package:nothflows/services/cactus_llm_service.dart';
import 'package:nothflows/services/automation_executor.dart';
import 'package:nothflows/models/flow_dsl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Local Simulation Tests', () {
    test('Full flow simulation: Parse and Execute', () async {
      print('\n=== NothFlows Simulation Test ===');
      
      print('1. Initializing Services...');
      final llmService = CactusLLMService();
      final executor = AutomationExecutor();
      
      // This should trigger the simulation mode on non-Android platforms
      await llmService.initialise();
      expect(llmService.isReady, true, reason: 'Service should be ready in simulation mode');
      
      print('2. Parsing instruction (Simulation Mode)...');
      // Complex instruction to test keyword matching in simulation
      const instruction = "When sleep mode is on, clean screenshots older than 30 days, mute instagram, and lower brightness to 20";
      const mode = "sleep";
      
      final flow = await llmService.parseInstruction(
        instruction: instruction,
        mode: mode,
      );
      
      expect(flow, isNotNull, reason: 'Flow should be parsed successfully');
      print('   Parsed Trigger: ${flow!.trigger}');
      print('   Parsed Actions: ${flow.actions.length}');
      
      // Verify simulated parsing logic matches keywords
      final actionTypes = flow.actions.map((a) => a.type).toList();
      print('   Action Types: $actionTypes');
      
      expect(actionTypes, contains('clean_screenshots'));
      expect(actionTypes, contains('mute_apps'));
      expect(actionTypes, contains('lower_brightness'));
      
      print('3. Executing Flow (Simulation Mode)...');
      final results = await executor.executeFlow(flow);
      
      expect(results.length, flow.actions.length);
      
      for (final result in results) {
        print('   [${result.success ? "PASS" : "FAIL"}] ${result.actionType}: ${result.message}');
        expect(result.success, true);
        expect(result.message, contains('[SIM]'), reason: 'Message should indicate simulation');
      }
      
      print('=== Test Completed Successfully ===\n');
    });
  });
}
