<?php
// Shim di compatibilità (file nostro, non della libreria): il codice del sito include questo file
// e usa `new PHPMailer` come con la 5.2; la libreria vera è PHPMailer 6 in src/.
require_once __DIR__ . '/src/Exception.php';
require_once __DIR__ . '/src/PHPMailer.php';
require_once __DIR__ . '/src/SMTP.php';

class_alias('PHPMailer\PHPMailer\PHPMailer', 'PHPMailer');
class_alias('PHPMailer\PHPMailer\SMTP', 'SMTP');
class_alias('PHPMailer\PHPMailer\Exception', 'phpmailerException');
