# ValidateYamlPipeline

A PowerShell script to validate the YAML files of an Azure DevOps pipeline.

The script can be used to validate a whole hierarchy of pipeline YAML. It can be used on a local git working tree of an Azure DevOps repo which contains the YAML source of an existing pipeline. 

To achieve this the script automates the following actions.

1. Save your local changes (git stash).
1. Create a temporary branch and check it out.
1. Commit your stashed changes to the temporary branch.
1. Push the temporary branch to the origin.
1. Call the Azure DevOps API to validate the pipeline with the given pipeline ID and the temporary branch
1. Display the validation result.
1. Switch back to your original branch.
1. Restore your local changes (index and working tree from git stash).
1. Delete the temporary branch.

# Setup and Usage

1. In Azure DevOps UI create a PAT token in Azure DevOps that has the permission to __execute and read__ your existing pipeline in your project.
   ![image](https://user-images.githubusercontent.com/10721825/162755251-70abac04-3307-48bf-8e95-0e1c11847759.png)![image](https://user-images.githubusercontent.com/10721825/162756012-7ebff55e-cb34-4a36-aae3-169ef49ad10e.png)
1. Create the environment variable `ValidateYamlPipeline_PAT` containing the PAT token.
   ![image](https://user-images.githubusercontent.com/10721825/162756547-502105f4-2ab4-4a43-8eee-eaa1f9141f3c.png)
1. Get the organisation, project name and pipeline ID from the Azure DevOps UI.
1. Make YAML changes in your local git working tree.
1. Run the script to validate your changes.
   ```powershell
   .\Validate-YamlPipeline.ps1 -OrgName "myorganisation" -ProjectName "MyProject" -PipelineId "2342"
   ```
   ![image](https://user-images.githubusercontent.com/10721825/162759738-3b9a76c9-8926-4a36-b861-9ba2d2da7fd3.png)


Steps 1 to 3 only have to be done once while 4 and 5 would normally occur repeatedly during YAML pipeline development. 

# Prerequisites

* PowerShell 7
* Azure DevOps account
* Azure DevOps git repo with YAML pipeline source
* Azure DevOps pipeline with ID
* Azure DevOps PAT token
