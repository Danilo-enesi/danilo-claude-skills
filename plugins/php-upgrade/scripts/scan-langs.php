<?php
// A3: tutte le lingue del front hanno le stesse voci (front/app/settings/lang/<sito>/language_<lingua>.inc).
// Il front carica UN solo file di lingua: una voce assente in eng è un Error in PHP 8 se usata come costante,
// e un testo vuoto se letta con $app->language->get(). Le voci si aggiungono in Admin › Linguaggi (o con --sql).
// Uso: php scan-langs.php            elenco "sito lingua CODICE (valore nell'altra lingua)", exit 1 se manca qualcosa
//      php scan-langs.php --sql      SQL idempotente per le tabelle Master (linguaggio, linguaggio_valori_text_lang)
//                                    con il valore dell'altra lingua come segnaposto da tradurre: poi «Aggiorna i linguaggi»
$root = rtrim(str_replace('\\', '/', getenv('MIG_ROOT') ?: getcwd()), '/');
$sql = in_array('--sql', $argv, true);
$missing = [];
foreach (glob("$root/front/app/settings/lang/*", GLOB_ONLYDIR) ?: [] as $dir) {
    $site = basename($dir);
    $vals = [];   // lingua => [CODICE => valore]
    foreach (glob("$dir/language_*.inc") as $f) {
        if (!preg_match('/language_([a-z]+)\.inc$/', $f, $m)) continue;
        preg_match_all("/^define\\('([A-Za-z0-9_]+)',\\s*'((?:\\\\.|[^'\\\\])*)'\\);/m", file_get_contents($f), $d, PREG_SET_ORDER);
        foreach ($d as $x) $vals[$m[1]][$x[1]] = stripslashes($x[2]);
    }
    $all = array_unique(array_merge(...array_map('array_keys', array_values($vals) ?: [[]])));
    sort($all);
    foreach ($all as $k) foreach ($vals as $l => $set) {
        if (isset($set[$k])) continue;
        $from = current(array_filter(array_map(fn($s) => $s[$k] ?? null, $vals)));
        $missing[] = [$site, $l, $k, (string) $from];
    }
}
if ($sql) {
    $rows = [];
    foreach ($missing as [$site, $l, $k, $v]) $rows[] = sprintf("  SELECT %s s, %s c, %s l, %s v", ...array_map(fn($x) => "'" . addslashes($x) . "'", [$site, $k, $l, $v]));
    if (!$rows) { echo "-- nessuna voce mancante\n"; exit(0); }
    echo "-- Voci mancanti nel front: il valore è quello di un'altra lingua, TRADURLO prima di eseguire. Poi Admin › Linguaggi › «Aggiorna i linguaggi».\n";
    echo "SET NAMES utf8;\nINSERT INTO linguaggio_valori_text_lang (id, id_linguaggio, campo_nome, lang, campo_valore)\n";
    echo "SELECT MD5(CONCAT(UUID(), g.id_linguaggio)), g.id_linguaggio, 'testo', t.l, t.v\nFROM linguaggio g\nJOIN (\n" . implode(" UNION ALL\n", $rows) . "\n) t ON t.c = g.codice AND t.s = g.id_website\n";
    echo "WHERE NOT EXISTS (SELECT 1 FROM linguaggio_valori_text_lang x WHERE x.id_linguaggio = g.id_linguaggio AND x.campo_nome = 'testo' AND x.lang = t.l);\nSELECT ROW_COUNT() AS righe_inserite;\n";
    exit(0);
}
// niente mbstring: deve girare anche con un PHP CLI senza estensioni
foreach ($missing as [$site, $l, $k, $v]) printf("%s %s %s  (altra lingua: %s)\n", $site, $l, $k, strlen($v) > 60 ? preg_replace('/^(.{0,57}).*$/us', '$1...', $v) : $v);
exit($missing ? 1 : 0);
