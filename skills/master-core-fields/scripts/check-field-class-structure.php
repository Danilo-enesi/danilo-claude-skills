<?php
/**
 * check-field-class-structure.php — validazione strutturale di un Field custom (master-core-fields §7).
 *
 * Uso: php check-field-class-structure.php <path-file-o-cartella>
 *
 * Verifica sulle classi Field custom (Master\Foundation\Form\Fields\*.php o
 * Modules/<Nome>/Form/Fields/*.php):
 *  - estende Field/BaseField (import di Master\Foundation\Form\Field)
 *  - dichiara un metodo render() (obbligatorio: produce l'HTML dell'input)
 *  - il namespace combacia con la posizione fisica del file
 *    (.../Foundation/Form/Fields -> Master\Foundation\Form\Fields,
 *     .../Modules/<Nome>/Form/Fields -> Master\Modules\<Nome>\Form\Fields)
 *  - il nome della classe combacia col nome del file (PascalCase)
 *
 * Salta i file sotto vendor/ (non sono Field custom di progetto, non vanno mai
 * modificati né valutati come se lo fossero).
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
        // Solo file dentro una cartella "Form/Fields" — altrimenti non è un Field.
        if (strpos(str_replace('\\', '/', $path), '/Form/Fields/') === false) {
            continue;
        }
        $files[] = $path;
    }
    return $files;
}

function lineOfPattern(string $content, string $pattern): int
{
    if (!preg_match($pattern, $content, $m, PREG_OFFSET_CAPTURE)) {
        return 1;
    }
    $before = substr($content, 0, $m[0][1]);
    return substr_count($before, "\n") + 1;
}

$files = collectFieldFiles($target);

foreach ($files as $file) {
    $content = file_get_contents($file);
    $normalized = str_replace('\\', '/', $file);
    $basename = basename($file, '.php');

    // 1. Estende Field/BaseField
    $extendsBase = preg_match('/class\s+\w+\s+extends\s+(BaseField|Field|\\\\?Master\\\\Foundation\\\\Form\\\\Field)\b/', $content, $extMatch);
    if (!$extendsBase) {
        $findings[] = [
            'rule' => 'field-class-missing-base',
            'severity' => 'critico',
            'file' => $file,
            'line' => 1,
            'message' => "La classe non risulta estendere Field/BaseField (Master\\Foundation\\Form\\Field) — un Field custom deve estendere quella classe base",
            'confidence' => 'da_verificare',
        ];
    }

    // 2. Metodo render() dichiarato
    if (!preg_match('/function\s+render\s*\(/', $content)) {
        $findings[] = [
            'rule' => 'field-class-missing-render',
            'severity' => 'critico',
            'file' => $file,
            'line' => 1,
            'message' => "Nessun metodo render() dichiarato — è obbligatorio: produce l'HTML dell'input (vedi master-core-fields §7)",
        ];
    }

    // 3. Namespace coerente con la posizione fisica
    if (preg_match('/namespace\s+([^;]+);/', $content, $nsMatch)) {
        $namespace = trim($nsMatch[1]);
        $expected = null;

        if (preg_match('#/Foundation/Form/Fields$#', dirname($normalized))) {
            $expected = 'Master\\Foundation\\Form\\Fields';
        } elseif (preg_match('#/Modules/([^/]+)/Form/Fields$#', dirname($normalized), $modMatch)) {
            $expected = 'Master\\Modules\\' . $modMatch[1] . '\\Form\\Fields';
        }

        if ($expected !== null && $namespace !== $expected) {
            $findings[] = [
                'rule' => 'field-class-namespace-mismatch',
                'severity' => 'importante',
                'file' => $file,
                'line' => lineOfPattern($content, '/namespace\s+[^;]+;/'),
                'message' => "Namespace '$namespace' non combacia con la posizione del file — atteso '$expected'",
            ];
        }
    } else {
        $findings[] = [
            'rule' => 'field-class-missing-namespace',
            'severity' => 'importante',
            'file' => $file,
            'line' => 1,
            'message' => "Nessuna dichiarazione namespace trovata nel file",
        ];
    }

    // 4. Nome classe combacia col nome file (PascalCase)
    if (preg_match('/class\s+(\w+)/', $content, $classMatch)) {
        $className = $classMatch[1];
        if ($className !== $basename) {
            $findings[] = [
                'rule' => 'field-class-name-mismatch',
                'severity' => 'importante',
                'file' => $file,
                'line' => lineOfPattern($content, '/class\s+\w+/'),
                'message' => "Il nome della classe ('$className') non combacia col nome del file ('$basename.php')",
            ];
        }
    } else {
        $findings[] = [
            'rule' => 'field-class-not-found',
            'severity' => 'critico',
            'file' => $file,
            'line' => 1,
            'message' => "Nessuna dichiarazione 'class' trovata nel file",
        ];
    }
}

echo json_encode([
    'script' => 'check-field-class-structure',
    'target' => $target,
    'files_checked' => count($files),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
