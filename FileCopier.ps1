$global:FILES_PATH = @()

class Node
{
    [bool]$IsFile
    [string]$Name
    [string]$Path
	
	Node([bool]$IsFile, [string]$Name, [string]$Path) {
		$this.IsFile = $IsFile;
		$this.Name = $Name;
		$this.Path = $Path;
	}
}

function CreateRootDirectory($rootPath)
{
	Write-Host "> Test-Path (root dir) $rootPath $(Test-Path $rootPath)"
	if (!(Test-Path $rootPath)) {
		Write-Host "> mkdir $rootPath"
		mkdir $rootPath
	}
	Write-Host
}

#Reading file and directory names and paths
function ReadNodeValue($node, $path)
{
	if($node.Name -eq "file") {
		$global:FILES_PATH += New-Object Node $True, $($node.InnerXML), $path
	}
	if ($node.Name -ne "root" -and $node.Name -ne "#file" -and $node.Name -ne "file" -and $node.Name -ne "#text") {
		$global:FILES_PATH += New-Object Node $False, $($node.Name), $path
		$path = $path + $node.Name + "\"
	}

    foreach ($child in $node.ChildNodes) {
        ReadNodeValue $child $path
    }
}

function Wait()
{
	Read-Host "Press ENTER to continue..."
}

function TestFiles($files)
{
	foreach($file in $files) {
		if(Test-Path $("files\" + $file)) {
			Write-Host "> Test-Path (file) $file" $(Test-Path $("files/" + $file))
		}
		
		while (!(Test-Path $("files\" + $file))) {
			Write-Host "> Test-Path (file) $file" $(Test-Path $("files/" + $file))
			Wait
		}
	}
	Write-Host
}

function CopyFiles()
{
	foreach($node in $global:FILES_PATH) {
		if(!$node.IsFile) {
			Write-Host ">"Test-Path" (dir) "$("$($node.Path)$($node.Name)\") $(Test-Path $("$($node.Path)$($node.Name)\"))
			if(!$(Test-Path $("$($node.Path)$($node.Name)\"))) {
				Write-Host "> mkdir $($node.Path)$($node.Name)\"
				mkdir "$($node.Path)$($node.Name)\"
			}
		}
	}
	Write-Host
	
	foreach($node in $global:FILES_PATH) {		
		if($node.IsFile) {
			Write-Host -NoNewline "> cp files\$($node.Name) $($node.Path)"
			if($(Test-Path $("$($node.Path)$($node.Name)"))) {
				Write-Host " (overwritten)"
			}
			else {
				Write-Host
			}
			cp "files\$($node.Name)" "$($node.Path)"
		}
	}
	Write-Host
}

Write-Host "Program copy given files to given directory structure`n"
[xml]$xmlData = Get-Content -Path configuration.xml
$rootPath = $xmlData.root | Select path -ExpandProperty path

Write-Host "Creation root directory specified in configuration.xml"
CreateRootDirectory($rootPath)

ReadNodeValue $xmlData.DocumentElement $rootPath

Write-Host "Checking if file specified in configuration.xml exists"
$files = $xmlData.SelectNodes('//file') | Select-Object -Expand '#text'
TestFiles $files

Write-Host "Checking, creation directory structure and copy files"
CopyFiles