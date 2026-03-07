n<?php
/**
 * server_register_demo.php
 * ─────────────────────────────────────────────────────────────
 * Kanasa VPN — Server Auto-Registration Endpoint
 *
 * Accepts a JSON POST from the VPS installer and saves the
 * server record into the `vpn_servers` table.
 *
 * Deploy this file to: https://admin.kanasavpn.com/server_register_demo.php
 *
 * Expected JSON body:
 * {
 *   "server_key":  "usa-st-louis",
 *   "country":     "United States",
 *   "city":        "St Louis",
 *   "endpoint":    "1.2.3.4",
 *   "agent_url":   "http://1.2.3.4:7932",
 *   "public_key":  "<wireguard-base64-key>",
 *   "listen_port": 7932
 * }
 *
 * Response (JSON):
 *   200 OK  → { "status": "ok",    "message": "...", "action": "inserted|updated" }
 *   400     → { "status": "error", "message": "..." }
 *   500     → { "status": "error", "message": "..." }
 * ─────────────────────────────────────────────────────────────
 */

header('Content-Type: application/json; charset=utf-8');

// ─── Database credentials ────────────────────────────────────
// TODO: Move these to environment variables or a config file
define('DB_HOST', 'localhost');
define('DB_NAME', 'kanasa_admin');       // ← your database name
define('DB_USER', 'kanasa_user');        // ← your db username
define('DB_PASS', 'YOUR_DB_PASSWORD');  // ← your db password
define('DB_CHARSET', 'utf8mb4');

// ─── Optional: shared secret for basic auth ──────────────────
// Set this env var on the server to require X-Kanasa-Token header
// Leave empty to disable token check (not recommended in production)
define('REGISTER_SECRET', getenv('KANASA_REGISTER_SECRET') ?: '');

// ─────────────────────────────────────────────────────────────
// Only accept POST
// ─────────────────────────────────────────────────────────────
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['status' => 'error', 'message' => 'Method not allowed. Use POST.']);
    exit;
}

// ─────────────────────────────────────────────────────────────
// Optional token check
// ─────────────────────────────────────────────────────────────
if (!empty(REGISTER_SECRET)) {
    $token = $_SERVER['HTTP_X_KANASA_TOKEN'] ?? '';
    if (!hash_equals(REGISTER_SECRET, $token)) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Forbidden — invalid token.']);
        exit;
    }
}

// ─────────────────────────────────────────────────────────────
// Read & decode JSON body
// ─────────────────────────────────────────────────────────────
$raw = file_get_contents('php://input');
if (empty($raw)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Empty request body.']);
    exit;
}

$data = json_decode($raw, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'Invalid JSON: ' . json_last_error_msg()]);
    exit;
}

// ─────────────────────────────────────────────────────────────
// Validate required fields
// ─────────────────────────────────────────────────────────────
$required = ['server_key', 'country', 'city', 'endpoint', 'agent_url', 'public_key', 'listen_port'];
foreach ($required as $field) {
    if (empty($data[$field]) && $data[$field] !== 0) {
        http_response_code(400);
        echo json_encode(['status' => 'error', 'message' => "Missing required field: $field"]);
        exit;
    }
}

$server_key  = trim((string) $data['server_key']);
$country     = trim((string) $data['country']);
$city        = trim((string) $data['city']);
$endpoint    = trim((string) $data['endpoint']);
$agent_url   = trim((string) $data['agent_url']);
$public_key  = trim((string) $data['public_key']);
$listen_port = (int) $data['listen_port'];

// Basic sanity checks
if ($listen_port < 1 || $listen_port > 65535) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'listen_port must be between 1 and 65535.']);
    exit;
}

if (!filter_var($endpoint, FILTER_VALIDATE_IP)) {
    http_response_code(400);
    echo json_encode(['status' => 'error', 'message' => 'endpoint must be a valid IP address.']);
    exit;
}

// ─────────────────────────────────────────────────────────────
// Connect to database
// ─────────────────────────────────────────────────────────────
try {
    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=%s', DB_HOST, DB_NAME, DB_CHARSET);
    $pdo = new PDO($dsn, DB_USER, DB_PASS, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed.']);
    // Log internally — never expose DB errors to the installer
    error_log('[kanasa] DB connect error: ' . $e->getMessage());
    exit;
}

// ─────────────────────────────────────────────────────────────
// Create table if not exists
// (safe to run on every call — IF NOT EXISTS is idempotent)
// ─────────────────────────────────────────────────────────────
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS `vpn_servers` (
            `id`           INT UNSIGNED     NOT NULL AUTO_INCREMENT,
            `server_key`   VARCHAR(100)     NOT NULL,
            `country`      VARCHAR(100)     NOT NULL DEFAULT '',
            `city`         VARCHAR(100)     NOT NULL DEFAULT '',
            `endpoint`     VARCHAR(45)      NOT NULL,
            `agent_url`    VARCHAR(255)     NOT NULL DEFAULT '',
            `public_key`   VARCHAR(255)     NOT NULL DEFAULT '',
            `listen_port`  SMALLINT UNSIGNED NOT NULL DEFAULT 9000,
            `registered_at` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at`   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uq_server_key` (`server_key`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to prepare database table.']);
    error_log('[kanasa] CREATE TABLE error: ' . $e->getMessage());
    exit;
}

// ─────────────────────────────────────────────────────────────
// INSERT or UPDATE (upsert by server_key)
// ─────────────────────────────────────────────────────────────
try {
    $sql = "
        INSERT INTO `vpn_servers`
            (`server_key`, `country`, `city`, `endpoint`, `agent_url`, `public_key`, `listen_port`)
        VALUES
            (:server_key, :country, :city, :endpoint, :agent_url, :public_key, :listen_port)
        ON DUPLICATE KEY UPDATE
            `country`     = VALUES(`country`),
            `city`        = VALUES(`city`),
            `endpoint`    = VALUES(`endpoint`),
            `agent_url`   = VALUES(`agent_url`),
            `public_key`  = VALUES(`public_key`),
            `listen_port` = VALUES(`listen_port`),
            `updated_at`  = NOW()
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        ':server_key'  => $server_key,
        ':country'     => $country,
        ':city'        => $city,
        ':endpoint'    => $endpoint,
        ':agent_url'   => $agent_url,
        ':public_key'  => $public_key,
        ':listen_port' => $listen_port,
    ]);

    // rowCount() == 1 → inserted, 2 → updated (MySQL counts both rows for ON DUPLICATE KEY)
    $action = ($stmt->rowCount() === 1) ? 'inserted' : 'updated';

    http_response_code(200);
    echo json_encode([
        'status'  => 'ok',
        'message' => "Server '$server_key' $action successfully.",
        'action'  => $action,
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Failed to save server record.']);
    error_log('[kanasa] INSERT error: ' . $e->getMessage());
    exit;
}

