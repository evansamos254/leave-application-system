<?php

$mailOverrides = is_file(__DIR__ . '/mail.local.php')
    ? require __DIR__ . '/mail.local.php'
    : [];
$smtpOverrides = $mailOverrides['smtp'] ?? [];
unset($mailOverrides['smtp']);

// On Vercel the filesystem is read-only except /tmp. Use env var VERCEL to detect.
$onVercel = (bool) getenv('VERCEL');
$uploadBase = $onVercel ? '/tmp' : dirname(__DIR__) . '/uploads';

return [
    'name' => 'XEROMYND',
    'hro_confirmation_name' => '',
    'timezone' => 'Africa/Nairobi',
    'base_url' => getenv('APP_BASE_URL') ?: '',
    'upload_dir' => $uploadBase . '/leave-attachments',
    'max_upload_size' => 5 * 1024 * 1024,
    'allowed_upload_extensions' => ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    'profile_photo_dir' => $uploadBase . '/profile-photos',
    'profile_photo_max_size' => 10 * 1024 * 1024,
    'profile_photo_extensions' => ['jpg', 'jpeg', 'png', 'webp'],
    'employment_document_dir' => $uploadBase . '/employment-documents',
    'employment_document_max_size' => 10 * 1024 * 1024,
    'employment_document_extensions' => ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    'log_file' => $onVercel ? '/tmp/app.log' : dirname(__DIR__) . '/storage/logs/app.log',
    'notifications' => [
        'email' => [
            'enabled' => true,
            'transport' => 'smtp',
            'from' => 'evansamos702@gmail.com',
            'from_name' => 'XEROMYND',
            'smtp' => [
                'host' => 'smtp.gmail.com',
                'port' => 587,
                'encryption' => 'tls',
                'username' => 'evansamos702@gmail.com',
                'password' => getenv('LEAVE_SMTP_PASSWORD') ?: '',
                'timeout' => 15,
                ...$smtpOverrides,
            ],
            ...$mailOverrides,
        ],
        'sms' => [
            'enabled' => false,
            'gateway_url' => '',
            'api_key' => '',
            'sender' => 'XEROMYND',
        ],
    ],
];
