# PowerShell version of compress-videos.sh, for running in the terminal you
# already have open. Same settings, same outputs.
#
#   winget install Gyan.FFmpeg     # once, then open a NEW terminal
#   .\compress-videos.ps1          # from the project root
#
# Settings, and why:
#   -t 9              nothing plays longer than nine seconds. Only the fluid
#                     clip is affected; the rest are 4.2 to 8.3s already.
#   scale=1080:-2     the panel is 600 CSS px wide, so 1080 covers a 2x
#                     display. Three sources are already 1080 and pass
#                     through; the two 4K ones halve.
#   -crf 20           visually transparent at this display size. Lower this
#                     to 18 if anything still looks soft.
#   -preset veryslow  spends encoder time to hit that quality in fewer bits.
#                     Costs minutes here, nothing at playback.
#   -an               drops audio. They play muted, so it is waste.
#   +faststart        playback can begin before the download finishes.

$ErrorActionPreference = 'Continue'

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host "ffmpeg not found on PATH." -ForegroundColor Red
    Write-Host "  winget install Gyan.FFmpeg"
    Write-Host "  then close this terminal, open a new one, and re-run."
    Write-Host ""
    Write-Host "PATH changes do not reach a terminal that was already open -" -ForegroundColor Yellow
    Write-Host "that is the step this usually trips on." -ForegroundColor Yellow
    exit 1
}

$jobs = @(
    @{ src = 'assets/dna2.mp4';                out = 'assets/dna-bg.mp4' },
    @{ src = 'assets/neuralode-video2.mp4';    out = 'assets/neuralode-bg.mp4' },
    @{ src = 'assets/sleepatlas-video2.mp4';   out = 'assets/sleepatlas-bg.mp4' },
    @{ src = 'assets/fluidsr-video2.mp4';      out = 'assets/fluidsr-bg.mp4' },
    @{ src = 'assets/heliostream-video2.mp4';  out = 'assets/heliostream-bg.mp4' }
)

$totalIn = 0
$totalOut = 0
$failed = 0

foreach ($j in $jobs) {
    if (-not (Test-Path $j.src)) {
        Write-Host ("skip: {0} not found" -f $j.src) -ForegroundColor Yellow
        continue
    }
    $name = Split-Path $j.src -Leaf
    Write-Host ("{0,-28} -> {1,-24} " -f $name, (Split-Path $j.out -Leaf)) -NoNewline

    ffmpeg -y -loglevel error -i $j.src `
        -t 9 -vf "scale=1080:-2" `
        -c:v libx264 -crf 20 -preset veryslow -profile:v high -pix_fmt yuv420p `
        -movflags +faststart -an $j.out

    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $j.out)) {
        Write-Host "FAILED" -ForegroundColor Red
        $failed++
        continue
    }
    $a = (Get-Item $j.src).Length
    $b = (Get-Item $j.out).Length
    $totalIn += $a
    $totalOut += $b
    Write-Host ("{0,7:N1} MB -> {1,6:N2} MB  ({2:N0}x)" -f ($a/1MB), ($b/1MB), ($a/$b)) -ForegroundColor Green
}

Write-Host ""
if ($totalIn -gt 0) {
    Write-Host ("TOTAL  {0:N1} MB -> {1:N2} MB" -f ($totalIn/1MB), ($totalOut/1MB)) -ForegroundColor Cyan
}
if ($failed -gt 0) { Write-Host ("{0} file(s) failed." -f $failed) -ForegroundColor Red }
Write-Host ""
Write-Host "If any clip looks soft, change -crf 20 to -crf 18 and re-run."
Write-Host "Then point the five VID constants in index.html at the new -bg.mp4 files."
