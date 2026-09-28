param(
    [int]$Interval = 20
)

$repo = git rev-parse --show-toplevel
if ($LASTEXITCODE -ne 0) {
    Write-Host "当前目录不是 Git 仓库" -ForegroundColor Red
    exit 1
}
Set-Location $repo

while ($true) {
    Clear-Host

    Write-Host "Git 文件修改监控" -ForegroundColor Cyan
    Write-Host "项目：$repo"
    Write-Host "时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "------------------------------"

    $files = @(git status --short --untracked-files=all)

    if ($files.Count -eq 0) {
        Write-Host "没有修改" -ForegroundColor Green
    }
    else {
        foreach ($file in $files) {
            $status = $file.Substring(0, 2).Trim()
            $name = $file.Substring(3)

            $color = switch -Regex ($status) {
                'D' { 'Red'; break }
                'A|\?' { 'Green'; break }
                default { 'Yellow' }
            }

            Write-Host "$status  $name" -ForegroundColor $color
        }
    }

    Write-Host "`n每 $Interval 秒刷新一次，按 Ctrl+C 退出" -ForegroundColor DarkGray
    Start-Sleep -Seconds $Interval
}