
$hardcodedData =  Get-Content -Raw -Path parameters.json | ConvertFrom-Json 
$Organization = $hardcodedData.organization
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
    
    #BuildNumber should be summited
    $BuildNumber = $hardcodedData.BuildNumber

    #Load artifacts data according to the $BuildNumber
    New-ComposeArtifactsJson -BuildNumber $BuildNumber -JsonBody $Json

    return $Json
}

function New-ComposeArtifactsJson {
    param (
        [parameter(Mandatory = $false)]
        [string]$BuildNumber = -1,

        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )

    # #Get build pipeline base on Pipeline Definition
    # $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/pipelines/"+$BuildDefinitionId+"?api-version=4.1"
    # $BuildPipelineData = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers        
   
    # #Get builddata
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds?buildNumber="+$BuildNumber+"&api-version=4.1"
    write-host $Url 
    $BuildData = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers

    if ($null -eq $BuildData){  
        Write-Output "Build can't be found" 
        return 
    } 
    
    if ($BuildData.value.count -eq 0){ 
        Write-Output "Build can't be found" 
        return 
    }

    $BuildInfo = $BuildData.value

    $BuildDefinitionId = $BuildInfo.definition.id
    $BuildDefinitionName = $BuildInfo.definition.name
    $BuildId = $BuildInfo.id

    $ProjectId = $BuildInfo.project.id    
    
    #write-host $Url
    #write-host $BuildData.definition.name
    write-host $BuildNumber
    
    #Get artifact data from AzureDevOps API according to the lkg build id
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds/"+$BuildId+"/artifacts?api-version=4.1"
    $ArtifactData = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers
  
    #write-host $Url
    #write-host $ArtifactData

    if ($null -eq $ArtifactData){  
        Write-Output "Artifact can't be found" 
        return 
    } 
    
    if ($ArtifactData.value.count -eq 0){ 
        Write-Output "Artifact can't be found" 
        return 
    }

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
    # $Url = "https://vsrm.dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/release/definitions?api-version=7.1-preview.4"
    # write-host $Url 

    #Compose body options
    $JsonBody =  New-ComposeJsonBodyOptions | ConvertTo-Json -Depth 9
    $JsonBody | Out-File "./bodyResult.json"

    write-host $result 
    #$result = Invoke-RestMethod -ContentType "application/json" -Uri $url  -Method Post  -Body $JsonBody  -Headers $headers

    
    
}

New-CreateReleasePipeline
