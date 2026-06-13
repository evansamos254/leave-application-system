<?php

declare(strict_types=1);

// Signal to the app that we are running on Vercel (serverless)
putenv('VERCEL=1');

require dirname(__DIR__) . '/app/bootstrap.php';
require dirname(__DIR__) . '/routes/web.php';
