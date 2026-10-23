<?php
// A2: costanti che in PHP 8 possono essere un Error (in 7.x valevano il proprio nome con un Warning).
// Una costante usata è sicura solo se:
//   a) ha un fallback: defined('X') poco prima (es. `defined('X') ? X : ''`), oppure
//   b) è definita nel codice: define('X') / const X (anche nelle librerie, es. PDF_* di tcpdf), oppure
//   c) è una traduzione presente nelle lingue del suo sistema:
//        front  -> front/app/settings/lang/<sito>/language_<lingua>.inc   (define generati da Admin › Linguaggi): TUTTE le lingue
//        admin  -> admin/lang/language_<lingua>_php.inc                     (JSON con "codice"): almeno una (il default copre le altre)
// Segnala:
//   «traduzione mancante in: eng»        presente in alcune lingue, non in tutte  -> aggiungerla in Linguaggi
//   «senza definizione né fallback»     in nessuna lingua né nel codice          -> traduzione nuova (Linguaggi)
//                                                                                  o costante di config (defined() ? X : '')
// Non vede le costanti lette con constant($variabile).
// Eccezioni verificate a mano: _migration/const-ignore.txt ("percorso NOME  # motivo", es. codice morto).
// Uso: php -d short_open_tag=1 scan-undefconst.php   (MIG_ROOT, MIG_SKIP_PREFIXES = prefissi relativi separati da |)
$root = rtrim(str_replace('\\', '/', getenv('MIG_ROOT') ?: getcwd()), '/');
$skip = '#^(?:' . implode('|', array_map(fn($p) => preg_quote(trim($p), '#'), array_filter(explode('|', getenv('MIG_SKIP_PREFIXES') ?: '_migration/|.git/|vendor/|node_modules/')))) . ')#i';
$ignore = [];
foreach (@file("$root/_migration/const-ignore.txt", FILE_IGNORE_NEW_LINES) ?: [] as $l) {
    $l = trim(preg_replace('/#.*/', '', $l));
    if ($l !== '') $ignore[preg_replace('/\s+/', ' ', $l)] = true;
}

$code = [];               // NOME => 1 (define/const nel codice)
$lang = ['front' => [], 'admin' => []];   // sistema => lingua => [NOME => 1]
$scan = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
foreach ($it as $f) {
    $p = str_replace('\\', '/', $f->getPathname());
    $rel = substr($p, strlen($root) + 1);
    if (preg_match('#^(\.git|_migration/out|node_modules)/#', $rel)) continue;
    if (preg_match('#^admin/lang/language_([a-z]+)_php\.inc$#', $rel, $lm)) {
        preg_match_all('/"codice"\s*:\s*"([A-Za-z0-9_]+)"/', file_get_contents($p), $m);
        foreach ($m[1] as $c) $lang['admin'][$lm[1]][strtoupper($c)] = 1;
        continue;
    }
    if (!preg_match('/\.(php|inc)$/', $rel)) continue;
    $src = file_get_contents($p);
    preg_match_all('/\bdefine\s*\(\s*[\'"]\\\\?([A-Za-z0-9_\\\\]+)[\'"]/i', $src, $m);
    if (preg_match('#^front/app/settings/lang/[^/]+/language_([a-z]+)\.inc$#', $rel, $lm)) {
        foreach ($m[1] as $c) $lang['front'][$lm[1]][strtoupper($c)] = 1;
        continue;
    }
    foreach ($m[1] as $c) $code[strtoupper(basename(str_replace('\\', '/', $c)))] = 1;
    preg_match_all('/\bconst\s+([A-Za-z0-9_]+)\s*=/', $src, $m);
    foreach ($m[1] as $c) $code[strtoupper($c)] = 1;
    if (!preg_match($skip, $rel)) $scan[$rel] = $src;
}
$builtin = array_change_key_case(get_defined_constants(), CASE_UPPER);
$kw = ['TRUE', 'FALSE', 'NULL', 'SELF', 'PARENT', 'STATIC'];
$out = [];
foreach ($scan as $rel => $src) {
    // sistema di traduzioni del file: admin/ usa quello dell'admin, il resto quello del front (se esiste)
    $sys = strpos($rel, 'admin/') === 0 || !$lang['front'] ? 'admin' : 'front';
    $t = @token_get_all($src);
    $n = count($t);
    for ($i = 0; $i < $n; $i++) {
        if (!is_array($t[$i]) || $t[$i][0] !== T_STRING) continue;
        $name = $t[$i][1];
        if (!preg_match('/^[A-Z][A-Z0-9_]+$/', $name)) continue;
        $u = strtoupper($name);
        if (isset($code[$u]) || isset($builtin[$u]) || in_array($u, $kw) || isset($ignore["$rel $name"])) continue;
        $j = $i + 1; while ($j < $n && is_array($t[$j]) && $t[$j][0] === T_WHITESPACE) $j++;
        if ($j < $n && in_array($t[$j], ['(', ':'], true)) continue;                                        // funzione o etichetta
        if ($j < $n && is_array($t[$j]) && in_array($t[$j][0], [T_DOUBLE_COLON, T_VARIABLE, T_STRING])) continue; // Classe:: o tipo
        $b = $i - 1; while ($b >= 0 && is_array($t[$b]) && $t[$b][0] === T_WHITESPACE) $b--;
        if ($b >= 0 && is_array($t[$b]) && in_array($t[$b][0], [T_OBJECT_OPERATOR, T_DOUBLE_COLON, T_NEW, T_FUNCTION, T_CONST, T_CLASS,
            T_INTERFACE, T_TRAIT, T_EXTENDS, T_IMPLEMENTS, T_USE, T_NAMESPACE, T_INSTANCEOF, T_GOTO, T_NS_SEPARATOR])) continue;
        // a) fallback: defined('NOME') nelle istruzioni subito prima
        $before = implode('', array_map(fn($x) => is_array($x) ? $x[1] : $x, array_slice($t, max(0, $i - 40), 40)));
        if (preg_match('/defined\s*\(\s*[\'"]' . preg_quote($name, '/') . '[\'"]\s*\)/', $before)) continue;
        // c) traduzione: dove c'è e dove manca
        $have = array_keys(array_filter($lang[$sys], fn($set) => isset($set[$u])));
        $miss = array_diff(array_keys($lang[$sys]), $have);
        // l'admin Master completa le voci mancanti con la lingua di default (Translator::loadLang): basta una lingua
        if ($have && (!$miss || $sys === 'admin')) continue;
        $why = $have ? 'traduzione mancante in: ' . implode(',', $miss) . " ($sys)" : 'senza definizione né fallback';
        $out[] = sprintf("%s:%d %s — %s", $rel, $t[$i][2], $name, $why);
    }
}
$out = array_values(array_unique($out));
sort($out);
echo $out ? implode("\n", $out) . "\n" : '';
exit($out ? 1 : 0);
