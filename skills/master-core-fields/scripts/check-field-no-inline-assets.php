<?php
/**
 * check-field-no-inline-assets.php — validazione "0 JS/CSS inline" sui Field custom (master-core-fields §7bis).
 *
 * Uso: php check-field-no-inline-assets.php <path-file-o-cartella>
 *
 * Regola assoluta del progetto: un Field custom non deve MAI emettere JS o CSS
 * inline dal proprio render()/renderViewMode() — niente <script>, <style>,
 * onclick=, style=. Il JS va in theme.js o in un plugin Admin (data-admin-*),
 * il CSS in theme.css o in una view Blade dedicata del modulo.
 *
 * Salta i file sotto vendor/ (non sono Field custom di progetto).
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$target = $argv[1] ?? getcwd();
$findings = [];

function collectFieldFiles(string $target): array
{
    if (is_file($target)) {
        return [$target];
    }
    if (!is_dir($target)) {
        return [];
    }
    $files = [];
    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($target, FilesystemIterator::SKIP_DOTS)
    );
    foreach ($iterator as $fileInfo) {
        if ($fileInfo->getExtension() !== 'php') {
            continue;
        }
        $path = $fileInfo->getPathname();
        if (strpos(str_replace('\\', '/', $path), '/vendor/') !== false) {
            continue;
        }
        if (strpos(str_replace('\\', '/', $path), '/Form/Fields/') === false) {
            continue;
        }
        $files[] = $path;
    }
    return $files;
}

$patterns = [
    'script tag'     => '/<script[\s>]/i',
    'style tag'      => '/<style[\s>]/i',
    'onclick attr'   => '/\sonclick\s*=/i',
    'inline style'   => '/\sstyle\s*=/i',
];

$files = collectFieldFiles($target);

foreach ($files as $file) {
    $content = file_get_contents($file);

    foreach ($patterns as $label => $pattern) {
        if (preg_match($pattern, $content, $m, PREG_OFFSET_CAPTURE)) {
            $before = substr($content, 0, $m[0][1]);
            $lineNo = substr_count($before, "\n") + 1;
            $findings[] = [
                'rule' => 'field-inline-js-css',
                'severity' => 'importante',
                'file' => $file,
                'line' => $lineNo,
                'message' => "Trovato $label ('" . trim($m[0][0]) . "') — un Field custom non deve mai emettere JS/CSS inline: JS in theme.js/plugin Admin, CSS in theme.css o view Blade dedicata",
            ];
        }
    }
}

echo json_encode([
    'script' => 'check-field-no-inline-assets',
    'target' => $target,
    'files_checked' => count($files),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
