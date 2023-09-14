# Load the environment variables
$git_token = $env:token

$fileContent = Get-Content -Raw -Path json_data.json
Write-Host "fileContent: $fileContent"

# Convert the JSON content from base64 to a JSON object
$jsonObject = $fileContent | ConvertFrom-Json

# Specify the fields you want to encrypt
$fieldsToEncrypt = $env:fieldsToEncrypt -split ","
Write-Host "fieldsToEncrypt: $fieldsToEncrypt"

# Encryption key
$keyHex = $env:key  # Replace with your encryption key

# Create a new AES object with the specified key and AES mode
$AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
$AES.KeySize = 256  # Set the key size to 256 bits for AES-256
$AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
$AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# Loop through the specified fields and encrypt their values
foreach ($field in $fieldsToEncrypt) {
    Write-Host "Entered into FOREACH...!"

    # Find the item with the matching field name
    $item = $jsonObject.keyValueEntries | Where-Object { $_.name -eq $field }

    # Check if an item with the matching field name was found
    if ($item -ne $null) {
        $plaintext = $item.value
        Write-Host "plaintext: $plaintext"

        # Convert plaintext to bytes (UTF-8 encoding)
        $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

        # Generate a random initialization vector (IV)
        $AES.GenerateIV()
        $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

        # Encrypt the data
        $encryptor = $AES.CreateEncryptor()
        $encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)
        $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

        # Update the item with encrypted values
        $item.value = @{
            "EncryptedValue" = $encryptedBase64
            "IV" = $IVBase64
        }
    }
    else {
        Write-Host "Item with field name '$field' not found."
    }
}

# Convert the modified JSON data back to JSON format with a higher depth value
$encryptedJsonData = $jsonObject | ConvertTo-Json -Depth 10

# Display the modified JSON data
Write-Host "encryptedJsonData: $encryptedJsonData"
















# # Encryption key
# $keyHex = $env:key  # Replace with your encryption key

# # Create a new AES object with the specified key and AES mode
# $AES = New-Object System.Security.Cryptography.AesCryptoServiceProvider
# $AES.KeySize = 256  # Set the key size to 256 bits for AES-256
# $AES.Key = [System.Text.Encoding]::UTF8.GetBytes($keyHex.PadRight(32))
# $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC

# # Loop through the specified fields and encrypt their values
# foreach ($field in $fieldsToEncrypt) {
#     Write-Host "Entered into FOREACH...!"

#     # Access the value of the current field
#         $plaintext = $field

#         # Convert plaintext to bytes (UTF-8 encoding)
#         $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

#         # Generate a random initialization vector (IV)
#         $AES.GenerateIV()
#         $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

#         # Encrypt the data
#         $encryptor = $AES.CreateEncryptor()
#         $encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)
#         $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

#         # Store the encrypted value back in the JSON data
#         $field = @{
#             "EncryptedValue" = $encryptedBase64
#             "IV" = $IVBase64
#         }

#     # # Check if the credentials array exists and has at least one item
#     # if ($appdetailget.keyValueEntries.Count -gt 0) {

#     #     # Access the value of the current field
#     #     $plaintext = $appdetailget.keyValueEntries[0].$field

#     #     # Convert plaintext to bytes (UTF-8 encoding)
#     #     $plaintextBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintext)

#     #     # Generate a random initialization vector (IV)
#     #     $AES.GenerateIV()
#     #     $IVBase64 = [System.Convert]::ToBase64String($AES.IV)

#     #     # Encrypt the data
#     #     $encryptor = $AES.CreateEncryptor()
#     #     $encryptedBytes = $encryptor.TransformFinalBlock($plaintextBytes, 0, $plaintextBytes.Length)
#     #     $encryptedBase64 = [System.Convert]::ToBase64String($encryptedBytes)

#     #     # Store the encrypted value back in the JSON data
#     #     $appdetailget.keyValueEntries[0].$field = @{
#     #         "EncryptedValue" = $encryptedBase64
#     #         "IV" = $IVBase64
#     #     }
#     # }
# }

# # Convert the modified JSON data back to JSON format with a higher depth value
# $encryptedJsonData = $field | ConvertTo-Json -Depth 10

# # Display the modified JSON data
# Write-Host $encryptedJsonData

# # Define the local file path and file name
# $filePath = $env:sourcepath

# # Write the JSON data to the file
# $encryptedJsonData | Set-Content -Path $filePath -Encoding UTF8
