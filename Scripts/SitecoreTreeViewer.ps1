function Get-yUMLDiagram {
	param(
		$yUML,
		$diagramFileName = "C:\inetpub\wwwroot\App_Data\logs\test.svg"
	)
	$wc = New-Object Net.WebClient
	$wc.DownloadFile("https://yuml.me/diagram/nofunky/class/" + $yUML,$diagramFileName)
}

function Show-ResultsDialog {
	param(
		$image64
	)
	$description = "Dependency graph based on item path/id dependency"
	$legend = "This graph represents desired dependency determined based on item's id/path dependencies between each module."
	$result2 = Read-Variable -Parameters `
 		@{ Name = "Info0"; Title = ""; Value = '<img src="data:image/svg+xml;base64,' + $image64 + '""/>'; editor = "info" },`
 		@{ Name = "Info1"; Title = "Legend:"; Value = $legend; editor = "info" } `
 		-Description $description -Title "Dependency Graph" -Width 1000 -Height 800 `
 		-CancelButtonName "Exit"
	if ($result2 -eq "cancel") {
		exit
	}
}

function ProcessChildren($parent)
{
    $result = ""
    $kids = $parent.children
    foreach($child in $kids)
    {
        $isPublished = IsPublished($child.Paths.FullPath)
        $bgColor = "white"
        if ($isPublished -ne $true) {
            $bgColor = "orange"
        }
        
        $isParentPublished = IsPublished($parent.Paths.FullPath)
        $parentBgColor = "white"
        if ($isParentPublished -ne $true) {
            $parentBgColor = "orange"
        }
        
        $result += "[" + $parent.Name + " {bg:" + $parentBgColor + "}]-^["+ $child.Name +" {bg:" + $bgColor + "}],"
        ProcessChildren($child)
    }
    return $result
}

function IsPublished($path) {
    $itemExists = Test-Path -Path "web:$($path)"
    return $itemExists
}

$props = @{
    Title = "UML Graph"
    Parameters = @(
        @{ Name = "startItem"; Title = "Item"; Editor = "droptree" }
    )
}
$result = Read-Variable @props
if($result -ne "ok") {
    Close-Window
    Exit
}
$rootPath = $startItem.Paths.FullPath
$itemDb = $startItem.Database
$path = "C:\inetpub\wwwroot\App_Data\logs\test.svg"
$uml = ""
$item = Get-Item -Path ("{0}:{1}" -f $itemDb, $rootPath)
$uml += ProcessChildren -parent $item -uml $uml

Get-yUMLDiagram $uml
$base64 = [convert]::ToBase64String((Get-Content $path -Encoding byte))
Show-ResultsDialog $base64 