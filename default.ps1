Framework "4.0x86"

properties {
	$baseDir = Resolve-Path "."
	$buildtoolsDir = Resolve-Path "."
	$outDir = "$(Resolve-Path ""."")\bin"
	$branch = "develop"
}

Task default -Depends Build-All

Function Update-Packages($PackagesDirectory) {
	"Updating packages for $PackagesDirectory"
	dir $PackagesDirectory | ? { $_.Name -match "^.+\.[0-9]" } | % {
		$referenceName = $_.FullName
		$baseName = $_.Name -replace "^(.+?)\.[0-9].*$","`$1"
		dir "$outDir\$baseName.[0-9]*.nupkg" | % { .\7z.exe x -r -y "-o$referenceName" "$($_.FullName)" | Out-Null }
	}
}

Function Build-Project($ProjectName, $UpdatePackages = $true) {
	If ($UpdatePackages) {
		Update-Packages "$baseDir\$ProjectName\packages"
	}
	Invoke-Psake "$baseDir\$ProjectName\build\default.ps1"
	cp "$baseDir\$ProjectName\bin\*.nupkg" $outDir
}

Task Build-All {
	if (Test-Path $outDir) {
		rm -Recurse -Force "$outDir" >$null
	}
	md $outDir >$null

	Write-Host "Fetching repos..."
	Exec { git submodule -q foreach git fetch origin -q }
	Write-Host "Done."

	Write-Host "Checking out branch $branch in all repos..."
	Exec { git submodule -q foreach git reset --hard -q "origin/$branch" }
	Write-Host "Done."

	Write-Host "Updating submodules in all repos..."
	Exec { git submodule -q foreach git submodule -q update --init --recursive }
	Write-Host "Done."

	Write-Host "Cleaning all repos..."
	Exec { git submodule -q foreach git clean -xdfq }
	Write-Host "Done."
	
	Build-Project -ProjectName Compiler -UpdatePackages $false
	Build-Project -ProjectName QUnit
	Build-Project -ProjectName Linq
	Build-Project -ProjectName Web
	Build-Project -ProjectName Loader
	Build-Project -ProjectName Knockout
	Build-Project -ProjectName jQuery
	Build-Project -ProjectName jQueryUI
	Build-Project -ProjectName NodeJS
}
