
$hardcodedData =  Get-Content -Raw -Path parameters.json | ConvertFrom-Json 

$Organization = $hardcodedData.organization

$ProjectId = $hardcodedData.projectId
$ProjectName = $hardcodedData.projectName

$Token = $hardcodedData.token
$User = ''
$Pass = $Token
$Headers = @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($User+":"+$Pass)) }

function New-ComposeJsonBodyOptions {
    write-host "-----------------------------------------------------------"
    write-host "Compose request body JSON"

    #Read template data
    $Json = Get-Content -Raw -Path template.json | ConvertFrom-Json 
    
    #BuildDefinition id should be summited
    $BuildDefinitionId = $hardcodedData.buildDefinitionId

    #Load artifacts data according to the $BuildDefinitionId
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
    $BuildLKG =  $hardcodedData.buildId
    $BuildId = $BuildLKG
   
    #Get builddata
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds/"+$BuildId+"?api-version=4.1"
    $BuildData = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers
    $BuildDefinitionName = $BuildData.definition.name
    $BuildNumber = $BuildData.buildNumber
    
    #write-host $Url
    #write-host $BuildData.definition.name
    write-host $BuildNumber
    
    #Get artifact data from AzureDevOps API according to the lkg build id
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds/"+$BuildId+"/artifacts?api-version=4.1"
    $ArtifactData = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers
  
    write-host $Url
    #write-host $ArtifactData

    $ArtifactId = $ArtifactData.value.id
    $ArtifactName = $ArtifactData.value.name

    #write-host $ArtifactId
    #write-host $ArtifactName

    write-host $JsonBody.artifacts

    #Update values on JSON body template
    $Artifact = $JsonBody.artifacts[0]
    $Artifact.alias = $ArtifactName

    #Update defaultVersionSpecific data
    #write-host $JsonBody.artifacts.definitionReference.defaultVersionSpecific
    $Artifact.definitionReference.defaultVersionSpecific.id = $ArtifactId
    $Artifact.definitionReference.defaultVersionSpecific.name = $ArtifactName
    #write-host $JsonBody.artifacts.definitionReference.defaultVersionSpecific

    #Update definition data
    #write-host $JsonBody.artifacts.definitionReference.definition
    $Artifact.definitionReference.definition.id = $BuildDefinitionId
    $Artifact.definitionReference.definition.name = $BuildDefinitionName
    #write-host $JsonBody.artifacts.definitionReference.definition

    #Update project data
    #write-host $JsonBody.artifacts.definitionReference.project
    $Artifact.definitionReference.project.id = $ProjectId
    $Artifact.definitionReference.project.name = $ProjectName
    #write-host $JsonBody.artifacts.definitionReference.project

}

function New-ComposeEnviromentsJson {
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )
   write-host $JsonBody.source
}

function New-ComposeVariablesJson {
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )

   write-host $JsonBody.source
}



function New-CreateReleasePipeline {
    write-host "-----------------------------------------------------------"

    #Compose Release Pipeline Request
    
    #Compose the url
    $Url = "https://vsrm.dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/release/definitions?api-version=7.1-preview.4"
    write-host $Url 

    #Compose body options
    $JsonBody =  New-ComposeJsonBodyOptions | ConvertTo-Json -Depth 9
    $JsonBody | Out-File "./bodyResult.json"

    write-host $result 
    #$result = Invoke-RestMethod -ContentType "application/json" -Uri $url  -Method Post  -Body $JsonBody  -Headers $headers

    
    
}

New-CreateReleasePipeline
