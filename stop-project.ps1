[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = $PSScriptRoot
$stateKey = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($projectRoot)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$stateFile = Join-Path $env:TEMP "meu-saas-start-$stateKey.json"

if (-not (Test-Path $stateFile)) {
    Write-Host 'Nenhuma sessao do projeto foi encontrada para finalizar.'
    return
}

$session = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
if ($session.ProjectRoot -ne $projectRoot) {
    throw 'O arquivo de sessao nao corresponde a esta pasta do projeto.'
}

$actionsPending = $false
foreach ($entry in @($session.Processes)) {
    try {
        $process = Get-Process -Id ([int]$entry.Id) -ErrorAction Stop
    }
    catch {
        continue
    }

    if ($process.StartTime.ToUniversalTime().Ticks -ne [long]$entry.StartTimeUtcTicks) {
        Write-Warning "PID $($entry.Id) foi reutilizado; ignorando para nao encerrar outro processo."
        continue
    }

    $target = "$($entry.Name) (PID $($entry.Id))"
    if ($PSCmdlet.ShouldProcess($target, 'Encerrar o terminal e seus processos filhos')) {
        & taskkill.exe /PID ([int]$entry.Id) /T /F | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Nao foi possivel encerrar $target."
            $actionsPending = $true
        }
    }
    else {
        $actionsPending = $true
    }
}

if ($session.StopPostgres) {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw 'Docker nao esta no PATH; o registro foi mantido para tentar parar o PostgreSQL depois.'
    }

    Push-Location $projectRoot
    try {
        if ($PSCmdlet.ShouldProcess('PostgreSQL do Docker Compose', 'Parar o servico postgres')) {
            & docker compose stop postgres
            if ($LASTEXITCODE -ne 0) {
                throw 'Falha ao parar o PostgreSQL. O registro foi mantido para nova tentativa.'
            }
        }
        else {
            $actionsPending = $true
        }
    }
    finally {
        Pop-Location
    }
}

if ($WhatIfPreference) {
    Write-Host 'Simulacao concluida; nenhuma sessao foi encerrada.'
    return
}

if ($actionsPending) {
    Write-Warning "Algumas acoes ficaram pendentes. O registro foi mantido em $stateFile"
    return
}

Remove-Item -LiteralPath $stateFile -Force
Write-Host 'Terminais iniciados pelo runner foram encerrados.'
if ($session.StopPostgres) {
    Write-Host 'PostgreSQL iniciado pelo runner foi parado; o volume de dados foi preservado.'
}
else {
    Write-Host 'PostgreSQL ja estava ativo antes da inicializacao e foi mantido em execucao.'
}
