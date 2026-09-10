<?php
/**
 * check-module-structure.php — Fase 1 strutturale: i 5 componenti di un modulo.
 *
 * Uso: php check-module-structure.php <path-modulo-o-progetto>
 *
 * Ogni modulo (cartella con config.php alla radice) deve avere:
 *  - config.php
 *  - Models/<NomeModulo>.php
 *  - Controllers/AdminController.php
 *  - Facades/<NomeModulo>.php
 *  - Classes/Module.php
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$root = $argv[1] ?? getcwd();
if (!is_dir($root)) {
    fwrite(STDERR, "Path non trovato: $root\n");
    exit(1);
}

function findModuleDirs(string $dir): array
{
    $out = [];
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if ($file->isFile() && $file->getFilename() === 'config.php') {
            $out[] = dirname($file->getPathname());
        }
    }
    return $out;
}

$modules = findModuleDirs($root);
$findings = [];

foreach ($modules as $modulePath) {
    $moduleName = basename($modulePath);
    $required = [
        'Models' . DIRECTORY_SEPARATOR . $moduleName . '.php',
        'Controllers' . DIRECTORY_SEPARATOR . 'AdminController.php',
        'Facades' . DIRECTORY_SEPARATOR . $moduleName . '.php',
        'Classes' . DIRECTORY_SEPARATOR . 'Module.php',
    ];

    foreach ($required as $rel) {
        $full = $modulePath . DIRECTORY_SEPARATOR . $rel;
        if (!file_exists($full)) {
            $findings[] = [
                'rule' => 'module-structure',
                'severity' => 'importante',
                'file' => $modulePath,
                'line' => 1,
                'message' => "Modulo '$moduleName': manca '$rel'",
                'confidence' => 'da_verificare_se_singolare_del_nome_modulo',
            ];
        }
    }
}

echo json_encode([
    'script' => 'check-module-structure',
    'root' => $root,
    'modules_scanned' => count($modules),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
