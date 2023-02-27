### Functions ###
#param ([String[]]  $usersList)



function Read-ReleaseTemplateData {
    write-host "-----------------------------------------------------------"
    write-host "Read parameters"
    $json = Get-Content -Raw -Path parameters.json | ConvertFrom-Json
    write-host $json.sourceId
    write-host $json.createdBy
    write-host $json.modifiedBy

}

function Convert-ReleaseTemplateDataJSON {
    write-host "-----------------------------------------------------------"
    write-host "Convert File"
}

function New-ReleasePipeline {
    write-host "-----------------------------------------------------------"
    write-host "Create Release Pipeline"
}


Read-ReleaseTemplateData
Convert-ReleaseTemplateDataJSON
New-ReleasePipeline
