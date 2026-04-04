$ErrorActionPreference = "Stop"

$definesPath = Join-Path $PSScriptRoot "..\\dart_defines.json"
$definesPath = [System.IO.Path]::GetFullPath($definesPath)

if (-not (Test-Path $definesPath)) {
  Write-Error "Missing dart_defines.json. Copy dart_defines.example.json to dart_defines.json and fill in the real values first."
}

$defines = Get-Content $definesPath -Raw | ConvertFrom-Json

if ([string]::IsNullOrWhiteSpace($defines.SHAYA_SUPABASE_URL) -or $defines.SHAYA_SUPABASE_URL -eq "https://YOUR_PROJECT_REF.supabase.co") {
  Write-Error "SHAYA_SUPABASE_URL is still a placeholder in dart_defines.json."
}

if ([string]::IsNullOrWhiteSpace($defines.SHAYA_SUPABASE_ANON_KEY) -or $defines.SHAYA_SUPABASE_ANON_KEY -eq "YOUR_SUPABASE_ANON_KEY") {
  Write-Error "SHAYA_SUPABASE_ANON_KEY is still a placeholder in dart_defines.json."
}

flutter run --dart-define-from-file="$definesPath"
