<?php
/**
 * check-vendor-untouched.php — Fase 1 strutturale: divieto di modificare vendor/enesisrl/.
 *
 * Uso:
 *   php check-vendor-untouched.php --files=file1.php,file2.php   (lista esplicita)
 *   php check-vendor-untouched.php --git-diff=<repo-path>        (usa `git diff --name-only` nel repo dato)
 *
 * Qualsiasi path che passa sotto una cartella "vendor/enesisrl/" è una violazione:
 * il fix va fatto in laravel-master-dev/private/packages/enesisrl/, non nel vendor installato.
 *
 * Output: JSON su stdout. Sola lettura (il git-diff è read-only: `git diff`, non modifica nulla).
 */

error_reporting(E_ERROR | E_PARSE);

$files = [];

foreach ($argv as $arg) {
    if (preg_match('/^--files=(.+)$/', $arg, $m)) {
        $files = array_merge($files, explode(',', $m[1]));
    }
    if (preg_match('/^--git-diff=(.+)$/', $arg, $m)) {
        $repoPath = $m[1];
        $escaped = escapeshellarg($repoPath);
        $cmd = "git -C $escaped diff --name-only HEAD 2>&1";
        exec($cmd, $out, $code);
        if ($code === 0) {
            $files = array_merge($files, $out);
        } else {
            fwrite(STDERR, "git diff fallito in $repoPath: " . implode("\n", $out) . "\n");
        }
    }
}

if (empty($files)) {
    fwrite(STDERR, "Nessun file da controllare. Usa --files=... o --git-diff=<repo>.\n");
    exit(1);
}

$findings = [];
foreach ($files as $f) {
    $normalized = str_replace('\\', '/', trim($f));
    if ($normalized === '') {
        continue;
    }
    if (preg_match('#(^|/)vendor/enesisrl/#', $normalized)) {
        $findings[] = [
            'rule' => 'vendor-untouched',
            'severity' => 'critico',
            'file' => $normalized,
            'line' => 1,
            'message' => "File sotto vendor/enesisrl/ modificato — il fix va fatto in laravel-master-dev/private/packages/enesisrl/ e tirato via Composer, mai qui",
        ];
    }
}

echo json_encode([
    'script' => 'check-vendor-untouched',
    'files_checked' => count($files),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
