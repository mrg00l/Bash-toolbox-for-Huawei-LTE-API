<?php

$chat_id = "-0000000000000";
$bot_token = "000000000:0000000000000000000000";
// Connect to your MySQL antispam database
$servername = "localhost";
$username = "root";
$password = "mypass";
$dbname = "antispam";
$log_file = '/path_to/script_log.txt';
//------------------------------

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    file_put_contents($log_file, "Connection failed: " . $conn->connect_error . PHP_EOL, FILE_APPEND);
    die("Connection failed: " . $conn->connect_error);
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    if (empty($_POST['device']) || empty($_POST['country']) || empty($_POST['version'])) {
        http_response_code(400);
        echo "Missing parameters";
        exit;
    }

    $device = isset($_POST['device']) ? substr($_POST['device'], 0, 30) : '';
    $loginstd = isset($_POST['login-std']) ? substr($_POST['login-std'], 0, 1) : '';
    $loginscram = isset($_POST['login-scram']) ? substr($_POST['login-scram'], 0, 1) : '';
    $version = isset($_POST['version']) ? substr($_POST['version'], 0, 5) : '';
    $smssend = isset($_POST['sms-send']) ? substr($_POST['sms-send'], 0, 5) : '';
    $country = isset($_POST['country']) ? substr($_POST['country'], 0, 3) : '';
    $message = "Hello from $country! $device, login-std: $loginstd, login-scram: $loginscram, sms-send: $smssend, functions.bash version: $version";

    // ------------- Antispam ------------------
    $ip = $_SERVER['REMOTE_ADDR'];
    $timestamp = time();
    $twenty_four_hours_ago = $timestamp - (24 * 3600);
    $one_minute_ago = $timestamp - 60;
    $md5_hash = md5($message);

    // Delete records older than 24 hours
    $sql_delete = "DELETE FROM connectionlog WHERE TIMESTAMP < $twenty_four_hours_ago";

    if ($conn->query($sql_delete) === TRUE) {
        file_put_contents($log_file, "Records older than 24 hours deleted successfully" . PHP_EOL, FILE_APPEND);
    } else {
        file_put_contents($log_file, "Error deleting records: " . $conn->error . PHP_EOL, FILE_APPEND);
    }

    // Check if a record with the same IP address and timestamp less than 1 minute ago exists
    $sql_check = "SELECT * FROM connectionlog WHERE IP = '$ip' AND TIMESTAMP > $one_minute_ago";

    $result = $conn->query($sql_check);

    if ($result->num_rows > 0) {
        file_put_contents($log_file, "Record with the same IP address and timestamp less than 1 minute ago already exists." . PHP_EOL, FILE_APPEND);
        exit("Record with the same IP address and timestamp less than 1 minute ago already exists.");
    }

    // Check if a record with the same MD5 hash already exists
    $sql_check = "SELECT * FROM connectionlog WHERE MD5 = '$md5_hash'";

    $result = $conn->query($sql_check);

    if ($result->num_rows > 0) {
        file_put_contents($log_file, "Record already exists." . PHP_EOL, FILE_APPEND);
        exit("Record already exists.");
    }

  // Insert data into database
    $sql = "INSERT INTO connectionlog (IP, MD5, TIMESTAMP)
            VALUES ('$ip', '$md5_hash', '$timestamp')";

    if ($conn->query($sql) === TRUE) {
        file_put_contents($log_file, "New record created successfully" . PHP_EOL, FILE_APPEND);
    } else {
        file_put_contents($log_file, "Error inserting record: " . $conn->error . PHP_EOL, FILE_APPEND);
    }

    // Close connection
    $conn->close();


    // -------- End antispam -------------

    // Send message to Telegram
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, "https://api.telegram.org/bot$bot_token/sendMessage");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'chat_id' => $chat_id,
        'text' => $message,
        'disable_notification' => true
    ]));

    // Execute cURL request
    $response = curl_exec($ch);

    if (curl_errno($ch)) {
        http_response_code(500);
        echo 'cURL Error: ' . curl_error($ch);
        exit;
    } else {
        echo "OK";
    }

    curl_close($ch);
} else {
?>
    <!DOCTYPE html>
    <html>
    <head>
        <title>Submit Form</title>
    </head>
    <body>
    <form method="POST" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]); ?>">
        <label for="country">Country:</label><br>
        <input type="text" id="country" name="country" maxlength="3" required><br>
        <label for="device">Device:</label><br>
        <input type="text" id="device" name="device" maxlength="30" required><br>
        <input type="checkbox" id="login-std" name="login-std" value="1">
        <label for="login-std">Login Standard</label><br>
        <input type="checkbox" id="login-scram" name="login-scram" value="1">
        <label for="login-scram">Login Scram</label><br>
        <input type="checkbox" id="sms-send" name="sms-send" value="1">
        <label for="sms-send">SMS Send</label><br>
        <label for="version">functions.bash version:</label><br>
        <input type="text" id="version" name="version" maxlength="5" required><br>
        <input type="submit" value="Submit">
    </form>
    </body>
    </html>
    <?php
}
?>
