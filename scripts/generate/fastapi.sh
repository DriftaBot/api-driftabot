#!/usr/bin/env bash
# Generate OpenAPI schema from a FastAPI project.
set -euo pipefail

OUTPUT="${1:?Usage: fastapi.sh <output_path>}"
mkdir -p "$(dirname "$OUTPUT")"

# Install dependencies
echo "[drift-agent] installing FastAPI dependencies..."
if [ -f "requirements.txt" ]; then
  pip install -r requirements.txt -q
elif [ -f "pyproject.toml" ]; then
  pip install -e . -q
fi

# Generate the schema by importing the FastAPI app
python3 - "$OUTPUT" << 'PYEOF'
import json, sys, os, importlib

output = sys.argv[1]

candidates = [
  ('main', 'app'),
  ('app.main', 'app'),
  ('src.main', 'app'),
  ('api.main', 'app'),
  ('app', 'app'),
]

for module_name, attr in candidates:
  try:
    mod = importlib.import_module(module_name)
    app = getattr(mod, attr, None)
    if app is None:
      continue
    schema = app.openapi()
    os.makedirs(os.path.dirname(output) or '.', exist_ok=True)
    with open(output, 'w') as f:
      json.dump(schema, f, indent=2)
    print(f'[drift-agent] generated FastAPI OpenAPI schema from {module_name}:{attr} → {output}')
    sys.exit(0)
  except Exception:
    continue

print('[drift-agent] FastAPI app not found in common locations', file=sys.stderr)
sys.exit(1)
PYEOF
