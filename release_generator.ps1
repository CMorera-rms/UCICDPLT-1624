### Functions ###
#param ([String[]]  $usersList)

$Organization = "cmorera"

$ProjectId = "3b0727f4-d94e-433c-ad69-9216c50ea468"
$ProjectName = "cata-test"

$Token = "kttwvkvlaojpfirum4nvzcqnwduw6hvkyueqdzmncbiabldq5hta"
$User = ''
$Pass = $Token
$Headers = @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($User+":"+$Pass)) }


function New-ComposeJsonBodyOptions {
    write-host "-----------------------------------------------------------"
    write-host "Compose request body JSON"

    $Json = Get-Content -Raw -Path template.json | ConvertFrom-Json 
    
    #BuildDefinition id should be summited
    $BuildDefinitionId = 7
    #write-host $Json
    New-ComposeArtifactsJson -BuildDefinitionId $BuildDefinitionId -JsonBody $Json

    return $Json
}

function New-ComposeArtifactsJson {
    param (
        [parameter(Mandatory = $false)]
        [int]$BuildDefinitionId = -1,

        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )
    
    #Get the lkg build id according to the build definition id
    #TODO: Do functionality to get the lkg id
    #write-host $BuildDefinitionId
    $BuildDefinitionName = "webapi-manual-pipeline-build"
    $BuildLKG = 30
    $BuildId = $BuildLKG
   
    #Get artifact data from AzureDevOps API according to the lkg build id
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds/"+$BuildId+"/artifacts?api-version=4.1"
    $ArtifactData = Invoke-RestMethod  -Uri $Url  -Method Get  -Headers $Headers
    #write-host $ArtifactData.value

    $ArtifactId = $ArtifactData.value.id
    $ArtifactName = $ArtifactData.value.name

    #write-host $ArtifactId
    #write-host $ArtifactName

    write-host $JsonBody.artifacts.alias

    #Update values on JSON body template
    $JsonBody.artifacts.alias1 = $ArtifactName

    #Update defaultVersionSpecific data
    #write-host $JsonBody.artifacts.definitionReference.defaultVersionSpecific
    $JsonBody.artifacts.definitionReference.defaultVersionSpecific.id = $ArtifactId
    $JsonBody.artifacts.definitionReference.defaultVersionSpecific.name = $ArtifactName
    #write-host $JsonBody.artifacts.definitionReference.defaultVersionSpecific

    #Update definition data
    #write-host $JsonBody.artifacts.definitionReference.definition
    $JsonBody.artifacts.definitionReference.definitions.id = $BuildDefinitionId
    $JsonBody.artifacts.definitionReference.definitions.name = $BuildDefinitionName
    #write-host $JsonBody.artifacts.definitionReference.definition

    #Update project data
    #write-host $JsonBody.artifacts.definitionReference.project
    $JsonBody.artifacts.definitionReference.project.id = $ProjectId
    $JsonBody.artifacts.definitionReference.project.name = $ProjectName
    #write-host $JsonBody.artifacts.definitionReference.project

}

function New-ComposeEnviromentsJson {
    param (
    
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )
   write-host $JsonBody.source
}

function New-ComposeVariablesJson{
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )

   write-host $JsonBody.source
}


function New-CreateReleasePipeline {
    write-host "-----------------------------------------------------------"
    $JsonBody =  New-ComposeJsonBodyOptions | ConvertTo-Json -Depth 9

    #$Json = Get-Content -Raw -Path template.json | ConvertFrom-Json  | ConvertTo-Json

    #Write-Host ($JsonBody.artifacts.definitionReference.defaultVersionSpecific)
    #Write-Host ($JsonBody.artifacts.definitionReference.definition )
    #Write-Host ($JsonBody.artifacts.definitionReference.project )

    #write-host "Do Create Release Pipeline Request"
    $url = "https://vsrm.dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/release/definitions?api-version=7.1-preview.4"
    #write-host $url 
    
    $result = Invoke-RestMethod -ContentType "application/json" -Uri $url  -Method Post  -Body $JsonBody  -Headers $headers
    write-host $result 
    
}

New-CreateReleasePipeline
