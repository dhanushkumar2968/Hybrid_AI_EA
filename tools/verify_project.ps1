$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    'MQL5\Experts\XAUUSD_Hybrid_AI_EA.mq5',
    'MQL5\Experts\LegacyAnalysisAdapter.mqh',
    'MQL5\Experts\MTFTrendAnalysis.mqh',
    'MQL5\Experts\D1Analysis.mqh',
    'MQL5\Experts\M30_Analysis.mqh',
    'MQL5\Include\XAUUSDHybrid\AIClient.mqh',
    'MQL5\Include\XAUUSDHybrid\ExecutionEngine.mqh',
    'python\hybrid_ai\service.py',
    'python\training\train_model.py'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf)) {
        throw "Required project file is missing: $relative"
    }
}
Write-Output 'PASS required project files exist'

$sources = Get-ChildItem -LiteralPath (Join-Path $root 'MQL5') -Recurse -File |
    Where-Object { $_.Extension -in @('.mq5', '.mqh') }
foreach ($source in $sources) {
    $includes = Select-String -LiteralPath $source.FullName -Pattern '^\s*#include\s+"([^"]+)"' -AllMatches
    foreach ($match in $includes.Matches) {
        $includePath = $match.Groups[1].Value.Replace('/', '\')
        $resolved = [IO.Path]::GetFullPath((Join-Path $source.DirectoryName $includePath))
        if (-not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
            throw "Unresolved project-local include in $($source.Name): $includePath"
        }
    }
}
Write-Output 'PASS all quoted MQL5 includes resolve inside the project'

$mainPath = Join-Path $root 'MQL5\Experts\XAUUSD_Hybrid_AI_EA.mq5'
$main = Get-Content -LiteralPath $mainPath -Raw
foreach ($setting in @(
    'BOT_ENABLED=false',
    'ANALYSIS_ENABLED=true',
    'AI_ENABLED=false',
    'DRAWINGS_ENABLED=true',
    'TRADING_PERMISSION=false',
    'LIVE_EXECUTION=false'
)) {
    if ($main -notmatch [regex]::Escape($setting)) {
        throw "Required safe default is missing: $setting"
    }
}
Write-Output 'PASS required order-safety defaults are present'

$tradeSources = @($sources | Select-String -Pattern '\bCTrade\b' | ForEach-Object { $_.Path } | Sort-Object -Unique)
$expectedTradeSource = [IO.Path]::GetFullPath((Join-Path $root 'MQL5\Include\XAUUSDHybrid\ExecutionEngine.mqh'))
if ($tradeSources.Count -ne 1 -or $tradeSources[0] -ne $expectedTradeSource) {
    throw "CTrade must remain isolated to ExecutionEngine.mqh; found: $($tradeSources -join ', ')"
}
Write-Output 'PASS CTrade is isolated to ExecutionEngine.mqh'

$logPath = Join-Path $root 'mql5_compile.log'
$artifactPath = Join-Path $root 'MQL5\Experts\XAUUSD_Hybrid_AI_EA.ex5'
if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf) -or
    (Get-Item -LiteralPath $artifactPath).Length -le 0) {
    throw 'MetaEditor did not produce a non-empty EA artifact.'
}
if (-not (Select-String -LiteralPath $logPath -Pattern '^Result: 0 errors, 0 warnings' -Quiet)) {
    throw 'Latest MetaEditor log does not confirm a clean compile.'
}
Write-Output 'PASS compiled EA artifact and clean MetaEditor result are present'
