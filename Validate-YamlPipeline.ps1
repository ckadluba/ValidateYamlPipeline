[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $OrgName,
    [Parameter(Mandatory=$true)]
    [string]
    $ProjectName,
    [Parameter(Mandatory=$true)]
    [string]
    $PipelineId
)

function CleanupGitWorkTree($previousBranch, $validationBranch, $validationBranchCreated, $stashCreated)
{
    git checkout "$previousBranch"
    if ($stashCreated -eq $true) {
        git stash pop --index
    }

    if ($validationBranchCreated -eq $true) {
        git push --delete origin "$validationBranch"
        git branch -D "$validationBranch"
    }
}

function CallYamlValidationApiWithBranch($orgName, $projectName, $pipelineId, $validationBranch)
{
    $requestUrl = "https://dev.azure.com/$orgName/$projectName/_apis/pipelines/$pipelineId/runs?api-version=6.0-preview.1"

    $requestBody = @{
        "resources" = @{
            "repositories" = @{
                "self" = @{
                    "refName" = "refs/heads/$validationBranch"
                }
            }
        }       
        "PreviewRun" = "true"
    }

    $authString = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $env:SystemTeamTools_TestPipelineYaml_PAT))

    $requestArgs = @{
        Method      = "POST"
        Uri         = $requestUrl
        Body        = $requestBody | ConvertTo-Json -Depth 3
        ContentType = "application/json"
        Headers     = @{Authorization = $authString }
    }

    Invoke-RestMethod @requestArgs    
}


if ($null -eq $env:ValidateYamlPipeline_PAT) {
    throw "Please set the environment variable ValidateYamlPipeline_PAT to a valid PAT token with read and execute permission for builds of pipeline $PipelineId."
}

$previousBranch = git branch --show-current
$domainAndUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$userName = $domainAndUser.Split("\")[1]
$validationBranch = "$userName/yaml-validation"
$validationBranchCreated = $false
$stashCreated = $false

try {
    $stashCountBefore = (git stash list | Measure-Object -Line).Lines
    git stash --include-untracked
    $stashCountAfter = (git stash list | Measure-Object -Line).Lines
    $stashCreated = ($stashCountBefore -ne $stashCountAfter)
    git checkout -b "$validationBranch"
    if ($? -ne $true)
    {
        throw "Could not create temporary validation branch $validationBranch."
    }
    $validationBranchCreated = $true
    if ($stashCreated -eq $true) {
        git stash apply
        git add .
        git commit -am "YAML Validation"
    }
    git push -u origin HEAD
    if ($? -ne $true)
    {
        throw "Could not create temporary validation branch $validationBranch."
    }

    CallYamlValidationApiWithBranch $OrgName $ProjectName $PipelineId $validationBranch    
}
finally {
    CleanupGitWorkTree $previousBranch $validationBranch $validationBranchCreated $stashCreated
}
