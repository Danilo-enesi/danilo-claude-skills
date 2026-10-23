"""Test della guardia: python -I plugins/php-upgrade/tests/guard_test.py
Crea un progetto finto in una cartella temporanea (con _migration/config.sh) e verifica i casi.
Molti casi vengono da falsi positivi reali della prima migrazione: non toglierli."""
import json, os, subprocess, sys, tempfile

GUARD = os.environ.get("MIG_GUARD_PATH") or os.path.join(os.path.dirname(__file__), "..", "hooks", "guard.py")
ROOT = tempfile.mkdtemp(prefix="php-upgrade-test-")
os.makedirs(os.path.join(ROOT, "_migration"))
with open(os.path.join(ROOT, "_migration", "config.sh"), "w") as f:
    f.write("PROD_HOST=example.it  # dominio\nPROTECTED=(\n  admin/pers/ admin/include/class/tcpdf/\n  admin/include/class/PHPExcel\n)\n")
PTL = "C:/Users/danilo/Dev/danilo-claude-skills/plugins/prod-to-local/scripts"
TMP = os.environ.get("TEMP") or os.environ.get("TMPDIR") or "/tmp"


def run(tool, root=ROOT, **inp):
    p = subprocess.run([sys.executable, "-I", GUARD], input=json.dumps({"tool_name": tool, "tool_input": inp}),
                       capture_output=True, text=True, env={**os.environ, "CLAUDE_PROJECT_DIR": root, "MIG_GUARD_IGNORE_OFF": "1"})
    if p.returncode == 2:
        return "block"
    return "ask" if '"ask"' in p.stdout else "allow"


J = lambda *p: os.path.join(ROOT, *p)
cases = [
    # file
    ("allow", "Edit", {"file_path": J("admin", "include", "class", "class.master.php")}),
    ("allow", "Write", {"file_path": J("_migration", "REPORT.md")}),
    ("allow", "Edit", {"file_path": J("_migration", "GUIA.md")}),
    ("allow", "Write", {"file_path": J("_migration", "out", "x.txt")}),
    ("allow", "Write", {"file_path": J("_migration", "prod-php83-ini.txt")}),
    ("allow", "Write", {"file_path": os.path.join(TMP, "claude", "scratchpad", "x.php")}),
    ("allow", "Write", {"file_path": os.path.join(os.path.expanduser("~"), ".claude", "projects", "p", "memory", "m.md")}),
    ("block", "Edit", {"file_path": J("_migration", "checks.php")}),
    ("block", "Edit", {"file_path": J("_migration", "config.sh")}),
    ("block", "Edit", {"file_path": J(".claude", "settings.json")}),
    ("block", "Edit", {"file_path": J("CLAUDE.md")}),
    ("block", "Edit", {"file_path": J("admin", "pers", "config", "db.php")}),
    ("block", "Edit", {"file_path": J("admin", "include", "class", "tcpdf", "tcpdf.php")}),
    ("block", "Edit", {"file_path": J("admin", "include", "class", "PHPExcel", "Cell.php")}),
    ("block", "Edit", {"file_path": J("promo", ".htaccess")}),
    ("block", "Write", {"file_path": "C:/devProjects/altro/index.php"}),
    ("block", "Write", {"file_path": os.path.join(os.path.expanduser("~"), ".claude", "settings.json")}),
    # comandi ammessi (letture, comandi composti, falsi positivi storici)
    ("allow", "Bash", {"command": "bash _migration/tests/run.sh --static"}),
    ("allow", "Bash", {"command": "git add -A && git commit -m 'C1 core'"}),
    ("allow", "Bash", {"command": "git remote -v; git stash list; git status --short"}),
    ("allow", "Bash", {"command": "git commit -q -m \"Guardia: eccezione per ssh e scp nei profili\n\nDROP TABLE, delete from x, example.it\" && git log --oneline -1"}),
    ("allow", "Bash", {"command": "git commit -F- <<'EOF'\nPHPMailer: invio via ssh? no. curl -X POST example.it\nEOF"}),
    ("allow", "Bash", {"command": "echo ok > _migration/out/note.txt"}),
    ("allow", "Bash", {"command": "grep -n x .claude/settings.json 2>/dev/null"}),
    ("allow", "Bash", {"command": "cat _migration/config.sh 2>&1 | head"}),
    ("allow", "Bash", {"command": "sed 's/x/y/' ini.txt > /c/Temp/php.ini\nbash scripts/env.sh 2>&1 | grep -i estension _migration/x"}),
    ("allow", "Bash", {"command": "curl -sk https://site.test/a.pdf -o /c/Temp/p.out; grep x _migration/urls-pdf.txt"}),
    ("allow", "Bash", {"command": "grep '^/it/' _migration/urls-pdf.txt | sed 's/<[^>]*>//g' | sort | uniq -c"}),
    ("allow", "Bash", {"command": "cat > /c/Temp/mailtest.php <<'EOF'\nrequire_once $argv[1] . '/admin/include/class/tcpdf/x.php';\nEOF"}),
    ("allow", "Bash", {"command": "bash scripts/rollback.sh --dry-run"}),
    ("allow", "Bash", {"command": "bash scripts/update-lib.sh tcpdf --download"}),
    # permesso dell'utente
    ("ask", "Bash", {"command": "bash scripts/rollback.sh mig/base"}),
    ("ask", "Bash", {"command": "bash scripts/smoke.sh --target prod --confirm-prod"}),
    ("ask", "Bash", {"command": "bash scripts/compare-prod.sh --confirm-prod"}),
    ("ask", "Bash", {"command": "bash scripts/restore-db.sh x.sql.gz --confirm"}),
    ("ask", "Bash", {"command": "bash scripts/deploy-pack.sh --prod-copy a --prod-dump b"}),
    ("ask", "Bash", {"command": f'powershell.exe -NoProfile -File "{PTL}/vault.ps1" set site-ssh'}),
    ("ask", "Bash", {"command": f'bash "{PTL}/preflight.sh" --host example.it --profile site-ssh'}),
    # bloccati
    ("block", "Bash", {"command": "ssh -p 10112 user@example.it ls"}),
    ("block", "Bash", {"command": "scp a.tgz user@host:/tmp/"}),
    ("block", "Bash", {"command": f'bash "{PTL}/preflight.sh" --profile x-ssh; ssh -p 10112 user@example.it ls'}),
    ("block", "Bash", {"command": 'ssh -p 10112 user@example.it "rm -rf www"  # prod-to-local'}),
    ("block", "Bash", {"command": "curl -s https://www.example.it/it/"}),
    ("block", "Bash", {"command": "curl -s 'https://www.example.it/it/' -o /c/Temp/p.html"}),
    ("block", "Bash", {"command": "curl -X POST https://site.test/it/contatti/ -d a=1"}),
    ("block", "Bash", {"command": "git reset --hard HEAD~1"}),
    ("block", "Bash", {"command": "git checkout -- admin"}),
    ("block", "Bash", {"command": "git stash"}),
    ("block", "Bash", {"command": "git remote add x y"}),
    ("block", "Bash", {"command": "git commit --amend -m x"}),
    ("block", "Bash", {"command": "mysql -e 'DROP DATABASE site_db'"}),
    ("block", "Bash", {"command": "mysql site_db < dump.sql"}),
    ("block", "Bash", {"command": "sed -i 's/a/b/' admin/include/function.inc"}),
    ("block", "Bash", {"command": "echo x > _migration/checks.php"}),
    ("block", "Bash", {"command": "ls; echo x > _migration/config.sh"}),
    ("block", "Bash", {"command": "echo \"x\" > \"_migration/checks.php\""}),
    ("block", "Bash", {"command": "git status && cp a.php admin/include/class/tcpdf/tcpdf.php"}),
    ("block", "Bash", {"command": "echo x > .claude/settings.json 2>/dev/null"}),
    ("block", "PowerShell", {"command": "Remove-Item -Recurse -Force admin"}),
]
bad = [(exp, got, tool, inp) for exp, tool, inp in cases if (got := run(tool, **inp)) != exp]
# fuori da un progetto in migrazione la guardia non interviene
other = tempfile.mkdtemp(prefix="no-migration-")
if run("Bash", root=other, command="git reset --hard") != "allow":
    bad.append(("allow", "block", "Bash", "progetto senza _migration/config.sh"))
for exp, got, tool, inp in bad:
    print(f"FAIL atteso={exp} ottenuto={got} {tool} {inp}")
print(f"{len(cases) + 1 - len(bad)}/{len(cases) + 1} casi OK")
sys.exit(1 if bad else 0)
