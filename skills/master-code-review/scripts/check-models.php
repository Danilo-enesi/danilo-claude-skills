<?php
/**
 * check-models.php — Fase 1 strutturale: convenzioni Master sui Model Eloquent.
 *
 * Uso: php check-models.php <path-modulo-o-progetto>
 * Scansiona ricorsivamente Models/*.php e verifica:
 *  - estende Master\Foundation\Modules\Base\Models\Model
 *  - protected $keyType = 'string' e public $incrementing = false
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$root = $argv[1] ?? getcwd();
if (!is_dir($root)) {
    fwrite(STDERR, "Path non trovato: $root\n");
    exit(1);
}

function findFilesM(string $dir, string $pattern): array
{
    $out = [];
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if ($file->isFile() && preg_match($pattern, $file->getPathname())) {
            $out[] = $file->getPathname();
        }
    }
    return $out;
}

function lineOfM(string $content, string $needle): ?int
{
    $lines = explode("\n", $content);
    foreach ($lines as $i => $line) {
        if (stripos($line, $needle) !== false) {
            return $i + 1;
        }
    }
    return null;
}

// Solo file dentro una cartella Models/, esclude Translation dei sotto-model se serve un check dedicato (qui trattati uguale)
$modelFiles = findFilesM($root, '#[/\\\\]Models[/\\\\][A-Za-z0-9_]+\.php$#');
$findings = [];

foreach ($modelFiles as $path) {
    $content = file_get_contents($path);
    $className = basename($path, '.php');

    if (!preg_match('/class\s+' . preg_quote($className, '/') . '\s+extends\s+([A-Za-z0-9_\\\\]+)/', $content, $m)) {
        $findings[] = [
            'rule' => 'model-base-class',
            'severity' => 'da_verificare',
            'file' => $path,
            'line' => 1,
            'message' => "Impossibile determinare la classe estesa da '$className'",
        ];
        continue;
    }

    $extends = $m[1];
    $isBaseModel = (bool) preg_match('/Base\\\\Models\\\\Model$|^Model$/', $extends);
    $usesUse = preg_match('/use\s+Master\\\\Foundation\\\\Modules\\\\Base\\\\Models\\\\Model\s*;/', $content);

    if (!$isBaseModel && !$usesUse) {
        $findings[] = [
            'rule' => 'model-base-class',
            'severity' => 'critico',
            'file' => $path,
            'line' => lineOfM($content, 'extends'),
            'message' => "'$className' estende '$extends' invece di Master\\Foundation\\Modules\\Base\\Models\\Model",
        ];
    }

    if (!preg_match('/\$keyType\s*=\s*[\'"]string[\'"]/', $content)) {
        $findings[] = [
            'rule' => 'model-key-type',
            'severity' => 'critico',
            'file' => $path,
            'line' => 1,
            'message' => "'$className' non dichiara protected \$keyType = 'string'",
        ];
    }

    if (!preg_match('/\$incrementing\s*=\s*false/', $content)) {
        $findings[] = [
            'rule' => 'model-incrementing',
            'severity' => 'critico',
            'file' => $path,
            'line' => 1,
            'message' => "'$className' non dichiara public \$incrementing = false",
        ];
    }
}

echo json_encode([
    'script' => 'check-models',
    'root' => $root,
    'files_scanned' => count($modelFiles),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
