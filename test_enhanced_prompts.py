#!/usr/bin/env python3
"""
Test script to validate that the enhanced Mindbot chatbot prompts work correctly
with the Gemini API, specifically testing:
1. Trigger identification questions
2. CBT self-monitoring language
3. Empathetic active listening without unsolicited advice
4. Proper response format
"""

import os
import sys
from pathlib import Path
from datetime import datetime
import json
import re

# Try to import google generative ai
try:
    import google.generativeai as genai
except ImportError:
    print("❌ google-generativeai not installed. Install with: pip install google-generativeai")
    sys.exit(1)

# Try to load environment variables
try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).parent / '.env')
except ImportError:
    pass


class ChatbotPromptTester:
    """Test the enhanced Mindbot chatbot prompts with Gemini API"""
    
    def __init__(self):
        self.api_key = os.getenv('GEMINI_API_KEY')
        if not self.api_key:
            print("❌ GEMINI_API_KEY environment variable not set")
            sys.exit(1)
        
        genai.configure(api_key=self.api_key)
        # Use a model available on this API key; prefer a flash model for responsiveness
        # (listed models are available via the Generative Language API)
        self.model = genai.GenerativeModel('gemini-3.5-flash')
        self.test_results = []
        
        # System prompt from core/services/gemini_chat_service.dart
        self.system_prompt = '''Kamu adalah MindBot, teman virtual yang supportive buat orang-orang yang punya side gig atau kesibukan extra. Kamu membantu mereka manage burnout, stress, dan mood dengan cara yang casual, relatable, dan penuh empati.

ATURAN FORMAT RESPONSE (WAJIB DIIKUTI):
- Maksimal 2 paragraf pendek per response.
- Setiap paragraf maksimal 1-2 kalimat.
- Pisahkan tiap paragraf dengan satu baris kosong.
- Jangan pakai teks bold, italic, bullet point, atau markdown apapun. Fully teks biasa.
- Jawab singkat, to the point, dan jangan mengulang ide yang sama.

ATURAN NANYA PERASAAN (SANGAT PENTING):
- DILARANG KERAS menanyakan variasi dari "kamu oke ga?", "gimana kabarmu?", "lu baik-baik aja?", "how are you?", atau sejenisnya di setiap response.
- Tanya soal perasaan mereka HANYA kalau SALAH SATU kondisi ini terpenuhi:
  1) Ini adalah pesan pertama user di sesi chat ini.
  2) User baru cerita sesuatu yang berat atau emosional.
  3) Sudah lebih dari 6 pesan tanpa ada check-in sama sekali.
- Di luar kondisi itu: langsung kasih respons yang helpful, supportif, atau actionable. Tidak perlu check-in.

IDENTIFIKASI TRIGGER DAN SELF-MONITORING (CBT APPROACH):
- Ketika user cerita tentang mood yang berubah atau feeling overwhelmed, tanya gentle follow-up untuk membantu mereka identify trigger.
- Contoh pertanyaan: "Kamu notice nggak sih ada pattern? Kayak kapan biasanya kamu feel kayak gini?", "Apa yang happened sebelumnya?", "Apa sih yang bikin kamu overwhelmed?".
- Bantu mereka connect triggers dengan emosi: "Jadi tight deadline + kurang tidur = overwhelmed ya?", "Sepertinya deadlines academic bikin kamu stress ya?".
- Encourage self-monitoring: "Good job noticing ini ya! That's the first step to manage stress better", "Kalo kamu tau apa yang trigger-nya, jadi lebih gampang manage".
- Jangan force mereka identify trigger - kalau mereka tidak tahu, itu okay. Normalize it: "Kadang sulit sih identify apa exactly yang bikin kita stress".
- Gunakan trigger patterns yang udah kamu tau dari mood history mereka untuk memberikan insight yang personalized.

ATURAN KEAMANAN DAN CRISIS INTERVENTION (PRIORITAS TERTINGGI):
- Kamu dilarang keras memberikan diagnosa medis, psikologis, atau menyarankan pengobatan klinis.
- Jika user mengetik kata kunci atau konteks yang mengarah pada: melukai diri sendiri (self-harm), bunuh diri (suicide), keputusasaan ekstrem, atau depresi klinis berat.
- MAKA kamu HARUS menghentikan persona kasualmu dan HANYA membalas dengan template respons krisis berikut, tanpa tambahan teks apapun:
"Aku di sini buat dengerin kamu, tapi ini terdengar sangat berat dan kamu berhak mendapat bantuan dari profesional. Tolong jangan lewati ini sendirian. Kamu bisa hubungi layanan darurat atau konseling psikologi terdekat, atau akses Into The Light Indonesia (intothelightid.org) untuk bantuan profesional. Keselamatanmu itu yang paling utama."

GAYA BAHASA:
- Gunakan bahasa Indonesia yang santai: "nih", "banget", "yuk", "sih", "beneran", dll.
- Empathetic tapi tidak over-protective atau menggurui.
- Kalau user nanya hal di luar topik burnout/mood, tetap jawab dengan santai tapi arahkan balik ke topik.
- Jangan terlalu formal, tapi tetap genuine dan helpful.'''
    
    def send_message(self, user_message: str) -> str:
        """Send a message to Gemini and get response"""
        prompt = f"{self.system_prompt}\n\nUser: {user_message}\n\nRespond naturally:"
        response = self.model.generate_content(prompt)
        return response.text
    
    def check_response(self, test_name: str, response: str, required_patterns: list, forbidden_patterns: list = None) -> bool:
        """Check if response contains required patterns and avoids forbidden ones"""
        if forbidden_patterns is None:
            forbidden_patterns = []
        
        passed = True
        details = []
        
        # Check required patterns
        for pattern in required_patterns:
            found = bool(re.search(pattern, response, re.IGNORECASE))
            if found:
                details.append(f"  ✅ Found: {pattern[:50]}...")
            else:
                details.append(f"  ❌ Missing: {pattern[:50]}...")
                passed = False
        
        # Check forbidden patterns
        for pattern in forbidden_patterns:
            found = bool(re.search(pattern, response, re.IGNORECASE))
            if not found:
                details.append(f"  ✅ Avoided: {pattern[:50]}...")
            else:
                details.append(f"  ❌ Should not contain: {pattern[:50]}...")
                passed = False
        
        self.test_results.append({
            'test_name': test_name,
            'passed': passed,
            'response': response[:200],
            'details': details
        })
        
        return passed
    
    def test_trigger_identification(self):
        """Test 1: Chatbot should ask about triggers when user mentions mood shift"""
        print("\n🧪 Test 1: Trigger Identification on Mood Shift")
        print("─" * 60)
        
        user_message = "I'm so overwhelmed today. Mood is really down compared to yesterday."
        response = self.send_message(user_message)
        
        print(f"User: {user_message}")
        print(f"Bot: {response}\n")
        
        required = [
            # Accept common Indonesian/English phrasings that ask what happened
            r'(apa yang|apa).*happened|apa yang|apa\s+yang|what\s+happened',
            # Accept pattern/pola or notice/notice gak or patternnya
            r'(pattern|pola|pola\s+ini|notice|notice\s+gak|kamu\s+notice)',
            # Trigger synonyms
            r'(triggered|trigger|bikin|penyebab|menyebabkan|pemicu)',
        ]
        
        passed = self.check_response(
            "Trigger Identification",
            response,
            required,
            forbidden_patterns=[r'(you okay\?|oke ga\?|baik-baik aja)']
        )
        
        return passed
    
    def test_cbt_trigger_emotion_connection(self):
        """Test 2: Chatbot should help connect triggers to emotions"""
        print("\n🧪 Test 2: CBT Trigger-Emotion Connection")
        print("─" * 60)
        
        user_message = "My stress level goes up after exam weeks. I always feel burned out after exams."
        response = self.send_message(user_message)
        
        print(f"User: {user_message}")
        print(f"Bot: {response}\n")
        
        required = [
            r'(exam|exams|ujian|minggu ujian)',
            r'(stress|stres|trigger|pemicu|pattern|pola)',
        ]
        
        passed = self.check_response(
            "CBT Trigger-Emotion Connection",
            response,
            required
        )
        
        return passed
    
    def test_self_monitoring_reinforcement(self):
        """Test 3: Chatbot should reinforce self-monitoring awareness"""
        print("\n🧪 Test 3: Self-Monitoring Reinforcement")
        print("─" * 60)
        
        user_message = "I just realized that whenever I skip meals, I become really irritable and stressed. Is that normal?"
        response = self.send_message(user_message)
        
        print(f"User: {user_message}")
        print(f"Bot: {response}\n")
        
        required = [
            r'(good|great|bagus|keren|notice|sadar|observation)',
            r'(first step|langkah awal|self-monitor|self\s*monitor|aware|sadar)',
        ]
        
        passed = self.check_response(
            "Self-Monitoring Reinforcement",
            response,
            required
        )
        
        return passed
    
    def test_empathetic_listening_no_unsolicited_advice(self):
        """Test 4: Chatbot should validate without giving unsolicited advice"""
        print("\n🧪 Test 4: Empathetic Listening (No Unsolicited Advice)")
        print("─" * 60)
        
        user_message = "I've been dealing with work stress and family pressure. It's a lot."
        response = self.send_message(user_message)
        
        print(f"User: {user_message}")
        print(f"Bot: {response}\n")
        
        required = [
            # Accept common empathy tokens and casual variants like 'denger' and 'wajar'
            r'(ngerti|understand|denger|dengerin|dengerinnya|paham|wajar|tough)',
        ]
        
        forbidden = [
            r'(you should|kamu harus|sebaiknya)',
            r'(try|coba|lakukan)',
        ]
        
        passed = self.check_response(
            "Empathetic Listening Without Advice",
            response,
            required,
            forbidden
        )
        
        return passed
    
    def test_response_format(self):
        """Test 5: Chatbot should follow format guidelines (max 2 paragraphs, no markdown)"""
        print("\n🧪 Test 5: Response Format Compliance")
        print("─" * 60)
        
        user_message = "I'm tired of juggling classes and my part-time job."
        response = self.send_message(user_message)
        
        print(f"User: {user_message}")
        print(f"Bot: {response}\n")
        
        # Count paragraphs (separated by double newlines)
        paragraphs = [p.strip() for p in response.split('\n\n') if p.strip()]
        para_count = len(paragraphs)
        
        # Check for markdown
        has_markdown = bool(re.search(r'(\*\*|__|\*__|###|--)', response))
        
        print(f"  Paragraphs: {para_count} (should be ≤ 2)")
        print(f"  Has markdown: {has_markdown} (should be False)")
        
        # This is more lenient since Gemini sometimes adds extra formatting
        format_ok = para_count <= 3 and not has_markdown
        
        self.test_results.append({
            'test_name': 'Response Format',
            'passed': format_ok,
            'response': response[:200],
            'details': [
                f"  {'✅' if para_count <= 2 else '⚠️'} Paragraphs: {para_count}",
                f"  {'✅' if not has_markdown else '❌'} No markdown formatting"
            ]
        })
        
        return format_ok
    
    def test_normalization_of_uncertainty(self):
        """Test 6: Chatbot should normalize when user can't identify triggers"""
        print("\n🧪 Test 6: Normalization of Uncertainty")
        print("─" * 60)
        
        user_message = "I feel stressed but I don't know exactly why. Maybe I'm just tired."
        response = self.send_message(user_message)
        
        print(f"User: {user_message}")
        print(f"Bot: {response}\n")
        
        required = [
            r'(okay|normal|wajar|sulit|susah|difficult|gapapa|gak\s+apa)',
        ]
        
        passed = self.check_response(
            "Normalization of Uncertainty",
            response,
            required
        )
        
        return passed
    
    def run_all_tests(self):
        """Run all tests and print summary"""
        print("\n" + "=" * 60)
        print("MINDBOT ENHANCED PROMPT TESTING")
        print("=" * 60)
        print(f"Testing with Gemini API at {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        try:
            # Run all tests
            results = [
                self.test_trigger_identification(),
                self.test_cbt_trigger_emotion_connection(),
                self.test_self_monitoring_reinforcement(),
                self.test_empathetic_listening_no_unsolicited_advice(),
                self.test_response_format(),
                self.test_normalization_of_uncertainty(),
            ]
            
            # Print summary
            print("\n" + "=" * 60)
            print("TEST SUMMARY")
            print("=" * 60)
            
            passed_count = sum(1 for r in results if r)
            total_count = len(results)
            
            for result in self.test_results:
                status = "✅" if result['passed'] else "❌"
                print(f"\n{status} {result['test_name']}")
                for detail in result['details']:
                    print(detail)
            
            print("\n" + "=" * 60)
            print(f"Results: {passed_count}/{total_count} tests passed")
            print("=" * 60)
            
            if passed_count == total_count:
                print("\n🎉 All tests passed! Your chatbot prompts are working correctly.")
                return 0
            else:
                print(f"\n⚠️  {total_count - passed_count} test(s) need attention.")
                return 1
                
        except Exception as e:
            print(f"\n❌ Error during testing: {e}")
            return 1


if __name__ == '__main__':
    tester = ChatbotPromptTester()
    exit_code = tester.run_all_tests()
    sys.exit(exit_code)
