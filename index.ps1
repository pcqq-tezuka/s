# PCQQ script menu
# Usage: irm pc-qq.net/s | iex
# 一覧は list.json で管理（Webページ pc-qq.net/cmd/ と共通）

$base = 'https://pc-qq.net/s'

try {
    $json = Invoke-RestMethod "$base/list.json"
    if ($json -is [string]) { $json = $json | ConvertFrom-Json }
    $items = @($json | ForEach-Object { $_ })
} catch {
    Write-Host 'list.json の取得に失敗しました' -ForegroundColor Red
    return
}

while ($true) {
    Clear-Host
    Write-Host '=== PCQQ Script Menu ===' -ForegroundColor Cyan
    for ($i = 0; $i -lt $items.Count; $i++) {
        Write-Host (' {0}. {1}' -f ($i + 1), $items[$i].name)
    }
    Write-Host ''
    Write-Host ' v+番号: 中身を表示だけ (例: v1)    q: 終了' -ForegroundColor DarkGray
    $sel = Read-Host '番号を選択'
    if ($sel -eq 'q') { break }

    $view = $sel -match '^v'
    $n = ($sel -replace '^v', '') -as [int]
    if (-not $n -or $n -lt 1 -or $n -gt $items.Count) { continue }
    $it = $items[$n - 1]

    try { $code = Invoke-RestMethod "$base/$($it.file)" }
    catch { Write-Host "取得失敗: $($it.file)" -ForegroundColor Red; Read-Host 'Enterで戻る' | Out-Null; continue }

    if ($view) {
        Write-Host $code
    } else {
        $r = if ($it.revert) { 1 } else { $null }
        & ([scriptblock]::Create($code))
        $r = $null
    }
    Read-Host 'Enterで戻る' | Out-Null
}
