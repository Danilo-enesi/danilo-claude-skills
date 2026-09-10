<?php
/**
 * check-migrations.php — Fase 1 strutturale: convenzioni Master sulle migration.
 *
 * Uso: php check-migrations.php <path-modulo-o-progetto>
 * Scansiona ricorsivamente database/migrations (o qualunque cartella data)
 * cercando file *_create_<entity>_table.php e verifica:
 *  - UUID come PK (uuid('id')->primary()), MAI $table->id()
 *  - softDeletes() sulla tabella principale
 *  - audit fields created_by/updated_by/deleted_by come string(36) con FK su users
 *  - split in 3 file (main / _translations_ / _values_) quando esistono l'uno o l'altro
 *
 * Output: JSON su stdout, un oggetto per file con l'elenco dei check falliti.
 * Non modifica nulla, sola lettura.
 */

error_reporting(E_ERROR | E_PARSE);

$root = $argv[1] ?? getcwd();
if (!is_dir($root)) {
    fwrite(STDERR, "Path non trovato: $root\n");
    exit(1);
}

function findFiles(string $dir, string $pattern): array
{
    $out = [];
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir, FilesystemIterator::SKIP_DOTS));
    foreach ($it as $file) {
        if ($file->isFile() && preg_match($pattern, $file->getFilename())) {
            $out[] = $file->getPathname();
        }
    }
    return $out;
}

function lineOf(string $content, string $needle): ?int
{
    $lines = explode("\n", $content);
    foreach ($lines as $i => $line) {
        if (stripos($line, $needle) !== false) {
            return $i + 1;
        }
    }
    return null;
}

$migrationFiles = findFiles($root, '/_create_.*_table\.php$/i');
$findings = [];

// Raggruppa per "entity" per capire lo split main/translations/values
$byEntity = [];
foreach ($migrationFiles as $path) {
    $base = basename($path);
    if (preg_match('/_create_(.+?)_(translations|values)_table\.php$/i', $base, $m)) {
        $entity = $m[1];
        $byEntity[$entity]['translations_or_values'][] = $path;
    } elseif (preg_match('/_create_(.+?)_table\.php$/i', $base, $m)) {
        $entity = $m[1];
        $byEntity[$entity]['main'][] = $path;
    }
}

foreach ($migrationFiles as $path) {
    $content = file_get_contents($path);
    $base = basename($path);
    $isMainTable = preg_match('/_create_(.+?)_table\.php$/i', $base) && !preg_match('/_(translations|values)_table\.php$/i', $base);

    // Regola 1: UUID PK (solo sulla tabella principale, non su translations/values che referenziano id già come uuid)
    if ($isMainTable) {
        if (preg_match('/\$table->id\(\s*\)/', $content, $m, PREG_OFFSET_CAPTURE)) {
            $findings[] = [
                'rule' => 'uuid-pk',
                'severity' => 'critico',
                'file' => $path,
                'line' => lineOf($content, '$table->id('),
                'message' => "\$table->id() trovato — la PK deve essere \$table->uuid('id')->primary()",
            ];
        } elseif (!preg_match("/\\\$table->uuid\\(\\s*['\"]id['\"]\\s*\\)\\s*->primary\\(\\s*\\)/", $content)) {
            $findings[] = [
                'rule' => 'uuid-pk',
                'severity' => 'critico',
                'file' => $path,
                'line' => 1,
                'message' => "Nessuna PK uuid('id')->primary() trovata sulla tabella principale — verificare manualmente",
                'confidence' => 'da_verificare',
            ];
        }
    }

    // Regola 2: soft deletes sulla tabella principale
    if ($isMainTable && !preg_match('/softDeletes\(\s*\)/', $content)) {
        $findings[] = [
            'rule' => 'soft-deletes',
            'severity' => 'suggerimento',
            'file' => $path,
            'line' => 1,
            'message' => "Manca \$table->softDeletes() sulla tabella principale",
        ];
    }

    // Regola 3: audit fields come string(36), non uuid(), con FK su users
    if ($isMainTable) {
        foreach (['created_by', 'updated_by', 'deleted_by'] as $field) {
            if (preg_match("/\\\$table->uuid\\(\\s*['\"]" . $field . "['\"]/", $content)) {
                $findings[] = [
                    'rule' => 'audit-fields-type',
                    'severity' => 'suggerimento',
                    'file' => $path,
                    'line' => lineOf($content, $field),
                    'message' => "'$field' dichiarato con uuid() invece di string(36) — deve essere string(36) per compatibilità con la PK di users",
                ];
            } elseif (!preg_match("/\\\$table->string\\(\\s*['\"]" . $field . "['\"]\\s*,\\s*36\\s*\\)/", $content)) {
                $findings[] = [
                    'rule' => 'audit-fields-missing',
                    'severity' => 'suggerimento',
                    'file' => $path,
                    'line' => 1,
                    'message' => "Campo audit '$field' string(36) non trovato",
                    'confidence' => 'da_verificare',
                ];
            } elseif (!preg_match("/foreign\\(\\s*['\"]" . $field . "['\"]\\s*\\)\\s*->references\\(\\s*['\"]id['\"]\\s*\\)\\s*->on\\(\\s*['\"]users['\"]/", $content)) {
                $findings[] = [
                    'rule' => 'audit-fields-fk',
                    'severity' => 'suggerimento',
                    'file' => $path,
                    'line' => 1,
                    'message' => "Campo audit '$field' presente ma senza foreign key esplicita su users",
                ];
            }
        }
    }
}

// Regola 4: split in 3 file — se esiste una migration _translations_ o _values_ senza la main, o viceversa con campi Lang nel modulo
foreach ($byEntity as $entity => $group) {
    if (empty($group['main'])) {
        $findings[] = [
            'rule' => 'migration-split',
            'severity' => 'importante',
            'file' => $group['translations_or_values'][0] ?? "$entity (sconosciuto)",
            'line' => 1,
            'message' => "Trovata migration translations/values per '$entity' ma manca la migration della tabella principale",
        ];
    }
}

echo json_encode([
    'script' => 'check-migrations',
    'root' => $root,
    'files_scanned' => count($migrationFiles),
    'findings' => $findings,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . "\n";
