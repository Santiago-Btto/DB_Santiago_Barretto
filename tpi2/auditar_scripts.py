"""Inventario estático de todos los scripts versionados; nunca ejecuta SQL ni DDL."""

from __future__ import annotations

import ast
import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
OUT = Path(__file__).resolve().parent / "evidencia"
EXTENSIONS = {".sql", ".js", ".ps1", ".py"}
WRITE_PATTERN = re.compile(r"\b(INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|TRUNCATE|GRANT|REVOKE|COMMIT)\b", re.I)
GUARD_PATTERN = re.compile(r"\b(current_database|ON_ERROR_STOP|if|raise|throw|ROLLBACK|BEGIN|guard|existe)\b", re.I)


def tracked_scripts() -> list[Path]:
    result = subprocess.run(["git", "ls-files", "-z", "--", "*.sql", "*.js", "*.ps1", "*.py"],
                            cwd=ROOT, capture_output=True, check=True)
    return [ROOT / path.decode("utf-8") for path in result.stdout.split(b"\0") if path]


def analyze(path: Path) -> dict[str, str | int]:
    data = path.read_bytes()
    content = data.decode("utf-8-sig", errors="replace")
    rel = path.relative_to(ROOT).as_posix()
    suffix = path.suffix.lower()
    if suffix not in EXTENSIONS:
        raise ValueError(rel)
    if suffix == ".py":
        try:
            ast.parse(content, filename=rel)
            syntax = "python_ast_ok"
        except SyntaxError as exc:
            syntax = f"python_ast_error_l{exc.lineno}"
    elif suffix == ".js":
        result = subprocess.run(["node", "--check", str(path)], capture_output=True, text=True)
        syntax = "node_check_ok" if result.returncode == 0 else "node_check_error"
    elif suffix == ".ps1":
        escaped = str(path).replace("'", "''")
        command = ("$t=$null;$e=$null;"
                   f"[System.Management.Automation.Language.Parser]::ParseFile('{escaped}',[ref]$t,[ref]$e)|Out-Null;"
                   "if($e.Count -eq 0){'ok'}else{'error'}")
        result = subprocess.run(["pwsh", "-NoProfile", "-Command", command],
                                capture_output=True, text=True)
        syntax = "ps_parser_ok" if result.returncode == 0 and result.stdout.strip() == "ok" else "ps_parser_error"
    else:
        syntax = "sql_requiere_motor_y_contexto"
    return {
        "ruta": rel,
        "unidad": rel.split("/")[0],
        "extension": suffix,
        "lineas": len(content.splitlines()),
        "sha256": hashlib.sha256(data).hexdigest(),
        "sintaxis": syntax,
        "palabras_escritura": len(WRITE_PATTERN.findall(content)),
        "marcas_guarda": len(GUARD_PATTERN.findall(content)),
    }


def main() -> None:
    scripts = tracked_scripts()
    rows = [analyze(path) for path in scripts]
    OUT.mkdir(parents=True, exist_ok=True)
    fields = ["ruta", "unidad", "extension", "lineas", "sha256", "sintaxis",
              "palabras_escritura", "marcas_guarda"]
    with (OUT / "inventario_scripts.tsv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, delimiter="\t")
        writer.writeheader()
        writer.writerows(rows)
    summary = {
        "total": len(rows),
        "por_unidad": dict(sorted(Counter(row["unidad"] for row in rows).items())),
        "por_extension": dict(sorted(Counter(row["extension"] for row in rows).items())),
        "errores_parser": [row["ruta"] for row in rows if row["sintaxis"].endswith("error")],
        "alcance": "Inventario y comprobación sintáctica de Python/JS/PowerShell; SQL no ejecutado por seguridad",
    }
    (OUT / "inventario_resumen.json").write_text(
        json.dumps(summary, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
