$ErrorActionPreference = "Stop"

function Require-Command {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
    [Parameter(Mandatory = $true)]
    [string]$HelpText
  )

  if ($null -eq (Get-Command $Name -ErrorAction SilentlyContinue)) {
    Write-Error "$Name is not installed. $HelpText"
  }
}

Require-Command -Name "supabase" -HelpText "Install the Supabase CLI first."
Require-Command -Name "docker" -HelpText "Install Docker Desktop and make sure it is running before starting local Supabase."

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)

Push-Location $root
try {
  supabase start
  Write-Host ""
  Write-Host "Local Supabase is running."
  Write-Host "Studio: http://127.0.0.1:54323"
  Write-Host "API:    http://127.0.0.1:54321"
  Write-Host ""
  Write-Host "Run 'supabase status' if you need the local anon key."
} finally {
  Pop-Location
}
