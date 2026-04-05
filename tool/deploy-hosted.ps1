param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectRef
)

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

function Invoke-SupabaseCommand {
  param(
    [Parameter(Mandatory = $true)]
    [string[]]$Arguments
  )

  & supabase @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Supabase command failed: supabase $($Arguments -join ' ')"
  }
}

Require-Command -Name "supabase" -HelpText "Install the Supabase CLI first."

$root = Join-Path $PSScriptRoot ".."
$root = [System.IO.Path]::GetFullPath($root)
$envFile = Join-Path $root "supabase\.env.local"
$tempSecretsFile = Join-Path $root "supabase\.env.deploy.local"

if (-not (Test-Path $envFile)) {
  Write-Error "Missing supabase/.env.local. Copy supabase/.env.example to supabase/.env.local and fill in the real secrets first."
}

Push-Location $root
try {
  Invoke-SupabaseCommand -Arguments @("link", "--project-ref", $ProjectRef)
  Invoke-SupabaseCommand -Arguments @("db", "push")

  # Hosted Supabase already provides SUPABASE_* runtime vars for Edge Functions.
  # Filtering them here keeps deploy output cleaner and avoids reserved-name warnings.
  Get-Content $envFile |
    Where-Object {
      -not [string]::IsNullOrWhiteSpace($_) -and
      -not $_.StartsWith("#") -and
      -not $_.StartsWith("SUPABASE_")
    } |
    Set-Content $tempSecretsFile

  if ((Get-Item $tempSecretsFile).Length -gt 0) {
    Invoke-SupabaseCommand -Arguments @(
      "secrets",
      "set",
      "--env-file",
      $tempSecretsFile,
      "--project-ref",
      $ProjectRef
    )
  }

  foreach ($functionName in @(
    "generate-music",
    "generate-video",
    "generate-lyrics",
    "verify-purchase",
    "delete-account"
  )) {
    Write-Host "Deploying $functionName..."
    Invoke-SupabaseCommand -Arguments @(
      "functions",
      "deploy",
      $functionName,
      "--no-verify-jwt",
      "--project-ref",
      $ProjectRef
    )
  }

  Write-Host ""
  Write-Host "Hosted deployment finished for project $ProjectRef."
} finally {
  if (Test-Path $tempSecretsFile) {
    Remove-Item $tempSecretsFile -Force
  }
  Pop-Location
}
