param($packageName, $repoName) 

# $protoSrc = "packages/dispatch/"
# $genSrc = "gen/pb-csharp/"
$protoSrc = ""
$genSrc = ""
$version = "1.0.0"
$nugetOutput = "nuget"

Write-Host $packageName
Write-Host $repoName

# Generates nuget package
function GenerateNugetPackage($protoSrc, $genSrc, $packageName, $version, $nugetOutput) {
    
    #region Helper functions

    # Creates dotnet library that will be packed as NUGET package
    function CreateClassLibrary($path, $name, $grpcPackageVersion = "2.33.1") {
        # Create lib and add needed packages
        dotnet new classlib -f netcoreapp3.1 --no-restore -o ($path + $name)  
        dotnet add ($path + $name + "/" + $name + ".csproj") package Grpc.AspNetCore -v $grpcPackageVersion --no-restore

        # This has to be removed manually. Microsoft still didn't add some kind of flag
        # To suppress this default class generation 
        Remove-Item -Path ($path + $name + "/Class1.cs")
    }

    # Sets some metadata for nuget package (version, id, company etc)
    function SetNugetPackageDetails($libraryPath, $id, $version, $company = "P3") {
        # Get csproj as XML
        [xml]$projectXML = Get-Content ($libraryPath)

        # Create elements to write to
        $packageId = $projectXML.CreateElement("PackageId")
        $packageVersion = $projectXML.CreateElement("Version")
        $packageCompany = $projectXML.CreateElement("Company")

        # Add values
        $packageId.InnerText = $id
        $packageVersion.InnerText = $version
        $packageCompany.InnerText = $company

        # Append as nodes to xml Project node
        $projectXML.Project.PropertyGroup.AppendChild($packageId)
        $projectXML.Project.PropertyGroup.AppendChild($packageVersion)
        $projectXML.Project.PropertyGroup.AppendChild($packageCompany)

        # Save
        $projectXML.Save($libraryPath)
    }

    #endregion

    $packageProjectPath = $genSrc + $packageName + "/" + $packageName + ".csproj"
    
    CreateClassLibrary $genSrc $packageName

    SetNugetPackageDetails $packageProjectPath $packageName $version

    # Prepare nuget
    dotnet pack $packageProjectPath -o $nugetOutput

    $nupkgName = ($packageName + "." + $version + ".nupkg")
    $apiKey = "f15f053c-dab1-4808-98f3-29833486497a"
    $feedSrc = "ProtoPackages"

    # Publish nuget
    dotnet nuget push $nupkgName --api-key $apiKey --source $feedSrc
}

GenerateNugetPackage $protoSrc $genSrc $packageName $version $nugetOutput

