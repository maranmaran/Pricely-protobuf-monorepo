param($repository, $version, $description) 

# Describes package name - parsed out of repo name
$name = $repository.split('\/')[-1] -replace "-csharp", ""
$description = (Get-Content 'package.json' | Out-String | ConvertFrom-Json).description

Write-Host "Package name is " + $name
Write-Host "Package version is " + $version
Write-Host "Package description is " + $description

# Generates nuget package
function GenerateNugetPackage($name, $version, $description) {
    
    #region Helper functions

    # Creates dotnet library that will be packed as NUGET package
    function CreateLibrary($csprojPath, $name, $grpcPackageVersion = "2.33.1") {
        # Create lib and add needed packages
        dotnet new classlib -f netcoreapp3.1 --no-restore -o $name  
        dotnet add $csprojPath package Grpc.AspNetCore -v $grpcPackageVersion --no-restore

        # Cut all previously generated stubs (.cs grpc files) to library
        $stubs = Get-ChildItem . -Filter "*.cs"
        foreach($stub in $stubs) {
            Copy-Item $stub -Destination $name
        }
    
        # This has to be removed manually. Microsoft still didn't add some kind of flag
        # To suppress this default class generation 
        Remove-Item -Path ($name + "/Class1.cs")
    }

    # Sets some metadata for nuget package (version, id, company etc)
    function SetLibraryMetadata($csprojPath, $name, $version, $description, $company = "P3") {
        # Get csproj as XML
        [xml]$projectXML = Get-Content ($csprojPath)

        # Create elements to write to
        $packageId = $projectXML.CreateElement("PackageId")
        $packageVersion = $projectXML.CreateElement("Version")
        $packageCompany = $projectXML.CreateElement("Company")
        $packageDescription = $projectXML.CreateElement("PackageDescription")

        # Add values
        $packageId.InnerText = $name
        $packageVersion.InnerText = $version
        $packageCompany.InnerText = $company
        $packageDescription.InnerText = $description

        # Append as nodes to xml Project node
        $projectXML.Project.PropertyGroup.AppendChild($packageId)
        $projectXML.Project.PropertyGroup.AppendChild($packageVersion)
        $projectXML.Project.PropertyGroup.AppendChild($packageCompany)
        $projectXML.Project.PropertyGroup.AppendChild($packageDescription)

        # Save
        $projectXML.Save($csprojPath)
    }

    #endregion

    $csprojPath = $name + "/" + $name + ".csproj"
    
    Write-Host "Creating library"
    CreateLibrary $csprojPath $name

    Write-Host "Setting nuget details"
    SetLibraryMetadata $csprojPath $name $version

    # Pack nuget
    Write-Host "Packing nuget"
    dotnet pack $csprojPath -o "nuget"

    # Remove-Item $name -Recurse 
}

GenerateNugetPackage $name $version $description

