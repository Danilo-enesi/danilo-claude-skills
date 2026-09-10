<?php
/**
 * check-content-blocks.php — Fase 1 comportamentale: sistema blocchi Contents (master-page-content).
 *
 * Uso: php check-content-blocks.php <path-modulo>
 *
 * Se il modulo usa il campo Contents (in config.php) o dichiara $contentClass/$content_foreign_key
 * nel Model, verifica:
 *  - esiste davvero $contentClass/$content_foreign_key nel Model (o eredita da Page/usa HasContentBlocks)
 *  - il rendering dei blocchi (componente/Blade satellite) chiama getBlockData()/getContentMedia()
 *    invece di avere testo/ordine hardcodati
 *  - eventuali media letti dalle righe *_contents non vengono cercati dentro data JSON
 *    (antipattern: devono stare nella media collection Spatie content<Tipo>__<media_id>)
 *
 * Limite dichiarato: euristico, non un parser PHP/Blade completo — i casi dubbi vanno marcati
 * 'da_verificare', non affermati come errore.
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$modulePath = $argv[1] ?? getcwd();
$configPath = $modulePath . DIRECTORY_SEPARATOR . 'config.php';
$findings = [];

$usesContentsField = false;
if (file_exists($configPath)) {
    $configContent = file_get_contents($configPath);
    $usesContentsField = (bool) preg_match('/addField\s*\(\s*[\'"]Contents[\'"]/', $configContent);
}

$modelFile = null;
$modelsDir = $modulePath . DIRECTORY_SEPARATOR . 'Models';
if (is_dir($modelsDir)) {
    foreach (glob($modelsDir . DIRECTORY_SEPARATOR . '*.php') as $f) {
        if (stripos(basename($f), 'translation') === false) {
            $modelFile = $f;
            break;
        }
    }
}
$modelContent = $modelFile ? file_get_contents($modelFile) : '';

$declaresContentClass = (bool) preg_match('/\$contentClass\s*=/', $modelContent);
$declaresForeignKey = (bool) preg_match('/\$content_foreign_key\s*=/', $modelContent);
$usesTrait = (bool) preg_match('/HasContentBlocks/', $modelContent);
$extendsPage = (bool) preg_match('/extends\s+.*\bPage\b/', $modelContent);

if ($usesContentsField && $modelFile) {
    if (!$declaresContentClass && !$declaresForeignKey && !$usesTrait && !$extendsPage) {
        $findings[] = [
            'rule' => 'content-blocks-not-installed',
            'severity' => 'critico',
            'file' => $modelFile,
            'line' => 1,
            'message' => "config.php usa il campo Contents ma il Model non ha \$contentClass/\$content_foreign_key, non usa HasContentBlocks e non eredita da Page — il sistema blocchi non risulta installato",
        ];
    }

    $hasContentsMigration = false;
    if (is_dir($modulePath)) {
        $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($modulePath, FilesystemIterator::SKIP_DOTS));
        foreach ($it as $f) {
            if ($f->isFile() && preg_match('/_create_.*_contents_table\.php$/i', $f->getFilename())) {
                $hasContentsMigration = true;
                break;
            }
        }
    }
    if (!$hasContentsMigration) {
        $findings[] = [
            'rule' => 'content-blocks-missing-table',
            'severity' => 'importante',
            'file' => $modulePath,
            'line' => 1,
            'message' => "config.php usa il campo Contents ma non è stata trovata una migration '*_contents_table' nel modulo",
            'confidence' => 'da_verificare',
        ];
    }
}

// Cerca componenti/Blade di rendering blocchi nel modulo e verifica che leggano da getBlockData()/getContentMedia()
$viewDirs = [
    $modulePath . DIRECTORY_SEPARATOR . 'Views',
    $modulePath . DIRECTORY_SEPARATOR . 'resources' . DIRECTORY_SEPARATOR . 'views',
];
foreach ($viewDirs as $dir) {
    if (!is_dir($dir)) {
        continue;
    }
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($it as $f) {
        if (!$f->isFile() || !preg_match('/block/i', $f->getFilename())) {
            continue;
        }
        $content = file_get_contents($f->getPathname());
        $readsBlockData = (bool) preg_match('/getBlockData\s*\(|getContentMedia\s*\(/', $content);
        if (!$readsBlockData) {
            $findings[] = [
                'rule' => 'content-block-static-render',
                'severity' => 'da_verificare',
                'file' => $f->getPathname(),
                'line' => 1,
                'message' => "View/Blade con 'block' nel nome ma nessuna chiamata a getBlockData()/getContentMedia() trovata — verificare se il contenuto è davvero DB-driven",
            ];
        }
        if (preg_match('/->data\s*\[\s*[\'"]media/', $content)) {
            $findings[] = [
                'rule' => 'content-block-media-in-data',
                'severity' => 'importante',
                'file' => $f->getPathname(),
                'line' => 1,
                'message' => "Media cercato dentro il JSON 'data' del blocco — i media vivono nella collection Spatie content<Tipo>__<media_id>, in 'data' c'è solo il media_id",
            ];
        }
    }
}

echo json_encode([
    'script' => 'check-content-blocks',
    'module' => $modulePath,
    'uses_contents_field' => $usesContentsField,
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
