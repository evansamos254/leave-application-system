<?php

/**
 * PostgreSQL-backed session handler.
 * Required on Vercel (stateless serverless) where the default file-based
 * PHP sessions are not shared across Lambda invocations.
 */
class SessionHandler implements SessionHandlerInterface
{
    private ?PDO $pdo = null;

    private function db(): PDO
    {
        if ($this->pdo === null) {
            $config = require dirname(__DIR__, 2) . '/config/database.php';
            $dsn = sprintf(
                'pgsql:host=%s;dbname=%s;port=%s',
                $config['host'],
                $config['database'],
                $config['port'] ?? '5432'
            );
            $this->pdo = new PDO($dsn, $config['username'], $config['password'], [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);
        }

        return $this->pdo;
    }

    public function open(string $savePath, string $sessionName): bool
    {
        return true;
    }

    public function close(): bool
    {
        return true;
    }

    public function read(string $id): string|false
    {
        try {
            $stmt = $this->db()->prepare('SELECT data FROM sessions WHERE id = ?');
            $stmt->execute([$id]);
            $row = $stmt->fetch();

            return $row ? (string) $row['data'] : '';
        } catch (\Throwable $e) {
            error_log('Session read error: ' . $e->getMessage());

            return '';
        }
    }

    public function write(string $id, string $data): bool
    {
        try {
            $stmt = $this->db()->prepare(
                'INSERT INTO sessions (id, data, last_activity)
                 VALUES (?, ?, NOW())
                 ON CONFLICT (id) DO UPDATE SET data = EXCLUDED.data, last_activity = NOW()'
            );
            $stmt->execute([$id, $data]);

            return true;
        } catch (\Throwable $e) {
            error_log('Session write error: ' . $e->getMessage());

            return false;
        }
    }

    public function destroy(string $id): bool
    {
        try {
            $stmt = $this->db()->prepare('DELETE FROM sessions WHERE id = ?');
            $stmt->execute([$id]);

            return true;
        } catch (\Throwable $e) {
            error_log('Session destroy error: ' . $e->getMessage());

            return false;
        }
    }

    public function gc(int $maxLifetime): int|false
    {
        try {
            $cutoff = date('Y-m-d H:i:s', time() - $maxLifetime);
            $stmt = $this->db()->prepare('DELETE FROM sessions WHERE last_activity < ?');
            $stmt->execute([$cutoff]);

            return $stmt->rowCount();
        } catch (\Throwable $e) {
            error_log('Session gc error: ' . $e->getMessage());

            return false;
        }
    }
}
