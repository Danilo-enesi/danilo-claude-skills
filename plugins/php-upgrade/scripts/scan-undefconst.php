<?php
// A2: costanti usate ma mai definite. In 7.x valevano il proprio nome (Warning); in 8 sono un Error.
// Definite = define('X') / const X in TUTTO il progetto (anche nelle librerie: es. PDF_* di tcpdf)
//          + i "codice" dei JSON di lingua dell'admin Master (admin/lang/*.inc).
// Usate    = NOMI_MAIUSCOLI fuori dalle librerie, che non sono funzioni, classi, proprietà o costanti di classe.
// Eccezioni verificate a mano: _migration/const-ignore.txt ("percorso NOME", es. codice morto o protetto da defined()).
// Uso: php -d short_open_tag=1 scan-undefconst.php   (MIG_ROOT, MIG_SKIP_PREFIXES = prefissi relativi separati da |)
$root = rtrim(str_replace('\\', '/', getenv('MIG_ROOT') ?: getcwd()), '/');
$skip = '#^(?:' . implode('|', array_map(fn($p) => preg_quote(trim($p), '#'), array_filter(explode('|', getenv('MIG_SKIP_PREFIXES') ?: '_migration/|.git/|vendor/|node_modules/')))) . ')#i';
$ignore = [];
foreach (@file("$root/_migration/const-ignore.txt", FILE_IGNORE_NEW_LINES) ?: [] as $l) {
    $l = trim(preg_replace('/#.*/', '', $l));
    if ($l !== '') $ignore[preg_replace('/\s+/', ' ', $l)] = true;
}

$defined = [];
$scan = [];
$it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
foreach ($it as $f) {
    $p = str_replace('\\', '/', $f->getPathname());
    $rel = substr($p, strlen($root) + 1);
    if (preg_match('#^(\.git|_migration/out|node_modules)/#', $rel)) continue;   // mai: né definizioni né usi
    if (preg_match('#(^|/)admin/lang/[^/]+\.inc$#', $rel)) {
        preg_match_all('/"codice"\s*:\s*"([A-Za-z0-9_]+)"/', file_get_contents($p), $m);
        foreach ($m[1] as $c) $defined[strtoupper($c)] = 1;
    }
    if (!preg_match('/\.(php|inc)$/', $rel)) continue;
    $src = file_get_contents($p);
    preg_match_all('/\bdefine\s*\(\s*[\'"]\\\\?([A-Za-z0-9_\\\\]+)[\'"]/i', $src, $m);
    foreach ($m[1] as $c) $defined[strtoupper(basename(str_replace('\\', '/', $c)))] = 1;
    preg_match_all('/\bconst\s+([A-Za-z0-9_]+)\s*=/', $src, $m);
    foreach ($m[1] as $c) $defined[strtoupper($c)] = 1;
    if (!preg_match($skip, $rel)) $scan[$rel] = $src;
}
$builtin = array_change_key_case(get_defined_constants(), CASE_UPPER);
$kw = ['TRUE', 'FALSE', 'NULL', 'SELF', 'PARENT', 'STATIC', '__CLASS__', '__DIR__', '__FILE__', '__LINE__', '__FUNCTION__', '__METHOD__', '__NAMESPACE__'];
$out = [];
foreach ($scan as $rel => $src) {
    $t = @token_get_all($src);
    $n = count($t);
    for ($i = 0; $i < $n; $i++) {
        if (!is_array($t[$i]) || $t[$i][0] !== T_STRING) continue;
        $name = $t[$i][1];
        if (!preg_match('/^[A-Z][A-Z0-9_]+$/', $name)) continue;
        $u = strtoupper($name);
        if (isset($defined[$u]) || isset($builtin[$u]) || in_array($u, $kw) || isset($ignore["$rel $name"])) continue;
        $j = $i + 1; while ($j < $n && is_array($t[$j]) && $t[$j][0] === T_WHITESPACE) $j++;
        if ($j < $n && in_array($t[$j], ['(', ':'], true)) continue;                                        // funzione o etichetta
        if ($j < $n && is_array($t[$j]) && in_array($t[$j][0], [T_DOUBLE_COLON, T_VARIABLE, T_STRING])) continue; // Classe:: o tipo
        $b = $i - 1; while ($b >= 0 && is_array($t[$b]) && $t[$b][0] === T_WHITESPACE) $b--;
        if ($b >= 0 && is_array($t[$b]) && in_array($t[$b][0], [T_OBJECT_OPERATOR, T_DOUBLE_COLON, T_NEW, T_FUNCTION, T_CONST, T_CLASS,
            T_INTERFACE, T_TRAIT, T_EXTENDS, T_IMPLEMENTS, T_USE, T_NAMESPACE, T_INSTANCEOF, T_GOTO, T_NS_SEPARATOR])) continue;
        // protetta da defined('NOME') poco prima (es. `defined('X') ? X : ''`)
        if (preg_match('/defined\s*\(\s*[\'"]' . preg_quote($name, '/') . '[\'"]\s*\)/', implode('', array_map(fn($x) => is_array($x) ? $x[1] : $x, array_slice($t, max(0, $i - 40), 40))))) continue;
        $out[] = sprintf("%s:%d %s", $rel, $t[$i][2], $name);
    }
}
$out = array_values(array_unique($out));
sort($out);
echo $out ? implode("\n", $out) . "\n" : '';
exit($out ? 1 : 0);
