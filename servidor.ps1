# Servidor local para instalar Diana Score en el ordenador (Chrome o Edge).
# Sirve los archivos de esta misma carpeta en http://localhost, lo que permite
# instalar la app y usarla sin conexion. Para parar: cierra esta ventana.

$ErrorActionPreference = 'Stop'
$raiz = [System.IO.Path]::GetFullPath($PSScriptRoot)
if (-not $raiz.EndsWith('\')) { $raiz = $raiz + '\' }

$tipos = @{
  '.html'='text/html; charset=utf-8'; '.js'='text/javascript; charset=utf-8'
  '.css'='text/css; charset=utf-8'; '.json'='application/json; charset=utf-8'
  '.webmanifest'='application/manifest+json; charset=utf-8'
  '.svg'='image/svg+xml'; '.png'='image/png'; '.ico'='image/x-icon'; '.txt'='text/plain; charset=utf-8'
}

$escucha = $null
foreach ($p in 8411..8430) {
  $l = New-Object System.Net.HttpListener
  $l.Prefixes.Add("http://localhost:$p/")
  try { $l.Start(); $escucha = $l; $puerto = $p; break } catch { $l.Close() }
}
if (-not $escucha) { Write-Host 'No se encontro un puerto libre (8411-8430).' -ForegroundColor Red; Read-Host 'Pulsa Intro'; exit 1 }

$url = "http://localhost:$puerto/"
Write-Host ''
Write-Host '  Diana Score - servidor local' -ForegroundColor Cyan
Write-Host "  Abierta en: $url" -ForegroundColor Green
Write-Host '  Para INSTALARLA en el ordenador: en Chrome o Edge, pulsa el icono de'
Write-Host '  instalar que aparece a la derecha de la barra de direcciones (un monitor'
Write-Host '  con una flecha), o menu > Instalar Diana Score. Quedara como app y'
Write-Host '  funcionara sin conexion.'
Write-Host '  Para parar el servidor, cierra esta ventana.'
Write-Host ''
Start-Process $url

$indice = Join-Path $raiz 'index.html'
while ($escucha.IsListening) {
  try { $ctx = $escucha.GetContext() } catch { break }
  $res = $ctx.Response
  try {
    $ruta = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath).TrimStart('/').Replace('/', '\')
    $fich = [System.IO.Path]::GetFullPath((Join-Path $raiz $ruta))
    $ok = $true
    if (-not $fich.StartsWith($raiz, [System.StringComparison]::OrdinalIgnoreCase)) { $res.StatusCode = 403; $ok = $false }
    elseif (-not (Test-Path -LiteralPath $fich -PathType Leaf)) {
      if ([System.IO.Path]::GetExtension($ruta)) { $res.StatusCode = 404; $ok = $false } else { $fich = $indice }
    }
    if ($ok) {
      $bytes = [System.IO.File]::ReadAllBytes($fich)
      $ext = [System.IO.Path]::GetExtension($fich).ToLower()
      $tipo = $tipos[$ext]; if (-not $tipo) { $tipo = 'application/octet-stream' }
      $res.ContentType = $tipo
      $res.Headers.Add('Service-Worker-Allowed', '/')
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    }
  } catch { try { $res.StatusCode = 500 } catch {} }
  finally { try { $res.Close() } catch {} }
}
