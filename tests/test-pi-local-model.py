import importlib.util
import unittest
import sys
sys.dont_write_bytecode = True
from pathlib import Path
from unittest.mock import patch
spec = importlib.util.spec_from_file_location('lifecycle', str(Path(__file__).resolve().parents[1] / 'scripts/pi-local-model.py'))
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

class Lifecycle(unittest.TestCase):
    def test_deepseek_stops_other_and_unloads_before_ready(self):
        events = []
        with patch.object(m, 'stop_deepseek', side_effect=lambda **k: events.append('stop')), \
             patch.object(m, 'unload_ollama', side_effect=lambda **k: events.append('unload')), \
             patch.object(m, 'processes', return_value={10: 'ds4-q2'}), \
             patch.object(m, 'ready', side_effect=lambda p: events.append('ready') or True):
            m.ensure('ds4-q2')
        self.assertEqual(events, ['stop', 'unload', 'ready'])

    def test_unload_failure_never_starts_deepseek(self):
        with patch.object(m, 'stop_deepseek'), \
             patch.object(m, 'unload_ollama', side_effect=RuntimeError('still loaded')), \
             patch.object(m.subprocess, 'Popen') as start:
            with self.assertRaises(RuntimeError): m.ensure('ds4-q4')
            start.assert_not_called()

    def test_qwen_load_follows_deepseek_exit(self):
        events = []
        with patch.object(m, 'stop_deepseek', side_effect=lambda **k: events.append('stop')), \
             patch.object(m, 'unload_ollama', side_effect=lambda **k: events.append('unload')), \
             patch.object(m, 'loaded', return_value=[]), \
             patch.object(m, 'request', side_effect=lambda *a, **k: events.append('load')), \
             patch.object(m, 'ready', return_value=True):
            m.ensure('ollama')
        self.assertEqual(events, ['stop', 'unload', 'load'])

    def test_process_matching_ignores_unrelated_and_zombies(self):
        output = '''10 S ./ds4-server -m gguf/DeepSeek-V4.1-Flash-Q2.gguf --port 8012
11 Z ./ds4-server -m gguf/DeepSeek-V4.1-Flash-Q4.gguf --port 8014
12 S editor DeepSeek-V4.1-Flash-Q4.gguf --port 8014
13 S ./ds4-server -m other.gguf --port 8014
'''
        with patch.object(m.subprocess, 'check_output', return_value=output):
            self.assertEqual(m.processes(), {10: 'ds4-q2'})

unittest.main()
