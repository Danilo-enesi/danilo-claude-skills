<?php
// A1: chiamate a funzioni/metodi del progetto con meno argomenti dei parametri obbligatori.
// In 7.0 era un Warning (il parametro valeva null); da 7.1 è un ArgumentCountError (fatale).
// Euristica per nome: segnala solo se TUTTE le definizioni con quel nome richiedono più argomenti.
// Eccezioni verificate a mano: _migration/argcount-ignore.txt ("percorso nomefunzione", es. metodi nativi omonimi).
// Uso: php -d short_open_tag=1 scan-argcount.php   (MIG_ROOT, MIG_SKIP_PREFIXES = prefissi relativi separati da |)
$root = rtrim(str_replace('\\', '/', getenv('MIG_ROOT') ?: getcwd()), '/');
$skip = '#^(?:' . implode('|', array_map(fn($p) => preg_quote(trim($p), '#'), array_filter(explode('|', getenv('MIG_SKIP_PREFIXES') ?: '_migration/|.git/|vendor/|node_modules/')))) . ')#i';
$ignore = [];
foreach (@file("$root/_migration/argcount-ignore.txt", FILE_IGNORE_NEW_LINES) ?: [] as $l) {
    $l = trim(preg_replace('/#.*/', '', $l));
    if ($l !== '') $ignore[preg_replace('/\s+/', ' ', $l)] = true;
}

$toks = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
foreach ($it as $f) {
    $rel = substr(str_replace('\\', '/', $f->getPathname()), strlen($root) + 1);
    if (preg_match('/\.(php|inc)$/', $rel) && !preg_match($skip, $rel)) $toks[$rel] = @token_get_all(file_get_contents($f->getPathname()));
}

function skipWs($t, $j, $n) { while ($j < $n && is_array($t[$j]) && in_array($t[$j][0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT])) $j++; return $j; }

$defs = []; // nome => [parametri obbligatori, ...]
foreach ($toks as $t) {
    $n = count($t);
    for ($i = 0; $i < $n; $i++) {
        if (!is_array($t[$i]) || $t[$i][0] !== T_FUNCTION) continue;
        $j = skipWs($t, $i + 1, $n);
        if ($j < $n && $t[$j] === '&') $j = skipWs($t, $j + 1, $n);
        if (!is_array($t[$j]) || $t[$j][0] !== T_STRING) continue; // closure
        $name = strtolower($t[$j][1]);
        while ($j < $n && $t[$j] !== '(') $j++;
        $depth = 0; $req = 0; $cur = $def = $var = false;
        for ($k = $j; $k < $n; $k++) {
            $x = $t[$k];
            if ($x === '(' || $x === '[') { $depth++; continue; }
            if ($x === ')' || $x === ']') { if (--$depth === 0) break; continue; }
            if ($depth !== 1) continue;
            if (is_array($x) && $x[0] === T_VARIABLE) $cur = true;
            if (is_array($x) && $x[0] === T_ELLIPSIS) $var = true;
            if ($x === '=') $def = true;
            if ($x === ',') { if ($cur && !$def && !$var) $req++; $cur = $def = false; }
        }
        if ($cur && !$def && !$var) $req++;
        $defs[$name][] = $req;
    }
}

$out = [];
foreach ($toks as $rel => $t) {
    $n = count($t);
    for ($i = 0; $i < $n; $i++) {
        if (!is_array($t[$i]) || $t[$i][0] !== T_STRING || !isset($defs[strtolower($t[$i][1])])) continue;
        $b = $i - 1;
        while ($b >= 0 && is_array($t[$b]) && $t[$b][0] === T_WHITESPACE) $b--;
        if ($b >= 0 && $t[$b] === '&') { $b--; while ($b >= 0 && is_array($t[$b]) && $t[$b][0] === T_WHITESPACE) $b--; }
        if ($b >= 0 && is_array($t[$b]) && in_array($t[$b][0], [T_FUNCTION, T_NEW, T_CONST, T_CLASS])) continue;
        $j = skipWs($t, $i + 1, $n);
        if ($j >= $n || $t[$j] !== '(') continue;
        $depth = 0; $commas = 0; $any = $unpack = false;
        for ($k = $j; $k < $n; $k++) {
            $x = $t[$k];
            if ($x === '(' || $x === '[' || $x === '{' || (is_array($x) && in_array($x[0], [T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES]))) { if (++$depth > 1) $any = true; continue; }
            if ($x === ')' || $x === ']' || $x === '}') { if (--$depth === 0) break; continue; }
            if ($depth !== 1) continue;
            if ($x === ',') { $commas++; continue; }
            if (is_array($x) && $x[0] === T_ELLIPSIS) $unpack = true;
            if (!(is_array($x) && in_array($x[0], [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT]))) $any = true;
        }
        $passed = $any ? $commas + 1 : 0;
        $name = $t[$i][1];
        if ($unpack || $passed >= min($defs[strtolower($name)]) || isset($ignore["$rel $name"])) continue;
        $out[] = sprintf("%s:%d %s() passati=%d richiesti=%s", $rel, $t[$i][2], $name, $passed, implode('/', array_unique($defs[strtolower($name)])));
    }
}
sort($out);
echo $out ? implode("\n", $out) . "\n" : '';
exit($out ? 1 : 0);
