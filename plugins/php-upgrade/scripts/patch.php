<?php
// Applica le correzioni minime elencate in _migration/patches.php (= SPEC.md approvata).
//   php patch.php [--apply] [ID...]     senza --apply è un dry-run; con ID applica solo quelle patch
// Ogni patch deve trovare il testo originale esattamente una volta, oppure risultare già applicata;
// in ogni altro caso lo script si ferma senza scrivere nulla.
//
// patches.php restituisce un array di [id, file, tipo, cerca, nuovo]:
//   replace: sostituisce "cerca" con "nuovo"
//   before:  inserisce la riga "nuovo" prima della riga che contiene "cerca" (stessa indentazione e fine riga)
//   copy:    copia _migration/files/<cerca> in <file>

$root = getenv('MIG_ROOT') ?: trim((string) shell_exec('git rev-parse --show-toplevel'));
$list = "$root/_migration/patches.php";
function fail($msg) { fwrite(STDERR, "ERRORE: $msg\n"); exit(1); }
if (!is_file($list)) fail("manca $list");
$args = array_slice($argv, 1);
$apply = in_array('--apply', $args, true);
$only = array_values(array_filter($args, fn($a) => $a !== '--apply'));
foreach ($only as $a) if ($a[0] === '-') fail("argomento sconosciuto: $a");
$patches = require $list;

$writes = [];   // file => nuovo contenuto (in memoria finché tutte le patch non sono valide)
foreach ($patches as [$id, $file, $type, $find, $new]) {
    if ($only && !in_array($id, $only, true)) continue;
    $path = "$root/$file";
    if ($type === 'copy') {
        $src = file_get_contents("$root/_migration/files/$find");
        if ($src === false) fail("$id: manca _migration/files/$find");
        if (is_file($path) && file_get_contents($path) === $src) { echo "$id già applicata  $file\n"; continue; }
        if (is_file($path)) fail("$id: $file esiste già con un contenuto diverso");
        $writes[$file] = $src;
        echo "$id crea            $file\n";
        continue;
    }
    if (!is_file($path)) fail("$id: file non trovato: $file");
    $text = $writes[$file] ?? file_get_contents($path);
    $nFind = substr_count($text, $find);
    // "nuovo" può contenere "cerca" (es. '<?php' -> '<?php require...'): si controlla prima se è già applicata
    if (substr_count($text, $new) > 0) { echo "$id già applicata  $file\n"; continue; }
    if ($nFind !== 1) fail("$id: atteso 1 occorrenza in $file, trovate $nFind (il codice è diverso da quello analizzato)");
    if ($type === 'replace') {
        $text = str_replace($find, $new, $text);
    } elseif ($type === 'before') {
        $eol = strpos($text, "\r\n") !== false ? "\r\n" : "\n";
        $pos = strpos($text, $find);
        $lineStart = strrpos(substr($text, 0, $pos), "\n");
        $lineStart = $lineStart === false ? 0 : $lineStart + 1;
        $indent = substr($text, $lineStart, $pos - $lineStart);
        if (trim($indent) !== '') fail("$id: l'ancora non è a inizio riga in $file");
        $text = substr($text, 0, $lineStart) . $indent . $new . $eol . substr($text, $lineStart);
    } else {
        fail("$id: tipo sconosciuto '$type'");
    }
    $writes[$file] = $text;
    echo "$id modifica        $file\n";
}

if (!$writes) { echo "Niente da fare: tutte le patch sono già applicate.\n"; exit(0); }
if (!$apply) { echo "(dry-run) nessun file scritto. Rilancia con --apply.\n"; exit(0); }

foreach ($writes as $file => $text) {
    $path = "$root/$file";
    $tmp = "$path.mig-tmp";
    if (file_put_contents($tmp, $text) !== strlen($text) || !rename($tmp, $path)) {
        @unlink($tmp);
        fail("scrittura fallita: $file (esegui rollback.sh per annullare il passo)");
    }
}
echo "OK: " . count($writes) . " file scritti.\n";
