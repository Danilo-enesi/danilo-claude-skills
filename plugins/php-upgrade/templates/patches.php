<?php
// Correzioni minime approvate (una riga = un punto di SPEC.md), applicate da scripts/patch.php.
// [id, file, tipo, cerca, nuovo]  — tipo: replace | before | copy (da _migration/files/<cerca>)
// Le prime righe sono il CORE MASTER 7 (uguale in tutti i siti Master 7 / phplib): verificale con patch.php (dry-run),
// toglile se il sito non ha quei file. Sotto, le patch del progetto trovate nell'analisi.
return [
    // C1: accesso a stringa con graffe {} = parse error in PHP 8
    ['C1', 'admin/include/function.inc', 'replace', '$charAt = $base_directory{$len -1};', '$charAt = $base_directory[$len -1];'],
    ['C1', 'admin/include/function.inc', 'replace', '$charAt = $directory{0};', '$charAt = $directory[0];'],
    ['C1', 'admin/include/function.inc', 'replace', '$charAt = $directory{$len - 1};', '$charAt = $directory[$len - 1];'],
    // C2-C4: polyfill di each() e get_magic_quotes_gpc(), caricato prima del primo uso
    ['C2', 'admin/include/php8_polyfill.inc', 'copy', 'php8_polyfill.inc', null],
    ['C3', 'admin/include/register_globals.inc', 'replace', '<?php', "<?php require_once __DIR__ . '/php8_polyfill.inc';"],
    ['C4', 'admin/include/function.inc', 'before', 'if (!function_exists("ereg_replace")){', "require_once __DIR__ . '/php8_polyfill.inc';"],
    // C5: da PHP 8.1 mysqli lancia eccezioni; il core phplib controlla gli errori a mano
    ['C5', 'admin/lib/phplib/db_mysqli.inc', 'before', '$link = new mysqli($hostname, $username, $password);', 'mysqli_report(MYSQLI_REPORT_OFF); // PHP 8.1+: niente eccezioni, il core controlla gli errori a mano'],
    // C6: chiamata statica (adWidget/persWidget) a un metodo non statico = Error in PHP 8
    ['C6', 'admin/include/class/class.makeform.php', 'replace', '    function getThumbCampoImmagine($id_foto_thumb){', '    static function getThumbCampoImmagine($id_foto_thumb){'],

    // --- progetto (esempio: costruttore PHP4 di una classe istanziata) ---
    // ['P1', 'admin/template/include/class.template.php', 'replace', 'function Template($id_template, $lang_lista, $no_construct="N"){', 'function __construct($id_template, $lang_lista, $no_construct="N"){'],
];
