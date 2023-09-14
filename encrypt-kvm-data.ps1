# Load the environment variables
$git_token = $env:token
$fileContent = $env:jsonInput

Write-Host "fileContent: $fileContent"

# Specify the fields you want to encrypt
$fieldsToEncrypt = $env:fieldsToEncrypt -split ","

try {

    $jsonContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($fileContent.content))
    $appdetailget = $jsonContent | ConvertFrom-Json

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
        Write-Host "Entered into Foreach...!"
        # Check if the credentials array exists and has at least one item
        $plaintext = $field

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

        # Store the encrypted value back in the JSON data
        $appdetailget.credentials[0].$field = @{
            "EncryptedValue" = $encryptedBase64
            "IV" = $IVBase64
        }
    }

    # Convert the modified JSON data back to JSON format with a higher depth value
    $encryptedJsonData = $appdetailget | ConvertTo-Json -Depth 10

    # Display the modified JSON data
    Write-Host $encryptedJsonData

    # Define your GitHub username, repository names, branch names, and file paths
    $githubUsername = $env:targetgithubUsername
    $repositoryName = $env:targetrepositoryName
    $sourceBranchName = $env:targetBranchName
    $targetFilePath = $env:targetFilePath

    # Define your GitHub personal access token
    $githubToken = $git_token  # Replace with your GitHub token

    # Encode the content you want to update as base64
    $updatedContent = $encryptedJsonData
    $updatedContentBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($updatedContent))

    # Define the API URL to fetch the file content from the source branch
    $apiUrl = "https://api.github.com/repos/"+$githubUsername+"/"+$repositoryName+"/contents/"+$targetFilePath+"?ref="+$sourceBranchName

    # Set the request headers with your personal access token
    $headers = @{
        Authorization = "Bearer $githubToken"
        "Content-Type" = "application/json"
    }

    # Check if the file already exists in the repository and fetch its current SHA
    $fileExists = $false
    $sha = $null
    try {
        $fileContent = Invoke-RestMethod -Uri $apiUrl -Headers @{ Authorization = "Bearer $githubToken" }
        $fileExists = $true
        $sha = $fileContent.sha
    }
    catch {
        # The file doesn't exist
    }

    # Create a JSON body for the API request
    $requestBody = @{
        "branch" = $sourceBranchName
        "message" = "Update Decrypted Data"
        "content" = $updatedContentBase64  # Use the base64-encoded content
        "sha" = $sha  # Include the current SHA
    } | ConvertTo-Json

    # Determine whether to make a PUT or POST request based on whether the file exists
    if ($fileExists) {
        # File already exists, make a PUT request to update it
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "encrypted data has been successfully updated in $targetFilePath in branch $sourceBranchName."
        }
        catch {
            Write-Host "An error occurred while updating the file: $_"
        }
    }
    else {
        # File doesn't exist, make a POST request to create it
        try {
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method PUT -Body $requestBody

            Write-Host "Decrypted data has been successfully created in $targetFilePath in branch $sourceBranchName."
        }
        catch {
            Write-Host "An error occurred while creating the file: $_"
        }
    }
}
catch {
    Write-Host "An error occurred: $_"
}
