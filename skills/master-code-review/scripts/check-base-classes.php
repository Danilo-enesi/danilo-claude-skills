<?php
/**
 * check-base-classes.php — Fase 1 strutturale: classi base corrette nei moduli.
 *
 * Uso: php check-base-classes.php <path-modulo>
 *
 * Verifica, PER MODULO (cartella con config.php alla radice):
 *  - Controllers/AdminController.php estende Crud\Controllers\AdminController (NON Base\Controllers)
 *  - Classes/Module.php estende Crud\Classes\Module (NON Base\Classes\BaseModule)
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$root = $argv[1] ?? getcwd();
if (!is_dir($root)) {
    fwrite(STDERR, "Path non trovato: $root\n");
    exit(1);
}

function findModules(string $dir): array
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

function readExtends(string $path): ?string
{
    if (!file_exists($path)) {
        return null;
    }
    $content = file_get_contents($path);
    if (preg_match('/class\s+\w+\s+extends\s+([A-Za-z0-9_\\\\]+)/', $content, $m)) {
        return $m[1];
    }
    return null;
}

$modules = findModules($root);
$findings = [];

foreach ($modules as $modulePath) {
    $moduleName = basename($modulePath);

    $controllerPath = $modulePath . DIRECTORY_SEPARATOR . 'Controllers' . DIRECTORY_SEPARATOR . 'AdminController.php';
    if (file_exists($controllerPath)) {
        $extends = readExtends($controllerPath);
        if ($extends !== null && !preg_match('/Crud\\\\Controllers\\\\AdminController$|^AdminController$/', $extends)) {
            $findings[] = [
                'rule' => 'controller-base-class',
                'severity' => 'importante',
                'file' => $controllerPath,
                'line' => 1,
                'message' => "AdminController del modulo '$moduleName' estende '$extends' invece di Master\\Foundation\\Modules\\Crud\\Controllers\\AdminController",
            ];
        } elseif ($extends !== null && preg_match('/Base\\\\Controllers/', $extends)) {
            $findings[] = [
                'rule' => 'controller-base-class',
                'severity' => 'importante',
                'file' => $controllerPath,
                'line' => 1,
                'message' => "AdminController del modulo '$moduleName' estende la classe Base invece della Crud",
            ];
        }
    }

    $modulePhpPath = $modulePath . DIRECTORY_SEPARATOR . 'Classes' . DIRECTORY_SEPARATOR . 'Module.php';
    if (file_exists($modulePhpPath)) {
        $extends = readExtends($modulePhpPath);
        if ($extends !== null && !preg_match('/Crud\\\\Classes\\\\Module$|^Module$/', $extends)) {
            $findings[] = [
                'rule' => 'module-class-base-class',
                'severity' => 'importante',
                'file' => $modulePhpPath,
                'line' => 1,
                'message' => "Classes/Module.php del modulo '$moduleName' estende '$extends' invece di Master\\Foundation\\Modules\\Crud\\Classes\\Module",
            ];
        } elseif ($extends !== null && preg_match('/Base\\\\Classes\\\\BaseModule/', $extends)) {
            $findings[] = [
                'rule' => 'module-class-base-class',
                'severity' => 'importante',
                'file' => $modulePhpPath,
                'line' => 1,
                'message' => "Classes/Module.php del modulo '$moduleName' estende Base\\Classes\\BaseModule invece della Crud",
            ];
        }
    }
}

echo json_encode([
    'script' => 'check-base-classes',
    'root' => $root,
    'modules_scanned' => count($modules),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
