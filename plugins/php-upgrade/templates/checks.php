<?php
// Controlli statici del progetto, uno per ogni punto di SPEC.md (id = SPEC). Li esegue run-tests.sh --static.
// Prima di migrare devono FALLIRE tutti (run-tests.sh --static --expect-red); dopo, PASS.
require getenv('MIG_PLUGIN') . '/lib/checks-lib.php';

$mk = methods('admin/include/class/class.makeform.php', 'MakeForm');
$checks = [
    // core Master 7 (vedi patches.php)
    'C1' => ['function.inc compila (niente $str{})', fn() => lints('admin/include/function.inc')],
    'C2' => ['polyfill each()/get_magic_quotes_gpc() presente e corretto', fn() => polyfillWorks('admin/include/php8_polyfill.inc')],
    'C3' => ['register_globals.inc carica il polyfill prima di usarlo', fn() => before(src('admin/include/register_globals.inc'), 'php8_polyfill.inc', 'get_magic_quotes_gpc()')],
    'C4' => ['function.inc carica il polyfill (each() per session.inc)', fn() => strpos((string) src('admin/include/function.inc'), 'php8_polyfill.inc') !== false],
    'C5' => ['db_mysqli.inc disattiva le eccezioni mysqli prima di connettersi', fn() => before(src('admin/lib/phplib/db_mysqli.inc'), 'mysqli_report(MYSQLI_REPORT_OFF)', 'new mysqli(')],
    'C6' => ['MakeForm::getThumbCampoImmagine è static', fn() => !empty($mk['getthumbcampoimmagine'])],

    // librerie (una per riga di libs.lock): versione minima + compila
    // 'L1' => ['tcpdf >= 6 e compila', fn() => version_compare(version('admin/include/class/tcpdf', "/tcpdf_version\s*=\s*'([\d.]+)'/"), '6.0', '>=') && lintDir('admin/include/class/tcpdf')],
    // 'L2' => ['FPDI >= 2.6', fn() => version_compare(version('admin/include/class/fpdi', "/VERSION\s*=\s*'([\d.]+)'/"), '2.6', '>=')],
    // 'L3' => ['PHPMailer >= 6 con shim', fn() => version_compare(version('admin/include/class/phpmailer/src', "/VERSION\s*=\s*'([\d.]+)'/"), '6.0', '>=') && strpos((string) src('admin/include/class/phpmailer/class.phpmailer.php'), 'class_alias') !== false],

    // progetto (esempio)
    // 'P1' => ['Template ha __construct', fn() => hasConstruct('admin/template/include/class.template.php', 'Template')],
];
run_checks($checks);
