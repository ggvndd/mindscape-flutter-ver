#!/usr/bin/env python3
"""
Static validation test for Mindbot enhanced prompts.
Validates system prompts contain required CBT and trigger identification elements
WITHOUT requiring Gemini API calls.
"""

import re
import json
from pathlib import Path
from datetime import datetime

class StaticPromptValidator:
    """Validates system prompts contain required sections and language patterns"""
    
    def __init__(self):
        self.results = []
        self.project_root = Path(__file__).parent
        
    def load_dart_file(self, filepath):
        """Load and extract string literals from Dart files"""
        try:
            with open(self.project_root / filepath, 'r') as f:
                return f.read()
        except FileNotFoundError:
            print(f"❌ File not found: {filepath}")
            return None
    
    def extract_system_prompt(self, content, prompt_name):
        """Extract system prompt from Dart string concatenation"""
        # Look for the system prompt pattern
        pattern = rf"{prompt_name}\s*=\s*'(.*?)(?=\n\s*(?:_|static|GeminiChatService|void|\}}|const))"
        match = re.search(pattern, content, re.DOTALL)
        if match:
            prompt_text = match.group(1)
            # Unescape common Dart escapes
            prompt_text = prompt_text.replace("\\n", "\n")
            prompt_text = prompt_text.replace("\\'", "'")
            prompt_text = prompt_text.replace("\\\\", "\\")
            return prompt_text
        return None
    
    def check_patterns(self, prompt_text, required_patterns, test_name):
        """Check if prompt contains all required patterns"""
        passed = True
        details = []
        
        for pattern_name, pattern in required_patterns.items():
            found = bool(re.search(pattern, prompt_text, re.IGNORECASE))
            if found:
                details.append(f"  ✅ Contains: {pattern_name}")
            else:
                details.append(f"  ❌ Missing: {pattern_name}")
                passed = False
        
        self.results.append({
            'test': test_name,
            'passed': passed,
            'details': details
        })
        
        return passed
    
    def test_core_gemini_prompt(self):
        """Test core GeminiChatService system prompt"""
        print("\n🧪 Test 1: Core GeminiChatService System Prompt")
        print("─" * 60)
        
        content = self.load_dart_file("lib/core/services/gemini_chat_service.dart")
        if not content:
            return False
        
        # Extract the prompt
        prompt = self.extract_system_prompt(content, "_systemPrompt")
        
        if not prompt:
            print("❌ Could not extract system prompt")
            return False
        
        required = {
            "CBT Section": r"IDENTIFIKASI TRIGGER DAN SELF-MONITORING",
            "Trigger Keywords": r"trigger|pola|pattern",
            "Connect Emotions": r"connect|jadi.*overwhelmed",
            "Self-Monitoring Reinforcement": r"Good job|first step",
            "Normalize Uncertainty": r"kadang sulit|okay",
            "Format Rules": r"Maksimal 2 paragraf",
            "Crisis Protocol": r"ATURAN KEAMANAN|self-harm|suicide",
        }
        
        passed = self.check_patterns(prompt, required, "Core Gemini System Prompt")
        
        if passed:
            print("✅ All required CBT and trigger identification elements present!")
        
        return passed
    
    def test_data_gemini_prompt(self):
        """Test data GeminiChatService default prompt"""
        print("\n🧪 Test 2: Data GeminiChatService Default Prompt")
        print("─" * 60)
        
        content = self.load_dart_file("lib/data/services/gemini_chat_service.dart")
        if not content:
            return False
        
        prompt = self.extract_system_prompt(content, "_defaultSystemPrompt")
        
        if not prompt:
            print("❌ Could not extract system prompt")
            return False
        
        required = {
            "CBT Expertise": r"Cognitive Behavioral|self-monitoring|trigger identification",
            "Trigger Identification Section": r"Trigger Identification.*PENTING",
            "Pattern Recognition": r"pattern|notice|trend",
            "Self-Monitoring Messages": r"Good job noticing",
            "Normalize Uncertainty": r"kadang sulit|That's okay",
            "Crisis Handling": r"diagnosa medis|psikologis|professional",
        }
        
        passed = self.check_patterns(prompt, required, "Data Gemini Default Prompt")
        
        if passed:
            print("✅ All CBT and self-monitoring principles integrated!")
        
        return passed
    
    def test_gemma_standard_ui(self):
        """Test Gemma mood response standard UI prompt"""
        print("\n🧪 Test 3: Gemma Mood Response Standard UI")
        print("─" * 60)
        
        content = self.load_dart_file("lib/core/services/gemma_mood_response_service.dart")
        if not content:
            return False
        
        # Find the standard UI prompt
        pattern = r"prompt\s*=\s*'(.*?)Balas sekarang:'"
        matches = re.finditer(pattern, content, re.DOTALL)
        
        found_standard = False
        for match in matches:
            prompt_text = match.group(1)
            if "Standard UI" in prompt_text or "mood berubah" in prompt_text:
                found_standard = True
                break
        
        if not found_standard:
            print("❌ Could not find standard UI prompt")
            return False
        
        required = {
            "Trigger Identification": r"trigger identification",
            "Mood Change Detection": r"mood berubah|mood shift",
            "Questioning Triggers": r"Apa yang happened|bikin kamu",
            "Acknowledge Triggers": r"Good observation|Knowing",
            "Helpful Questions": r"pertanyaan.*helpful|relevant",
        }
        
        passed = self.check_patterns(prompt_text, required, "Gemma Standard UI Prompt")
        
        return passed
    
    def test_gemma_rush_hour_ui(self):
        """Test Gemma mood response rush hour UI prompt"""
        print("\n🧪 Test 4: Gemma Mood Response Rush Hour UI")
        print("─" * 60)
        
        content = self.load_dart_file("lib/core/services/gemma_mood_response_service.dart")
        if not content:
            return False
        
        # Find the rush hour prompt
        if "Rush Hour Mode" not in content:
            print("❌ Rush Hour Mode prompt not found")
            return False
        
        pattern = r"'SITUASI: User sedang dalam Rush Hour Mode.*?Balas sekarang:'"
        match = re.search(pattern, content, re.DOTALL)
        
        if not match:
            print("❌ Could not extract rush hour prompt")
            return False
        
        prompt_text = match.group(0)
        
        required = {
            "Max 2 Sentences": r"MAKSIMAL 2 kalimat",
            "Acknowledge Busy": r"sibuk|busy",
            "Validation": r"validasi|hangat",
            "Trigger Cue": r"trigger cue|rush hour mode",
            "No Open Questions": r"JANGAN tanya.*terbuka",
        }
        
        passed = self.check_patterns(prompt_text, required, "Gemma Rush Hour UI Prompt")
        
        return passed
    
    def test_file_structure(self):
        """Test that required files exist and contain proper structure"""
        print("\n🧪 Test 5: File Structure & Organization")
        print("─" * 60)
        
        required_files = [
            "lib/core/services/gemini_chat_service.dart",
            "lib/data/services/gemini_chat_service.dart",
            "lib/core/services/gemma_mood_response_service.dart",
        ]
        
        passed = True
        for filepath in required_files:
            full_path = self.project_root / filepath
            if full_path.exists():
                size = full_path.stat().st_size
                print(f"  ✅ {filepath} ({size} bytes)")
            else:
                print(f"  ❌ {filepath} not found")
                passed = False
        
        self.results.append({
            'test': "File Structure",
            'passed': passed,
            'details': []
        })
        
        return passed
    
    def run_all_tests(self):
        """Run all validation tests"""
        print("\n" + "=" * 60)
        print("MINDBOT ENHANCED PROMPTS - STATIC VALIDATION TEST")
        print("=" * 60)
        print(f"Testing at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        try:
            results = [
                self.test_core_gemini_prompt(),
                self.test_data_gemini_prompt(),
                self.test_gemma_standard_ui(),
                self.test_gemma_rush_hour_ui(),
                self.test_file_structure(),
            ]
            
            # Print summary
            print("\n" + "=" * 60)
            print("TEST RESULTS SUMMARY")
            print("=" * 60)
            
            for result in self.results:
                status = "✅" if result['passed'] else "❌"
                print(f"\n{status} {result['test']}")
                for detail in result['details']:
                    print(detail)
            
            passed_count = sum(1 for r in results if r)
            total_count = len(results)
            
            print("\n" + "=" * 60)
            print(f"Results: {passed_count}/{total_count} tests passed")
            print("=" * 60)
            
            if passed_count == total_count:
                print("\n🎉 All static validation tests passed!")
                print("Your enhanced prompts contain all required CBT and trigger")
                print("identification elements.\n")
                return 0
            else:
                print(f"\n⚠️  {total_count - passed_count} test(s) need attention.")
                return 1
                
        except Exception as e:
            print(f"\n❌ Error during testing: {e}")
            import traceback
            traceback.print_exc()
            return 1


if __name__ == '__main__':
    import sys
    validator = StaticPromptValidator()
    exit_code = validator.run_all_tests()
    sys.exit(exit_code)
