<?php
// Funzioni per i controlli statici del progetto (_migration/checks.php). Il progetto definisce
//   $checks = ['ID' => ['descrizione', fn() => bool], ...];
// e chiude con run_checks($checks). Si esegue sempre con -d short_open_tag=1 (run-tests.sh lo fa):
// con Off il tokenizer vede il codice dopo `<?` come HTML e i controlli sui metodi danno falsi FAIL.

$root = getenv('MIG_ROOT') ?: trim((string) shell_exec('git rev-parse --show-toplevel'));
$php = PHP_BINARY;

function src($f) { global $root; $p = "$root/$f"; return is_file($p) ? file_get_contents($p) : null; }
function lints($path) { global $php, $root; exec(escapeshellarg($php) . ' -n -l ' . escapeshellarg("$root/$path") . ' 2>&1', $o, $rc); return $rc === 0; }
function lintDir($dir, $skip = '#/(examples|tools|test|tests|docs)/#') {
    global $root;
    if (!is_dir("$root/$dir")) return false;
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$root/$dir", FilesystemIterator::SKIP_DOTS));
    foreach ($it as $f) {
        $rel = substr(str_replace('\\', '/', $f->getPathname()), strlen($root) + 1);
        if (preg_match('/\.(php|inc)$/', $rel) && !preg_match($skip, $rel) && !lints($rel)) return false;
    }
    return true;
}
// $a compare prima di $b nel testo
function before($text, $a, $b) { if ($text === null) return false; $pa = strpos($text, $a); $pb = strpos($text, $b); return $pa !== false && $pb !== false && $pa < $pb; }
// [nome metodo minuscolo => è static] della classe $class nel file
function methods($file, $class) {
    $code = src($file); if ($code === null) return [];
    $t = token_get_all($code); $in = false; $depth = 0; $out = [];
    foreach ($t as $i => $tok) {
        if (is_array($tok) && $tok[0] === T_CLASS) {
            for ($j = $i + 1; is_array($t[$j]) && $t[$j][0] === T_WHITESPACE; $j++);
            $in = is_array($t[$j]) && strcasecmp($t[$j][1], $class) === 0; $depth = 0; continue;
        }
        if (!$in) continue;
        if ($tok === '{' || (is_array($tok) && in_array($tok[0], [T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES]))) $depth++;
        if ($tok === '}' && --$depth === 0) $in = false;
        if ($depth === 1 && is_array($tok) && $tok[0] === T_FUNCTION) {
            for ($j = $i + 1; is_array($t[$j]) && $t[$j][0] === T_WHITESPACE; $j++);
            $static = false;
            for ($k = $i - 1; $k > 0 && is_array($t[$k]) && in_array($t[$k][0], [T_WHITESPACE, T_STATIC, T_PUBLIC, T_PROTECTED, T_PRIVATE, T_FINAL, T_ABSTRACT]); $k--)
                if ($t[$k][0] === T_STATIC) $static = true;
            $out[strtolower($t[$j][1])] = $static;
        }
    }
    return $out;
}
// costruttore moderno presente e niente costruttore PHP4 con il nome della classe
function hasConstruct($file, $class) { $m = methods($file, $class); return isset($m['__construct']) && !isset($m[strtolower($class)]); }
// prima versione trovata nei file .php di una libreria
function version($dir, $re) {
    global $root;
    if (!is_dir("$root/$dir")) return '0';
    foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator("$root/$dir", FilesystemIterator::SKIP_DOTS)) as $f)
        if (preg_match('/\.php$/', $f) && preg_match($re, file_get_contents($f), $m)) return $m[1];
    return '0';
}
// esegue codice PHP in un processo separato (-n) da un file temporaneo; true se esce con 0
function runsOk($code) {
    global $php;
    // file temporaneo: su Windows escapeshellarg() altera le virgolette di un codice passato con -r
    $tmp = tempnam(sys_get_temp_dir(), 'mig') . '.php';
    file_put_contents($tmp, "<?php $code");
    exec(escapeshellarg($php) . ' -n ' . escapeshellarg($tmp) . ' 2>&1', $o, $rc);
    unlink($tmp);
    return $rc === 0;
}
// polyfill each()/get_magic_quotes_gpc() funzionante (template Master 7)
function polyfillWorks($file) {
    global $root;
    if (!is_file("$root/$file")) return false;
    return runsOk('require ' . var_export("$root/$file", true) . ';'
        . '$a = ["x" => 1, "y" => 2]; $r = each($a); $r2 = each($a); $r3 = each($a);'
        . 'exit((get_magic_quotes_gpc() === false && $r === [1 => 1, "value" => 1, 0 => "x", "key" => "x"]'
        . ' && $r2["key"] === "y" && $r3 === false && @each($n) === null) ? 0 : 1);');
}

function run_checks(array $checks) {
    global $argv;
    $only = array_slice($argv, 1);
    $failed = 0;
    foreach ($checks as $id => [$label, $fn]) {
        if ($only && !in_array($id, $only, true)) continue;
        $ok = (bool) $fn();
        $failed += $ok ? 0 : 1;
        printf("%-4s %s  %s\n", $id, $ok ? 'PASS' : 'FAIL', $label);
    }
    exit($failed ? 1 : 0);
}
