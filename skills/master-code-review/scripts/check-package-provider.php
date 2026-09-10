<?php
/**
 * check-package-provider.php — Fase 1 strutturale: pacchetti enesisrl/laravel-master-*.
 *
 * Uso: php check-package-provider.php <path-pacchetto-o-progetto>
 *
 * Per ogni composer.json trovato con name enesisrl/laravel-master-*:
 *  - deve dichiarare extra.laravel.providers con almeno un ServiceProvider
 *  - se ha una cartella config/, i suoi file *.php dovrebbero essere pubblicati
 *    (cercato un publishes([...]) nel provider)
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$root = $argv[1] ?? getcwd();
if (!is_dir($root)) {
    fwrite(STDERR, "Path non trovato: $root\n");
    exit(1);
}

function findComposerJsons(string $dir): array
{
    $out = [];
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if ($file->isFile() && $file->getFilename() === 'composer.json') {
            $out[] = $file->getPathname();
        }
    }
    return $out;
}

$composerFiles = findComposerJsons($root);
$findings = [];
$packagesChecked = 0;

foreach ($composerFiles as $path) {
    $raw = file_get_contents($path);
    $json = json_decode($raw, true);
    if (!$json || empty($json['name']) || strpos($json['name'], 'enesisrl/laravel-master-') !== 0) {
        continue;
    }
    $packagesChecked++;
    $pkgDir = dirname($path);

    $providers = $json['extra']['laravel']['providers'] ?? [];
    if (empty($providers)) {
        $findings[] = [
            'rule' => 'service-provider-declared',
            'severity' => 'importante',
            'file' => $path,
            'line' => 1,
            'message' => "Pacchetto '{$json['name']}' non dichiara extra.laravel.providers in composer.json",
        ];
    }

    $configDir = $pkgDir . DIRECTORY_SEPARATOR . 'config';
    if (is_dir($configDir)) {
        $providerFiles = [];
        $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($pkgDir, FilesystemIterator::SKIP_DOTS));
        foreach ($it as $f) {
            if ($f->isFile() && preg_match('/ServiceProvider\.php$/', $f->getFilename())) {
                $providerFiles[] = $f->getPathname();
            }
        }

        $publishesConfig = false;
        foreach ($providerFiles as $pf) {
            if (preg_match('/publishes\s*\(/', file_get_contents($pf))) {
                $publishesConfig = true;
                break;
            }
        }
        if (!$publishesConfig) {
            $findings[] = [
                'rule' => 'config-publishable',
                'severity' => 'suggerimento',
                'file' => $configDir,
                'line' => 1,
                'message' => "Pacchetto '{$json['name']}' ha config/ ma nessun ServiceProvider chiama publishes(...)",
            ];
        }
    }
}

echo json_encode([
    'script' => 'check-package-provider',
    'root' => $root,
    'packages_checked' => $packagesChecked,
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
