<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $username = $_POST["username"] ?? "";
    $wordlist = $_FILES["wordlist"] ?? null;
    $correct_password = "ahmed";
    $found_password = null;
    
    if (!$username) {
        echo json_encode(["error" => "Username is required"]);
        exit;
    }
    
    if ($wordlist && $wordlist["error"] == UPLOAD_ERR_OK) {
        $file = fopen($wordlist["tmp_name"], "r");
        if ($file) {
            while (($word = fgets($file)) !== false) {
                $word = trim($word);
                if ($word === $correct_password) {
                    $found_password = $word;
                    break;
                }
            }
            fclose($file);
        }
    }
    
    if ($found_password) {
        echo json_encode(["message" => "Password cracked via dictionary attack!", "password" => $found_password]);
        exit;
    }
    
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
    $charsArray = str_split($chars);
    
    function generateCombinations($prefix, $length, $correct_password, $charsArray) {
        if (strlen($prefix) == $length) {
            if ($prefix === $correct_password) {
                echo json_encode(["message" => "Password cracked via brute force attack!", "password" => $prefix]);
                exit;
            }
            return;
        }
        foreach ($charsArray as $char) {
            generateCombinations($prefix . $char, $length, $correct_password, $charsArray);
        }
    }
    
    generateCombinations("", 5, $correct_password, $charsArray);
    
    echo json_encode(["message" => "Password could not be cracked"]);
    exit;
}
?>
