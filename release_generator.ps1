
$HardcodedData =  Get-Content -Raw -Path parameters.json | ConvertFrom-Json 
$Organization = $HardcodedData.organization
$ProjectName = $HardcodedData.projectName
$PipelineName = $HardcodedData.pipelineName
$PreApprovalsList = $HardcodedData.preApprovals
$PostApprovalsList = $HardcodedData.postApprovals
$BuildNumber = $HardcodedData.buildNumber

$Token = $HardcodedData.token
$User = ''
$Pass = $Token
$Headers = @{ Authorization = "Basic "+ [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($User+":"+$Pass)) }

function New-ComposeJsonBodyOptions {
    #Compose request body JSON
    write-host "Compose request body JSON  ------------------------------------------------"
    
    #Read template data
    $JsonBody = Get-Content -Raw -Path template.json | ConvertFrom-Json 

    #Set release name 
    $JsonBody.name = $PipelineName

    #Set release name
    New-ComposePreDeployApprovalsJson -JsonBody $JsonBody
    New-ComposePostDeployApprovalsJson -JsonBody $JsonBody

    #Load artifacts data according to the $BuildNumber
    New-ComposeArtifactsJson -BuildNumber $BuildNumber -JsonBody $JsonBody

    return $JsonBody
}

function New-ComposeArtifactsJson {
    param (
        [parameter(Mandatory = $false)]
        [string]$BuildNumber = -1,

        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )      
   
    # #Get builddata
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds?buildNumber="+$BuildNumber+"&api-version=4.1"
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
    
    #Get artifact data from AzureDevOps API according to the lkg build id
    $Url = "https://dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/build/builds/"+$BuildId+"/artifacts?api-version=4.1"
    $ArtifactData = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers
  
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

    #Update values on JSON body template
    $Artifact = $JsonBody.artifacts[0]
    $Artifact.alias = $ArtifactName

    #Update defaultVersionSpecific data
    $Artifact.definitionReference.defaultVersionSpecific.id = $ArtifactId
    $Artifact.definitionReference.defaultVersionSpecific.name = $ArtifactName

    #Update definition data
    $Artifact.definitionReference.definition.id = $BuildDefinitionId
    $Artifact.definitionReference.definition.name = $BuildDefinitionName

    #Update project data
    $Artifact.definitionReference.project.id = $ProjectId
    $Artifact.definitionReference.project.name = $ProjectName
}

function New-ComposePreDeployApprovalsJson {
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )
    
    $Enviroments = $JsonBody.environments 
    $ApprovalsLength = $PreApprovalsList.Count

    if($ApprovalsLength -gt 0 ){ 
        foreach($Enviroment in $Enviroments) {
            $ApprovalsData = New-ComposeApprovalsJson $PreApprovalsList
            $Enviroment.preDeployApprovals.approvals = $ApprovalsData
        }
    }
}

function New-ComposePostDeployApprovalsJson {
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )
    
    $Enviroments = $JsonBody.environments 
    $ApprovalsLength = $PostApprovalsList.Count

    if($ApprovalsLength -gt 0 ){ 
        foreach($Enviroment in $Enviroments) {
            $ApprovalsData = New-ComposeApprovalsJson $PostApprovalsList
            $Enviroment.postDeployApprovals.approvals = $ApprovalsData
        }
    }
}

function New-ComposeApprovalsJson {
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $ApprovalsList
    )
    #$ApprovalsData = @()

    $ApprovalsData = New-Object System.Collections.ArrayList

    foreach($Approver in $ApprovalsList) {
        $Index = $ApprovalsList.IndexOf($Approver)
        $ApproverData =  @{
            "rank"= $Index+1;
            "isAutomated"= $false
            "isNotificationOn"= $false
            "approver"=  @{
                "displayName" =  $null
                "id" =  $Approver.id
            }
        }
        
        $ApprovalsData.Add($ApproverData)        

        # $ApprovalsData += $ApproverData
    }
    
    return $ApprovalsData

}

function New-ComposeVariablesJson {
    param (
        [parameter(Mandatory = $false)]
        [PSObject] $JsonBody
    )

   write-host $JsonBody.source
}

function New-CreateReleasePipeline {
    #Compose Release Pipeline Request
    
    #Compose URL
    $Url = "https://vsrm.dev.azure.com/"+$Organization+"/"+$ProjectName+"/_apis/release/definitions?api-version=7.1-preview.4"

    #Compose body options
    $JsonBody =  New-ComposeJsonBodyOptions | ConvertTo-Json -Depth 9
    
    $result = Invoke-RestMethod -ContentType "application/json" -Uri $url  -Method Post  -Body $JsonBody  -Headers $headers
    write-host $result 
}

New-CreateReleasePipeline
