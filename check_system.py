import subprocess
import sys
import os

# Ensure we use SQLite for testing
os.environ['DATABASE_URL'] = 'sqlite:///test.db'

def run_cmd(cmd):
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.stdout: print(result.stdout)
    if result.stderr: print(result.stderr)
    return result.returncode

print("--- Running Migrations ---")
run_cmd([sys.executable, 'manage.py', 'migrate'])

print("\n--- Running Tests ---")
run_cmd([sys.executable, 'manage.py', 'test', 'api', '-v2', '--no-input'])

print("\n--- Seeding Data ---")
run_cmd([sys.executable, 'manage.py', 'seed_data', '--flush'])
