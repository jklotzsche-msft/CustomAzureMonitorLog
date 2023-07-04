# Import all functions from the functions folder and all subfolders into the current session using dot-sourcing
foreach ($file in Get-ChildItem -Path "$PSScriptRoot/functions" -Filter *.ps1 -Recurse) {
    . $file.FullName
}