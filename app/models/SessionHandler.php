<?php

/**
 * PostgreSQL-backed session handler using the shared database connection.
 * Stores sessions in the `sessions` table so they survive across
 * Vercel Lambda invocations (stateless serverless environment).
 */
class DatabaseSessionHandler implements SessionHandlerInterface
{
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
            $stmt = Database::connection()->prepare(
                'SELECT data FROM sessions WHERE id = ?'
            );
            $stmt->execute([$id]);
            $row = $stmt->fetch();

            return $row ? (string) $row['data'] : '';
        } catch (\Throwable $e) {
            error_log('[session.read] ' . $e->getMessage());

            return '';
        }
    }

    public function write(string $id, string $data): bool
    {
        try {
            $stmt = Database::connection()->prepare(
                'INSERT INTO sessions (id, data, last_activity)
                 VALUES (?, ?, NOW())
                 ON CONFLICT (id) DO UPDATE
                   SET data = EXCLUDED.data,
                       last_activity = NOW()'
            );
            $stmt->execute([$id, $data]);
        } catch (\Throwable $e) {
            error_log('[session.write] ' . $e->getMessage());
        }

        // Always return true — returning false triggers an uncatchable PHP warning.
        // If the write failed the user will simply re-authenticate on next request.
        return true;
    }

    public function destroy(string $id): bool
    {
        try {
            $stmt = Database::connection()->prepare(
                'DELETE FROM sessions WHERE id = ?'
            );
            $stmt->execute([$id]);
        } catch (\Throwable $e) {
            error_log('[session.destroy] ' . $e->getMessage());
        }

        return true;
    }

    public function gc(int $maxLifetime): int|false
    {
        try {
            $cutoff = date('Y-m-d H:i:s', time() - $maxLifetime);
            $stmt = Database::connection()->prepare(
                'DELETE FROM sessions WHERE last_activity < ?'
            );
            $stmt->execute([$cutoff]);

            return $stmt->rowCount();
        } catch (\Throwable $e) {
            error_log('[session.gc] ' . $e->getMessage());

            return 0;
        }
    }
}
