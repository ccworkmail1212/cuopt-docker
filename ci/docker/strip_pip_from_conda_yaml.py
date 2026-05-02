"""Remove the pip section from a conda env yaml (no external dependencies).

Uses plain text processing — no pyyaml needed, safe to run before conda env is created.

Usage: python3 strip_pip_from_conda_yaml.py <input.yaml> [output.yaml]
"""
import sys

src = sys.argv[1]
dst = sys.argv[2] if len(sys.argv) > 2 else src

with open(src) as f:
    lines = f.readlines()

result = []
in_pip_block = False
for line in lines:
    stripped = line.rstrip()
    # Detect start of pip block inside dependencies list
    if stripped.lstrip().startswith("- pip:") or stripped.strip() == "- pip:":
        in_pip_block = True
        continue
    if in_pip_block:
        # Pip entries are indented with extra spaces relative to "- pip:"
        if stripped.startswith("  ") or stripped == "":
            continue  # skip pip entry
        else:
            in_pip_block = False  # back to top-level
    result.append(line)

with open(dst, "w") as f:
    f.writelines(result)

removed = len(lines) - len(result)
print(f"Stripped pip section ({removed} lines removed, {len(result)} lines kept).")
