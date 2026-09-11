$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    node tests/render-blanks.cjs
    if ($LASTEXITCODE -ne 0) { throw 'Blank preview failed' }
    Add-Type -AssemblyName System.Drawing
    $canvas = [System.Drawing.Bitmap]::FromFile((Join-Path (Get-Location) '.build/blanks-unlabelled.png'))
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $font = New-Object System.Drawing.Font 'Arial',14
    $graphics.DrawString('BLANKS / VOID FRAGMENTS',$font,[System.Drawing.Brushes]::Black,30,20)
    $graphics.DrawString('WISP / QUICK',$font,[System.Drawing.Brushes]::Black,100,48)
    $graphics.DrawString('HUSK / BASELINE',$font,[System.Drawing.Brushes]::Black,430,48)
    $graphics.DrawString('HULK / HEAVY',$font,[System.Drawing.Brushes]::Black,760,48)
    $graphics.DrawString('VOID FRAGMENTS / LIGHTWEIGHT HOVER ANIMATION',$font,[System.Drawing.Brushes]::Black,30,632)
    $canvas.Save((Join-Path (Get-Location) 'docs/blanks.png'))
    $graphics.Dispose()
    $canvas.Dispose()
    $font.Dispose()
} finally { Pop-Location }
