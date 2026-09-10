<?php
/**
 * check-field-destinations.php — Fase 1 comportamentale: destinazione dei campi (master-core-fields §2).
 *
 * Uso: php check-field-destinations.php <path-modulo>
 *
 * Il "name" di ogni addField() deve avere una destinazione reale:
 *  - colonna diretta   -> presente in $fillable del Model
 *  - *Lang (multilingua) -> nome base presente nel $fillable del Model di Translation
 *  - multi-valore (multiple => true) -> presente in $related del Model
 *  - Media (MediaLibrary/Image/File) -> collection con lo stesso nome in registerMediaCollections()
 *  - Address -> il Model usa il trait HasAddresses
 *
 * Limite dichiarato: euristica su regex, non un parser PHP completo. In caso di dubbio
 * marca 'da_verificare' invece di affermare un errore.
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$modulePath = $argv[1] ?? getcwd();
$configPath = $modulePath . DIRECTORY_SEPARATOR . 'config.php';

if (!file_exists($configPath)) {
    fwrite(STDERR, "config.php non trovato in $modulePath\n");
    exit(1);
}

$configContent = file_get_contents($configPath);

// Trova il Model del modulo (Models/*.php, primo/unico file, salvo indicazione contraria)
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
$translationModelFile = null;
if (is_dir($modelsDir)) {
    foreach (glob($modelsDir . DIRECTORY_SEPARATOR . '*.php') as $f) {
        if (stripos(basename($f), 'translation') !== false) {
            $translationModelFile = $f;
            break;
        }
    }
}

$modelContent = $modelFile ? file_get_contents($modelFile) : '';
$translationContent = $translationModelFile ? file_get_contents($translationModelFile) : '';

function extractArrayItems(string $content, string $property): array
{
    if (!preg_match('/\$' . preg_quote($property, '/') . '\s*=\s*\[(.*?)\];/s', $content, $m)) {
        return [];
    }
    preg_match_all('/[\'"]([a-zA-Z0-9_]+)[\'"]/', $m[1], $items);
    return $items[1];
}

$fillable = extractArrayItems($modelContent, 'fillable');
$related = extractArrayItems($modelContent, 'related');
$translationFillable = extractArrayItems($translationContent, 'fillable');
$hasAddresses = (bool) preg_match('/HasAddresses/', $modelContent);

$findings = [];
$lines = explode("\n", $configContent);

function lineOfOffset(array $lines, string $needle, int $startLine = 0): int
{
    foreach ($lines as $i => $line) {
        if ($i < $startLine) continue;
        if (strpos($line, $needle) !== false) return $i + 1;
    }
    return 1;
}

preg_match_all('/addField\s*\(\s*([^,]+),\s*\[(.*?)\]\s*\)\s*;/s', $configContent, $calls, PREG_SET_ORDER);

foreach ($calls as $call) {
    $type = trim($call[1], " \t\n\r\0\x0B'\"");
    $body = $call[2];

    if (!preg_match('/[\'"]name[\'"]\s*=>\s*[\'"]([a-zA-Z0-9_]+)[\'"]/', $body, $nm)) {
        continue; // campo senza name esplicito (es. :separator) — non un vero addField
    }
    $name = $nm[1];
    $lineNo = lineOfOffset($lines, "'$name'") ?: lineOfOffset($lines, "\"$name\"");

    $isLang = (bool) preg_match('/Lang$/', $type);
    $isMedia = (bool) preg_match('/^(MediaLibrary|Image|File)$/', $type);
    $isAddress = ($type === 'Address');
    $isMultiple = (bool) preg_match('/[\'"]multiple[\'"]\s*=>\s*true/', $body);

    if ($isMedia) {
        if (!preg_match('/registerMediaCollections[\s\S]*?' . preg_quote($name, '/') . '/', $modelContent)) {
            $findings[] = [
                'rule' => 'field-destination-media',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo media '$name' (tipo $type) senza collection corrispondente in registerMediaCollections() del Model",
                'confidence' => 'da_verificare',
            ];
        }
        continue;
    }

    if ($isAddress) {
        if (!$hasAddresses) {
            $findings[] = [
                'rule' => 'field-destination-address',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo Address '$name' ma il Model non usa il trait HasAddresses",
            ];
        }
        continue;
    }

    if ($isLang) {
        if (!$translationModelFile) {
            $findings[] = [
                'rule' => 'field-destination-lang',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo multilingua '$name' (tipo $type) ma non è stato trovato un Model di Translation nel modulo",
                'confidence' => 'da_verificare',
            ];
        } elseif (!in_array($name, $translationFillable, true)) {
            $findings[] = [
                'rule' => 'field-destination-lang',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo multilingua '$name' non presente nel \$fillable del Model di Translation ($translationModelFile)",
            ];
        }
        continue;
    }

    if ($isMultiple) {
        if (!in_array($name, $related, true)) {
            $findings[] = [
                'rule' => 'field-destination-multivalue',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo multi-valore '$name' non presente in \$related del Model — i valori non verranno salvati da saveData()",
            ];
        }
        continue;
    }

    // Colonna diretta: deve essere nel $fillable, salvo campi noti non persistiti direttamente (Button, :separator già filtrati)
    if (!in_array($name, $fillable, true) && !in_array($name, $related, true)) {
        $findings[] = [
            'rule' => 'field-destination-column',
            'severity' => 'importante',
            'file' => $configPath,
            'line' => $lineNo,
            'message' => "Campo '$name' (tipo $type) non presente in \$fillable del Model — se salvato, sparirà silenziosamente",
            'confidence' => 'da_verificare',
        ];
    }
}

echo json_encode([
    'script' => 'check-field-destinations',
    'module' => $modulePath,
    'model_file' => $modelFile,
    'translation_model_file' => $translationModelFile,
    'fields_checked' => count($calls),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
