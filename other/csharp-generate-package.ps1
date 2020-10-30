$path = "gen\AllergenServiceProtos"

if (Test-Path ($path + "\Class1.cs")) 
{
  Remove-Item ($path + "\Class1.cs")
}

[xml]$project = Get-Content ($path + "\AllergenServiceProtos.csproj")

$itemGroup = $project.CreateElement("ItemGroup")

$project.Project.AppendChild($itemGroup)

$files = Get-ChildItem "gen\pb-csharp" 

foreach($file in $files) {

    $src = Join-Path "gen\pb-csharp" $file

    Copy-Item $src -Destination $path

    $newChild = $project.CreateElement("Compile")
    $newChild.SetAttribute("Include", $file)

    $itemGroup.AppendChild($newChild)
}

$project.Save($path + "\AllergenServiceProtos.csproj")

