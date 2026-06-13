<?php

// Session pooler is preferred for Vercel serverless (supports prepared statements,
// more reliable than direct IPv6 connection on cold-start Lambda).
return [
    'host'     => getenv('DB_HOST') ?: 'aws-0-eu-west-1.pooler.supabase.com',
    'database' => getenv('DB_NAME') ?: 'postgres',
    'username' => getenv('DB_USER') ?: 'postgres.sodjosasxtgqbbilecva',
    'password' => getenv('DB_PASSWORD') ?: 'tAFTKLL5SxGo0z2w',
    'port'     => getenv('DB_PORT') ?: '5432',
];
