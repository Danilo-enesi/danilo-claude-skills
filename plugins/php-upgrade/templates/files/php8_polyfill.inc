<?php
// Funzioni rimosse in PHP 8 e ancora usate dal core Master 7 / phplib.
// Con PHP 7.x le funzioni native esistono e queste definizioni vengono saltate.

if (!function_exists('get_magic_quotes_gpc')) {
    function get_magic_quotes_gpc() {
        return false;
    }
}

if (!function_exists('each')) {
    function each(&$array) {
        if (!is_array($array)) {
            return null;
        }
        $key = key($array);
        if ($key === null) {
            return false;
        }
        $value = current($array);
        next($array);
        return array(1 => $value, 'value' => $value, 0 => $key, 'key' => $key);
    }
}
