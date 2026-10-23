<?php
// Rigenera i file di lingua del front dal DB LOCALE come «Aggiorna i linguaggi» (admin/linguaggio/linguaggio_generator.php),
// da CLI e senza sessione dell'admin. Stesso SQL e stesso formato: dopo, git diff mostra solo le voci cambiate.
// Uso (da lang.sh, che passa DB e radice): php lang-regen.php <id_website>
$root = rtrim(str_replace('\\', '/', getenv('MIG_ROOT') ?: getcwd()), '/');
$site = $argv[1] ?? '';
if (!preg_match('/^[a-f0-9]{32}$/', $site)) { fwrite(STDERR, "ERRORE: id_website non valido (nome della cartella in front/app/settings/lang/)\n"); exit(1); }
$db = new mysqli(getenv('DB_HOST') ?: '127.0.0.1', getenv('DB_USER') ?: 'root', getenv('MYSQL_PWD') ?: '', getenv('DB_NAME'), (int) (getenv('DB_PORT') ?: 3306));
$db->set_charset('utf8');
$res = $db->query("SELECT linguaggio.id_website, linguaggio.codice, lingue.lingua, valore.campo_valore
    FROM lingue
    LEFT JOIN linguaggio_valori_text_lang valore ON valore.lang = lingue.lingua AND valore.campo_nome = 'testo'
    LEFT JOIN linguaggio ON linguaggio.id_linguaggio = valore.id_linguaggio AND linguaggio.id_website = '$site'
    WHERE linguaggio.codice != ''
    ORDER BY linguaggio.codice ASC, lingue.lingua ASC, valore.campo_valore ASC");
$lang = []; $pad = 0;
while ($r = $res->fetch_assoc()) {
    $pad = max($pad, strlen($r['codice']));
    $lang[$r['lingua']][] = ['codice' => $r['codice'], 'valore' => $r['campo_valore']];
}
$dir = "$root/front/app/settings/lang/$site";
if (!is_dir($dir)) { fwrite(STDERR, "ERRORE: manca $dir\n"); exit(1); }
foreach ($lang as $l => $voci) {
    $fd = fopen("$dir/language_$l.inc", 'wb');
    fwrite($fd, "<?php\r\n\r\n");
    $js = [];
    foreach ($voci as $v) {
        fwrite($fd, 'define(' . str_pad("'{$v['codice']}',", $pad + 3) . " '" . addslashes(stripslashes($v['valore'])) . "');\r\n");
        $js[$v['codice']] = $v['valore'];
    }
    fclose($fd);
    file_put_contents("$dir/language_$l.js", 'var site_language = ' . json_encode($js));
    echo "$l: " . count($voci) . " voci\n";
}
