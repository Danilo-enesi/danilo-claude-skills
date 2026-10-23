<?php
// Elenca le URL statiche del front (KappaEngine) da front/app/route.json, in TUTTE le lingue.
// I segmenti opzionali "(/:x)" si tolgono (resta la pagina base); le rotte con parametri obbligatori ":x" no
// (servono dati veri: aggiungerne a mano un campione). Una pagina presente in una lingua e assente in un'altra
// viene segnalata su stderr. Uso: php urls-from-routes.php [route.json] >> _migration/urls.txt
$file = $argv[1] ?? 'front/app/route.json';
$routes = json_decode((string) @file_get_contents($file), true);
if (!is_array($routes)) { fwrite(STDERR, "ERRORE: $file non leggibile o non è JSON\n"); exit(1); }
$routes = isset($routes['map']) && is_array($routes['map']) ? $routes['map'] : $routes;   // KappaEngine: rotte sotto "map"
$routes = array_filter($routes, 'is_array');
$langs = [];
foreach ($routes as $r) foreach (array_keys((array) ($r['pattern'] ?? [])) as $l) $langs[$l] = true;
$out = [];
foreach ($routes as $name => $r) {
    $p = (array) ($r['pattern'] ?? []);
    foreach (array_diff(array_keys($langs), array_keys($p)) as $l) fwrite(STDERR, "rotta '$name' senza lingua $l\n");
    foreach ($p as $l => $pattern) {
        $base = preg_replace('/\([^()]*\)/', '', $pattern);
        if (strpos($base, ':') !== false) { fwrite(STDERR, "parametri obbligatori, aggiungere a mano un esempio: $pattern\n"); continue; }
        $out[] = $base;
    }
}
echo implode("\n", array_unique($out)), "\n";
