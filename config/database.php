<?php

return [
    'host'     => getenv('DB_HOST') ?: 'db.sodjosasxtgqbbilecva.supabase.co',
    'database' => getenv('DB_NAME') ?: 'postgres',
    'username' => getenv('DB_USER') ?: 'postgres',
    'password' => getenv('DB_PASSWORD') ?: '',
    'port'     => getenv('DB_PORT') ?: '5432',
];
