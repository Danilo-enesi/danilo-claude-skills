<?php
/**
 * check-namespaces.php — Fase 1 strutturale: PSR-4 e naming convention dei file.
 *
 * Uso: php check-namespaces.php <path-modulo-o-progetto> [--base-ns=Master\\Modules] [--base-dir=Modules]
 *
 * Verifica:
 *  - il namespace dichiarato corrisponde al percorso fisico del file
 *    (mappando <base-dir> fisico su <base-ns> logico, stile PSR-4)
 *  - il nome del file è in PascalCase (classi/Model/Controller), non snake_case/camelCase
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$root = $argv[1] ?? getcwd();
$baseNs = 'Master\\Modules';
$baseDir = 'Modules';
foreach (array_slice($argv, 2) as $arg) {
    if (preg_match('/^--base-ns=(.+)$/', $arg, $m)) $baseNs = $m[1];
    if (preg_match('/^--base-dir=(.+)$/', $arg, $m)) $baseDir = $m[1];
}

if (!is_dir($root)) {
    fwrite(STDERR, "Path non trovato: $root\n");
    exit(1);
}

function findPhpFiles(string $dir): array
{
    $out = [];
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if ($file->isFile() && substr($file->getFilename(), -4) === '.php') {
            $out[] = $file->getPathname();
        }
    }
    return $out;
}

$files = findPhpFiles($root);
$findings = [];

foreach ($files as $path) {
    // Salta vendor/: quello lo copre check-vendor-untouched.php
    if (strpos(str_replace('\\', '/', $path), '/vendor/') !== false) {
        continue;
    }

    $content = file_get_contents($path);
    $basename = basename($path, '.php');

    // Naming convention: PascalCase (prima lettera maiuscola, nessun underscore)
    if (!preg_match('/^[A-Z][A-Za-z0-9]*$/', $basename)) {
        $findings[] = [
            'rule' => 'naming-convention',
            'severity' => 'suggerimento',
            'file' => $path,
            'line' => 1,
            'message' => "Nome file '$basename.php' non in PascalCase",
        ];
    }

    // Namespace vs percorso fisico
    if (!preg_match('/^\s*namespace\s+([A-Za-z0-9_\\\\]+)\s*;/m', $content, $m)) {
        continue; // file senza namespace (script procedurale, non una classe) — non valutato
    }
    $declaredNs = $m[1];

    $normalizedPath = str_replace('\\', '/', $path);
    $marker = '/' . $baseDir . '/';
    $pos = strpos($normalizedPath, $marker);
    if ($pos === false) {
        continue; // fuori dall'albero atteso, non valutabile con questa base
    }

    $relative = substr($normalizedPath, $pos + strlen($marker));
    $relativeDir = dirname($relative);
    $expectedNsSuffix = $relativeDir === '.' ? '' : '\\' . str_replace('/', '\\', $relativeDir);
    $expectedNs = $baseNs . $expectedNsSuffix;

    if ($declaredNs !== $expectedNs) {
        $findings[] = [
            'rule' => 'namespace-psr4',
            'severity' => 'critico',
            'file' => $path,
            'line' => lineOfNs($content),
            'message' => "Namespace dichiarato '$declaredNs' non corrisponde al percorso atteso '$expectedNs'",
        ];
    }
}

function lineOfNs(string $content): int
{
    $lines = explode("\n", $content);
    foreach ($lines as $i => $line) {
        if (preg_match('/^\s*namespace\s+/', $line)) {
            return $i + 1;
        }
    }
    return 1;
}

echo json_encode([
    'script' => 'check-namespaces',
    'root' => $root,
    'base_ns' => $baseNs,
    'base_dir' => $baseDir,
    'files_scanned' => count($files),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
