# PCQQ script menu
# Usage: irm pc-qq.net/s | iex
# 追加するときは $items に1行足すだけ

$base = 'https://pc-qq.net/s'

$items = @(
    @{ Name = 'ゲスト共有を有効化 (SMBクライアント側)'; File = 'guest.ps1'; Revert = $false }
    @{ Name = 'ゲスト共有を元に戻す';                   File = 'guest.ps1'; Revert = $true  }
)

while ($true) {
    Clear-Host
    Write-Host '=== PCQQ Script Menu ===' -ForegroundColor Cyan
    for ($i = 0; $i -lt $items.Count; $i++) {
        Write-Host (' {0}. {1}' -f ($i + 1), $items[$i].Name)
    }
    Write-Host ''
    Write-Host ' v+番号: 中身を表示だけ (例: v1)    q: 終了' -ForegroundColor DarkGray
    $sel = Read-Host '番号を選択'
    if ($sel -eq 'q') { break }

    $view = $sel -match '^v'
    $n = ($sel -replace '^v', '') -as [int]
    if (-not $n -or $n -lt 1 -or $n -gt $items.Count) { continue }
    $it = $items[$n - 1]

    try { $code = Invoke-RestMethod "$base/$($it.File)" }
    catch { Write-Host "取得失敗: $($it.File)" -ForegroundColor Red; Read-Host 'Enterで戻る' | Out-Null; continue }

    if ($view) {
        Write-Host $code
    } else {
        $r = if ($it.Revert) { 1 } else { $null }
        & ([scriptblock]::Create($code))
        $r = $null
    }
    Read-Host 'Enterで戻る' | Out-Null
}
