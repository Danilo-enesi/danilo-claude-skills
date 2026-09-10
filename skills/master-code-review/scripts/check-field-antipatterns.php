<?php
/**
 * check-field-antipatterns.php — Fase 1 comportamentale: antipattern noti sui Field (master-core-fields).
 *
 * Uso: php check-field-antipatterns.php <path-modulo>
 *
 * Verifica su config.php del modulo:
 *  - query grezza (DB::table/DB::raw/->get()) scritta dentro il blocco di un addField
 *    invece di passare da un metodo del Model/Facade ("logica nel posto sbagliato")
 *  - suffisso __it/__en scritto a mano sul name di un campo *Lang (ci pensa già il framework)
 *  - Checkbox/Published con rules => [...'required'...] (se non spuntato non arriva in Request)
 *  - campo dichiarato con addField ma mai referenziato in un addTab (non verrà mai renderizzato)
 *
 * E sui Field custom (Form/Fields/*.php del modulo o di progetto):
 *  - JS/CSS inline dentro render() (<script>, <style>, onclick=, style=)
 *
 * Output: JSON su stdout. Sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$modulePath = $argv[1] ?? getcwd();
$configPath = $modulePath . DIRECTORY_SEPARATOR . 'config.php';
$findings = [];

if (file_exists($configPath)) {
    $configContent = file_get_contents($configPath);
    $lines = explode("\n", $configContent);

    preg_match_all('/addField\s*\(\s*([^,]+),\s*\[(.*?)\]\s*\)\s*;/s', $configContent, $calls, PREG_SET_ORDER);

    $declaredNames = [];
    foreach ($calls as $call) {
        $type = trim($call[1], " \t\n\r\0\x0B'\"");
        $body = $call[2];

        if (!preg_match('/[\'"]name[\'"]\s*=>\s*[\'"]([a-zA-Z0-9_]+)[\'"]/', $body, $nm)) {
            continue;
        }
        $name = $nm[1];
        $declaredNames[] = $name;
        $lineNo = 1;
        foreach ($lines as $i => $line) {
            if (strpos($line, "'$name'") !== false || strpos($line, "\"$name\"") !== false) {
                $lineNo = $i + 1;
                break;
            }
        }

        // Query grezza dentro il blocco del campo
        if (preg_match('/DB::(table|raw)\s*\(|->get\s*\(\s*\)/', $body)) {
            $findings[] = [
                'rule' => 'field-inline-query',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo '$name': query costruita direttamente in config.php invece di un metodo del Model/Facade — logica nel posto sbagliato",
            ];
        }

        // Suffisso lang manuale su campo *Lang
        if (preg_match('/Lang$/', $type) && preg_match('/__(it|en|es|fr|de)$/', $name)) {
            $findings[] = [
                'rule' => 'field-manual-lang-suffix',
                'severity' => 'suggerimento',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo '$name' (tipo $type) ha già il suffisso lingua nel name — il campo *Lang lo genera da solo, non va scritto a mano",
            ];
        }

        // Checkbox/Published con required
        if (preg_match('/^(Checkbox|Published)$/', $type) && preg_match('/[\'"]rules[\'"]\s*=>\s*\[[^\]]*required/', $body)) {
            $findings[] = [
                'rule' => 'field-checkbox-required',
                'severity' => 'importante',
                'file' => $configPath,
                'line' => $lineNo,
                'message' => "Campo '$name' (tipo $type) ha 'required' nelle rules — se non spuntato il campo non arriva in Request, la regola non si comporta come atteso",
            ];
        }
    }

    // Campi mai referenziati in un addTab
    preg_match_all('/addTab\s*\(\s*\[(.*?)\]\s*\)\s*;/s', $configContent, $tabBlocks);
    $tabContent = implode("\n", $tabBlocks[1] ?? []);
    foreach (array_unique($declaredNames) as $name) {
        $referenced = preg_match('/[\'"]' . preg_quote($name, '/') . '(\||[\'"])/', $tabContent);
        if (!$referenced) {
            $findings[] = [
                'rule' => 'field-not-in-any-tab',
                'severity' => 'suggerimento',
                'file' => $configPath,
                'line' => 1,
                'message' => "Campo '$name' dichiarato con addField ma non referenziato in nessun addTab — non verrà mai renderizzato",
                'confidence' => 'da_verificare',
            ];
        }
    }
}

// Field custom: JS/CSS inline
$fieldDirs = [
    $modulePath . DIRECTORY_SEPARATOR . 'Form' . DIRECTORY_SEPARATOR . 'Fields',
];
foreach ($fieldDirs as $dir) {
    if (!is_dir($dir)) {
        continue;
    }
    foreach (glob($dir . DIRECTORY_SEPARATOR . '*.php') as $fieldFile) {
        $content = file_get_contents($fieldFile);
        if (preg_match('/<script[\s>]|<style[\s>]|\sonclick\s*=|\sstyle\s*=/i', $content, $m, PREG_OFFSET_CAPTURE)) {
            $before = substr($content, 0, $m[0][1]);
            $lineNo = substr_count($before, "\n") + 1;
            $findings[] = [
                'rule' => 'field-inline-js-css',
                'severity' => 'importante',
                'file' => $fieldFile,
                'line' => $lineNo,
                'message' => "Field custom contiene markup/JS inline ('" . trim($m[0][0]) . "') — JS va in theme.js/plugin Admin, CSS in theme.css, mai dentro render()",
            ];
        }
    }
}

echo json_encode([
    'script' => 'check-field-antipatterns',
    'module' => $modulePath,
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
