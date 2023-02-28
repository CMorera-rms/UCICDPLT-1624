### Functions ###
#param ([String[]]  $usersList)



function Read-ReleaseTemplateData {
    write-host "-----------------------------------------------------------"
    write-host "Read parameters"
    $json = Get-Content -Raw -Path test.json | ConvertFrom-Json
    return $json
}

function Convert-ReleaseTemplateDataJSON {
    write-host "-----------------------------------------------------------"
    write-host "Convert File"
    $json = Get-Content -Raw -Path test.json | ConvertFrom-Json  | ConvertTo-Json -Depth 9
    return $json
}

function New-ReleasePipeline {
    write-host "-----------------------------------------------------------"
    write-host "Create Release Pipeline"
    $organization = "cmorera"
    $project = "cata-test"
    $token = "5xp76tq5zjetjfj4dj5jsilvuxffr6mxhebt6nidbngu6km4sufa"
    $url = "https://vsrm.dev.azure.com/"+$organization+"/"+$project+"/_apis/release/definitions?api-version=7.1-preview.4"
    write-host $url 

    $user = ''
    $pass = $token
    $headers = @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($user+":"+$pass)) }
    $body =  Convert-ReleaseTemplateDataJSON
    write-host $body.source


    $JsonBody = $body
    
    $result = Invoke-RestMethod -ContentType "application/json" -Uri $url  -Method Post  -Body $JsonBody  -Headers $headers
    write-host $result

}


#Read-ReleaseTemplateData
#Convert-ReleaseTemplateDataJSON
New-ReleasePipeline
