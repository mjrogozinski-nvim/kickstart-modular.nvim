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
        with patch.object(m, 'stop_local_servers', side_effect=lambda **k: events.append('stop')), \
             patch.object(m, 'unload_ollama', side_effect=lambda **k: events.append('unload')), \
             patch.object(m, 'processes', return_value={10: 'ds4-q2'}), \
             patch.object(m, 'ready', side_effect=lambda p: events.append('ready') or True):
            m.ensure('ds4-q2')
        self.assertEqual(events, ['stop', 'unload', 'ready'])

    def test_unload_failure_never_starts_deepseek(self):
        with patch.object(m, 'stop_local_servers'), \
             patch.object(m, 'unload_ollama', side_effect=RuntimeError('still loaded')), \
             patch.object(m.subprocess, 'Popen') as start:
            with self.assertRaises(RuntimeError): m.ensure('ds4-q4')
            start.assert_not_called()

    def test_qwen_load_follows_deepseek_exit(self):
        events = []
        with patch.object(m, 'stop_local_servers', side_effect=lambda **k: events.append('stop')), \
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

class MTPLXLifecycle(unittest.TestCase):
    def test_mtplx_unloads_before_start(self):
        from tempfile import TemporaryDirectory
        events = []
        with TemporaryDirectory() as tmp, patch.object(m, 'STATE', Path(tmp)), \
             patch.object(m, 'stop_local_servers', side_effect=lambda **k: events.append('stop')), \
             patch.object(m, 'unload_ollama', side_effect=lambda **k: events.append('unload')), \
             patch.object(m, 'processes', return_value={}), \
             patch.object(m, 'ready', side_effect=[False, True]), \
             patch.object(m.subprocess, 'Popen') as start:
            start.return_value.pid = 99
            start.return_value.poll.return_value = None
            start.side_effect = lambda *a, **k: events.append('start') or start.return_value
            m.ensure('mtplx')
            self.assertEqual(events, ['stop', 'unload', 'start'])
            self.assertIn(m.MTPLX_REPO, start.call_args.args[0])

    def test_unload_failure_never_starts_mtplx(self):
        with patch.object(m, 'stop_local_servers'), \
             patch.object(m, 'unload_ollama', side_effect=RuntimeError('still loaded')), \
             patch.object(m.subprocess, 'Popen') as start:
            with self.assertRaises(RuntimeError): m.ensure('mtplx')
            start.assert_not_called()

    def test_execed_mtplx_server_is_recognized(self):
        model_path = m.HOME_DIR / '.mtplx/models' / m.MTPLX_REPO.replace('/', '--')
        command = f'/opt/homebrew/bin/python3 -P -m mtplx.server.openai --model {model_path} --port 8000'
        output = f"10 S {command}\n11 Z {command}\n12 S {command.replace(str(model_path), '/other/model')}\n13 S {command.replace('--port 8000', '--port 8001')}\n14 S editor -c {command}\n"
        with patch.object(m.subprocess, 'check_output', return_value=output):
            self.assertEqual(m.processes(), {10: 'mtplx'})

    def test_existing_mtplx_server_is_reused(self):
        with patch.object(m, 'stop_local_servers'), \
             patch.object(m, 'unload_ollama'), \
             patch.object(m, 'processes', return_value={10: 'mtplx'}), \
             patch.object(m, 'ready', return_value=True), \
             patch.object(m.subprocess, 'Popen') as start:
            m.ensure('mtplx')
            start.assert_not_called()

    def test_execed_mtplx_is_stopped_before_switch(self):
        events = []
        with patch.object(m, 'processes', side_effect=[{10: 'mtplx'}, {10: 'mtplx'}, {}]), \
             patch.object(m.os, 'kill', side_effect=lambda pid, sig: events.append(pid)):
            m.stop_local_servers(except_provider='ollama')
        self.assertEqual(events, [10])

    def test_mtplx_identity_and_health(self):
        output = f"10 S python {m.MTPLX / '.venv/bin/mtplx'} serve --model {m.MTPLX_REPO} --port 8000\n11 S editor mtplx serve --model {m.MTPLX_REPO} --port 8000\n"
        with patch.object(m.subprocess, 'check_output', return_value=output):
            self.assertEqual(m.processes(), {10: 'mtplx'})
        for ok, model, expected in [(True, m.TARGETS['mtplx'][1], True), (False, m.TARGETS['mtplx'][1], False), (True, 'other', False)]:
            with patch.object(m, 'request', return_value={'ok': ok, 'model': model}):
                self.assertEqual(m.ready('mtplx'), expected)

unittest.main()
