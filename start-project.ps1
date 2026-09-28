param(
    [switch]$NoInstall
)

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$stateKey = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($projectRoot)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$stateFile = Join-Path $env:TEMP "meu-saas-start-$stateKey.json"

if (Test-Path $stateFile) {
    throw 'Ja existe uma sessao registrada. Execute .\stop-project.ps1 antes de iniciar novamente.'
}

foreach ($tool in @('docker', 'java', 'javac', 'node', 'npm')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "Comando obrigatorio nao encontrado no PATH: $tool"
    }
}

$javaVersion = (& java -version 2>&1 | Out-String)
if ($javaVersion -notmatch 'version "25(?:\.|\")') {
    throw "Java 25 e necessario para a API. Versao detectada: $javaVersion"
}

$dockerInfo = & docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    throw 'Docker nao esta acessivel. Inicie o Docker Desktop e tente novamente.'
}

$frontendProjects = @('web', 'landing', 'mobile')
foreach ($name in $frontendProjects) {
    $projectDirectory = Join-Path $projectRoot $name
    if (-not (Test-Path (Join-Path $projectDirectory 'package.json'))) {
        throw "package.json nao encontrado para o modulo $name em $projectDirectory"
    }

    if (-not (Test-Path (Join-Path $projectDirectory 'node_modules'))) {
        if ($NoInstall) {
            throw "Dependencias ausentes em $name. Execute npm ci ou rode sem -NoInstall."
        }

        Push-Location $projectDirectory
        try {
            if (Test-Path 'package-lock.json') {
                & npm ci
            }
            else {
                & npm install
            }
            if ($LASTEXITCODE -ne 0) {
                throw "Falha ao instalar dependencias npm do modulo $name."
            }
        }
        finally {
            Pop-Location
        }
    }
}

Push-Location $projectRoot
try {
    $runningPostgres = @(& docker compose ps --status running -q postgres)
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao consultar o estado do PostgreSQL no Docker Compose.'
    }
    $stopPostgresOnFinish = ($runningPostgres.Count -eq 0)

    & docker compose up -d
    if ($LASTEXITCODE -ne 0) {
        throw 'Falha ao iniciar o PostgreSQL via Docker Compose.'
    }
}
finally {
    Pop-Location
}

$session = [ordered]@{
    ProjectRoot = $projectRoot
    StopPostgres = $stopPostgresOnFinish
    Processes = @()
}

function Save-ProjectSession {
    $session | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $stateFile -Encoding UTF8
}

Save-ProjectSession

function Start-ProjectTerminal {
    param(
        [string]$Name,
        [string]$Directory,
        [string]$Command
    )

    $escapedDirectory = $Directory.Replace("'", "''")
    $terminalScript = @"
`$Host.UI.RawUI.WindowTitle = '$Name'
Set-Location -LiteralPath '$escapedDirectory'
Write-Host 'Iniciando $Name...' -ForegroundColor Cyan
$Command
"@
    $encodedScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($terminalScript))
    $process = Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-NoExit', '-EncodedCommand', $encodedScript) `
        -WorkingDirectory $Directory `
        -PassThru

    $processInfo = Get-Process -Id $process.Id
    $session.Processes = @($session.Processes) + @([ordered]@{
        Name = $Name
        Id = $process.Id
        StartTimeUtcTicks = $processInfo.StartTime.ToUniversalTime().Ticks
    })
    Save-ProjectSession
}

Start-ProjectTerminal -Name 'API - 8080' `
    -Directory (Join-Path $projectRoot 'api') `
    -Command '.\mvnw.cmd spring-boot:run'
Start-ProjectTerminal -Name 'Web - 4200' `
    -Directory (Join-Path $projectRoot 'web') `
    -Command 'npm run start -- --port 4200'
Start-ProjectTerminal -Name 'Landing - 4201' `
    -Directory (Join-Path $projectRoot 'landing') `
    -Command 'npm run start -- --port 4201'
Start-ProjectTerminal -Name 'Mobile - 8100' `
    -Directory (Join-Path $projectRoot 'mobile') `
    -Command 'npm run start -- --port 8100'

Write-Host ''
Write-Host 'Servicos iniciados em terminais separados:' -ForegroundColor Green
Write-Host '  API:     http://localhost:8080'
Write-Host '  Web:     http://localhost:4200'
Write-Host '  Landing: http://localhost:4201'
Write-Host '  Mobile:  http://localhost:8100'
Write-Host '  Postgres: localhost:5432'
