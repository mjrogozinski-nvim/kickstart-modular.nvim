"""Serialize local model transitions for Pi. No inference prompts are sent."""
import errno
import fcntl
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
import urllib.error
import urllib.request

HOME_DIR = Path.home()
SETUP = HOME_DIR / 'Developer/ai/deepseek-v41-local'
STATE = HOME_DIR / '.local/state/nvim/pi-models'
QWEN = 'qwen3.8:27b-mtp-bf16'
TARGETS = {'ollama': (11434, QWEN), 'ds4-q2': (8012, 'deepseek-v4.1-flash'),
           'ds4-q4': (8014, 'deepseek-v4.1-flash')}


def request(port, path, body=None, timeout=5):
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(f'http://127.0.0.1:{port}{path}', data=data,
                                 headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.load(response)


def loaded():
    try:
        return request(11434, '/api/ps')['models']
    except urllib.error.URLError as error:
        if getattr(error.reason, 'errno', None) == errno.ECONNREFUSED:
            return []
        raise


def wait_for(predicate, timeout, description):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return
        time.sleep(0.5)
    raise RuntimeError(f'Timed out waiting for {description}')


def processes():
    output = subprocess.check_output(['ps', '-axo', 'pid=,stat=,command='], text=True)
    found = {}
    for line in output.splitlines():
        parts = line.strip().split(None, 2)
        if len(parts) != 3 or 'Z' in parts[1]:
            continue
        pid, _, command = parts
        args = command.split()
        if not args or Path(args[0]).name != 'ds4-server':
            continue
        for provider, (port, _) in TARGETS.items():
            if provider == 'ollama':
                continue
            quant = provider[-2:].upper()
            if ('--port' in args and args.index('--port') + 1 < len(args)
                    and args[args.index('--port') + 1] == str(port) and
                    f'DeepSeek-V4.1-Flash-{quant}.gguf' in command):
                found[int(pid)] = provider
    return found


def stop_deepseek(except_provider=None):
    stopping = {pid: provider for pid, provider in processes().items()
                if provider != except_provider}
    for pid in stopping:
        # Recheck identity immediately before sending a signal.
        if processes().get(pid) == stopping[pid]:
            print(f'Stopping {stopping[pid]} (PID {pid})', flush=True)
            try:
                os.kill(pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
    wait_for(lambda: not (set(processes()) & set(stopping)), 60, 'DeepSeek to exit')


def unload_ollama(keep=None):
    for model in loaded():
        name = model.get('name', model.get('model'))
        if name != keep:
            print(f'Unloading {name}', flush=True)
            request(11434, '/api/generate', {'model': name, 'keep_alive': 0,
                                           'stream': False}, timeout=120)
    wait_for(lambda: all(m.get('name', m.get('model')) == keep for m in loaded()),
             60, 'Ollama to release the previous model')


def ready(provider):
    port, model = TARGETS[provider]
    try:
        return any(m['id'] == model for m in request(port, '/v1/models')['data'])
    except (OSError, ValueError, KeyError):
        return False


def ensure(provider):
    if provider not in TARGETS:
        raise ValueError(f'Unsupported local provider: {provider}')
    if provider != 'ollama' and not (SETUP / 'start-server.sh').is_file():
        raise RuntimeError('DeepSeek start-server.sh is missing')
    stop_deepseek(except_provider=provider)
    unload_ollama(keep=QWEN if provider == 'ollama' else None)
    if provider == 'ollama':
        if not any(m.get('name') == QWEN for m in loaded()):
            print('Loading Qwen', flush=True)
            request(11434, '/api/generate', {
                'model': QWEN, 'stream': False, 'keep_alive': '30m',
                'options': {'num_ctx': 32768},
            }, timeout=300)
        if not ready(provider):
            raise RuntimeError('Qwen is not available in Ollama')
    else:
        running = provider in processes().values()
        if not running:
            if ready(provider):
                raise RuntimeError('Endpoint is occupied by an unrecognized server; not starting another')
            log = STATE / f'{provider}.log'
            print(f'Starting {provider}; log: {log}', flush=True)
            with log.open('ab') as output:
                child = subprocess.Popen(['sh', str(SETUP / 'start-server.sh'), provider[-2:]],
                                         stdin=subprocess.DEVNULL, stdout=output, stderr=output,
                                         start_new_session=True)
            (STATE / f'{provider}.pid').write_text(str(child.pid))
        else:
            child = None
        def healthy():
            if child is not None and child.poll() is not None:
                raise RuntimeError(f'{provider} exited; see {STATE / (provider + ".log")}')
            return ready(provider)
        try:
            wait_for(healthy, 300, f'{provider} endpoint to become ready')
        except Exception:
            if child is not None and child.poll() is None:
                child.terminate()
                child.wait(timeout=60)
            raise
    print(f'Ready: {provider}', flush=True)


def main():
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'transition.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Another local model transition is in progress')
        ensure(sys.argv[1])


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
