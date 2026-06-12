<?php

declare(strict_types=1);

$config = require dirname(__DIR__) . '/config/app.php';
date_default_timezone_set($config['timezone'] ?? 'UTC');

spl_autoload_register(function (string $class): void {
    $phpMailerPrefix = 'PHPMailer\\PHPMailer\\';
    if (str_starts_with($class, $phpMailerPrefix)) {
        $file = dirname(__DIR__) . '/vendor/phpmailer/src/' . substr($class, strlen($phpMailerPrefix)) . '.php';
        if (is_file($file)) {
            require $file;
        }
        return;
    }

    $directories = [
        dirname(__DIR__) . '/app/models',
        dirname(__DIR__) . '/app/services',
        dirname(__DIR__) . '/app/controllers',
        dirname(__DIR__) . '/app/middleware',
    ];

    foreach ($directories as $directory) {
        $file = $directory . '/' . $class . '.php';
        if (is_file($file)) {
            require $file;
            return;
        }
    }
});

require dirname(__DIR__) . '/app/helpers.php';

// Use PostgreSQL-backed sessions so they survive across Vercel Lambda invocations.
// SessionHandler must be registered BEFORE session_start().
require_once dirname(__DIR__) . '/app/models/SessionHandler.php';
$sessionHandler = new DatabaseSessionHandler();
session_set_save_handler($sessionHandler, true);

session_start();
