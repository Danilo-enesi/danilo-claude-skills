"""Hook PreToolUse di php-upgrade: blocca ciò che è fuori ambito o pericoloso durante una migrazione PHP.

Attivo solo nei progetti con _migration/config.sh (il plugin è globale). Pausa: l'utente crea .claude/guard.off.
Exit 2 = bloccato (il motivo va a Claude). Output JSON "ask" = serve il permesso dell'utente.
Principio: bloccare le scritture e le azioni verso PROD, non le letture. Ogni falso positivo costa un giro con l'utente.
"""
import json, os, re, sys

ROOT = os.path.normcase(os.path.abspath(os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()))
CONFIG = os.path.join(ROOT, "_migration", "config.sh")

# Sempre protetti, in aggiunta a PROTECTED di config.sh
BASE_PROTECTED = [".claude/", "CLAUDE.md", ".git/", ".dunebox/", ".gitignore", ".user.ini", "_migration/"]
# In _migration/ si scrivono solo documenti e risultati; harness (config, checks, patches, liste, files/) no
WRITABLE_IN_MIG = ["_migration/out/", "_migration/REPORT.md", "_migration/GUIA.md", "_migration/libs.lock",
                   "_migration/prod-php"]  # prod-php<ver>-modules.txt / -ini.txt (passo P0)
PTL_SCRIPT = r"^\s*(bash|powershell(\.exe)?)\s[^;&|\n]*prod-to-local/scripts/[\w.-]+\.(sh|ps1)\b"
PROD_OK = r"\bsmoke\.sh\b.*--target\s+prod|\bcompare-prod\.sh\b"


def read_config():
    try:
        text = open(CONFIG, encoding="utf-8", errors="replace").read()
    except OSError:
        return None
    text = re.sub(r"#[^\n]*", "", text)
    m = re.search(r"^PROTECTED=\((.*?)\)", text, re.M | re.S)
    host = re.search(r"^PROD_HOST=[\"']?([^\s\"']+)", text, re.M)
    return {"protected": m.group(1).split() if m else [], "prod_host": host.group(1) if host else None}


def block_rules(cfg):
    rules = [
        # (regex, motivo, su quale testo: "cmd" = senza messaggi di commit/heredoc, "bare" = anche senza stringhe tra apici)
        (r"(^|[\s;&|(])(ssh|scp|sftp|lftp|rsync|pscp|plink|winscp)\s", "bare", "il server di produzione lo tocca solo l'utente (o gli script di prod-to-local)"),
        (r"\bcurl\b.*(\s-T\b|--upload-file|-X\s*(PUT|POST|DELETE|PATCH)|--data|\s-d\s|\s-F\s)", "cmd", "niente richieste HTTP che scrivono"),
        (r"\bgit\s+(push|reset|clean|checkout|restore|rebase|filter-branch|replace|update-ref)\b|\bgit\s+stash\s+(push|pop|drop|clear|save)\b|\bgit\s+stash\s*($|[;&|])|\bgit\s+remote\s+(add|remove|rm|set-url|rename)\b",
         "bare", "per annullare usa rollback.sh del plugin (git che cambia lo stato non è ammesso)"),
        (r"\bgit\s+tag\s+(-d|--delete|-f)", "bare", "i tag mig/* non si cancellano"),
        (r"\bgit\s+commit\b.*--amend", "bare", "niente --amend: ogni passo è un commit nuovo"),
        (r"(?i)\b(drop\s+(database|table|schema)|truncate\s+table|delete\s+from|alter\s+table|insert\s+into|replace\s+into|create\s+(database|table))\b|\bupdate\s+`?\w+`?\s+set\b",
         "cmd", "niente SQL che scrive: il DB non fa parte della migrazione (backup/ripristino solo con gli script)"),
        (r"\bmysql(\.exe)?\b[^|\n]*<\s*\S", "cmd", "niente import diretti nel DB: usa restore-db.sh"),
        (r"\b(sed|perl)\s+(-\w*\s+)*-i", "bare", "niente modifiche in-place da shell: usa Edit (o patch.php per il core)"),
        (r"(?i)(remove-item\b.*-recurse|rmdir\s+/s|\bdel\s+/s|\bformat\b\s+[a-z]:)", "bare", "cancellazione ricorsiva non ammessa"),
        (r"--no-verify|--force\b", "bare", "niente bypass"),
    ]
    if cfg and cfg["prod_host"]:
        rules.append((re.escape(cfg["prod_host"]), "cmd", "verso PROD solo smoke.sh --target prod, compare-prod.sh (GET) o gli script di prod-to-local"))
    return rules


ASK_CMD = [
    (r"\bsmoke\.sh\b.*--target\s+prod", "smoke su PRODUZIONE (solo GET)"),
    (r"\bcompare-prod\.sh\b", "confronto con PRODUZIONE (solo GET)"),
    (r"\brestore-db\.sh\b(?!.*--dry-run)", "ripristino del DB locale (sovrascrive il DB del sito)"),
    (r"\brollback\.sh\b(?!.*--dry-run)", "rollback dei file del sito"),
    (r"\bdeploy-pack\.sh\b(?!.*--dry-run)", "creazione del pacchetto per PROD"),
    (r"\bdeploy-push\.sh\b.*--dry-run", "controllo in PRODUZIONE via SSH (solo lettura)"),
    (r"\bdeploy-push\.sh\b(?!.*--dry-run)", "DEPLOY IN PRODUZIONE via SSH (istantanea + applica, rollback automatico)"),
    (r"\bdeploy-rollback\.sh\b", "ROLLBACK IN PRODUZIONE via SSH"),
    (r"\bmaintenance\.sh\b\s+(on|off)\b", "modo manutenzione in PRODUZIONE (.htaccess, solo il blocco tra marcatori)"),
    (r"\bmaintenance\.sh\b", "lettura dello stato di manutenzione in PRODUZIONE via SSH"),
    (PTL_SCRIPT, "script prod-to-local: si collega alla produzione"),
]
# Redirezioni innocue ed email nei messaggi di commit: tolte prima di cercare scritture
HARMLESS = r"\d?>\s*/dev/null|\d?>&\d|>\s*\$null|<[^<>\s]+@[^<>\s]+>"
WRITE_OPS = r"(>|\btee\b|\bcp\b|\bmv\b|\brm\b|\bmkdir\b|\btouch\b|\bunzip\b|\btar\b.*-x|(?i:set-content|out-file|add-content|copy-item|move-item|remove-item|new-item|rename-item))"
SEGMENT = r"\n|;|&&|\|\||\|"
QUOTED = r"'[^']*'|\"(?:\\.|[^\"\\])*\""


def strip_prose(cmd):
    """Toglie il testo libero (corpo dei heredoc, messaggi di commit): parole come 'ssh' o 'delete from' lì non sono comandi."""
    cmd = re.sub(r"<<-?\s*['\"]?(\w+)['\"]?[^\n]*\n.*?\n\s*\1\b", "<<HEREDOC", cmd, flags=re.S)
    return re.sub(r"(\bgit\s+commit\b[^;&|]*?\s-(?:m|F)\s*)(\"(?:\\.|[^\"\\])*\"|'[^']*'|\S+)", r"\1MSG", cmd, flags=re.S)


def rel(path):
    p = os.path.normcase(os.path.abspath(os.path.join(ROOT, path)))
    if p != ROOT and not p.startswith(ROOT + os.sep):
        return None
    return os.path.relpath(p, ROOT).replace("\\", "/")


def under(r, prefixes):
    r = r.lower()  # su Windows normcase() abbassa già il percorso
    return any(r == p.lower().rstrip("/") or r.startswith(p.lower()) for p in prefixes)


def protected_list(cfg):
    return BASE_PROTECTED + (cfg["protected"] if cfg else [])


def is_protected(r, cfg):
    if under(r, WRITABLE_IN_MIG):
        return False
    if r.lower() == ".htaccess" or r.lower().endswith("/.htaccess"):
        return True
    return under(r, protected_list(cfg))


def outside_ok(path):
    """Fuori dal progetto si scrive solo nei temporanei (scratchpad) e nella memoria di Claude."""
    p = os.path.normcase(os.path.abspath(path))
    tmp = os.path.normcase(os.path.abspath(os.environ.get("TEMP") or os.environ.get("TMPDIR") or "/tmp"))
    mem = os.path.normcase(os.path.join(os.path.expanduser("~"), ".claude", "projects"))
    return p.startswith(tmp + os.sep) or (p.startswith(mem + os.sep) and os.sep + "memory" + os.sep in p)


def check_edit(path, cfg):
    r = rel(path)
    if r is None:
        return None if outside_ok(path) else f"fuori dal progetto: {path}"
    if is_protected(r, cfg):
        return f"percorso protetto durante la migrazione: {r}"
    return None


def check_cmd(cmd, cfg):
    prose_free = strip_prose(cmd)
    for seg in re.split(SEGMENT, prose_free):
        bare = re.sub(QUOTED, "''", seg)
        if re.search(PTL_SCRIPT, seg.replace("\\", "/")):
            continue  # script del plugin prod-to-local: ssh lo fa lo script (chiede comunque il permesso)
        for rx, where, why in block_rules(cfg):
            if not re.search(rx, bare if where == "bare" else seg):
                continue
            if why.startswith("verso PROD") and re.search(PROD_OK, seg):
                continue
            return "block", why
        # scritture: cercate fuori dalle stringhe tra apici (es. sed 's/<[^>]*>//g' non scrive)
        if re.search(WRITE_OPS, re.sub(HARMLESS, "", bare)):
            low = seg.replace("\\", "/").lower()
            for p in protected_list(cfg) + [".htaccess"]:
                if p.lower() in low and not any(w.lower() in low for w in WRITABLE_IN_MIG):
                    return "block", f"comando che scrive in un percorso protetto: {p}"
    for rx, why in ASK_CMD:
        if re.search(rx, prose_free.replace("\\", "/")):
            return "ask", why
    return None, None


def main():
    data = json.load(sys.stdin)
    if not os.path.isfile(CONFIG):
        return 0  # non è un progetto in migrazione
    if os.environ.get("MIG_GUARD_IGNORE_OFF") != "1" and os.path.exists(os.path.join(ROOT, ".claude", "guard.off")):
        return 0
    cfg = read_config()
    tool, inp = data.get("tool_name", ""), data.get("tool_input", {}) or {}
    if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        why = check_edit(inp.get("file_path") or inp.get("notebook_path") or "", cfg)
        if why:
            print(f"BLOCCATO dalla guardia della migrazione: {why}", file=sys.stderr)
            return 2
    elif tool in ("Bash", "PowerShell"):
        kind, why = check_cmd(inp.get("command", ""), cfg)
        if kind == "block":
            print(f"BLOCCATO dalla guardia della migrazione: {why}", file=sys.stderr)
            return 2
        if kind == "ask":
            print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "ask",
                                                     "permissionDecisionReason": f"Migrazione: {why}"}}))
    return 0


if __name__ == "__main__":
    sys.exit(main())
