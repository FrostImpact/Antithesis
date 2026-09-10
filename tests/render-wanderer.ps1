$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    node tests/render-wanderer.cjs --polygons
    if ($LASTEXITCODE -ne 0) { throw 'Model render failed' }
    Add-Type -AssemblyName System.Drawing
    $canvas = New-Object System.Drawing.Bitmap 1240,560
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::FromArgb(19,23,28))
    $polygons = Get-Content -LiteralPath 'docs/wanderer-preview-polygons.json' -Raw | ConvertFrom-Json
    foreach ($polygon in $polygons) {
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($polygon.colour[0],$polygon.colour[1],$polygon.colour[2]))
        $vertices = [System.Drawing.PointF[]]@($polygon.points | ForEach-Object {New-Object System.Drawing.PointF ([single]$_[0]),([single]$_[1])})
        $graphics.FillPolygon($brush,$vertices)
        $brush.Dispose()
    }
    $font = New-Object System.Drawing.Font 'Arial',16
    $graphics.DrawString('WANDERER / REFERENCE MODEL STUDY',$font,[System.Drawing.Brushes]::Ivory,32,20)
    $graphics.DrawString('REST',$font,[System.Drawing.Brushes]::Ivory,100,510)
    $graphics.DrawString('EXECUTION',$font,[System.Drawing.Brushes]::Ivory,520,510)
    $graphics.DrawString('REAR',$font,[System.Drawing.Brushes]::Ivory,920,510)
    $canvas.Save((Join-Path (Get-Location) 'docs/wanderer-design.png'))
    $graphics.Dispose()
    $canvas.Dispose()
    $font.Dispose()
    Remove-Item -LiteralPath 'docs/wanderer-preview-polygons.json'
} finally { Pop-Location }
