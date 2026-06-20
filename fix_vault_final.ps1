$ErrorActionPreference = 'Stop'
$vaultPath = "C:\Obsidian\ai-assistent"

$replacements = [ordered]@{
    "cao"         = "cao"
    "ao"          = "ao"
    "Conteudo"    = "Conteudo"
}
$count = 0
$files = Get-ChildItem -Path $vaultPath -Recurse -Filter "*.md"
Write-Host "Processando $($files.Count) arquivos..." -ForegroundColor Cyan
foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    $modified = $false
    if ([string]::IsNullOrWhiteSpace($content) -or $content.Length -lt 50) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $content = @"
---
type: knowledge
domain: general
status: active
---
# $name
*Subtitle*
> Documentacao inicial de $name.
## Parent
- [[index]]
## Children
## Related
## Tags
#kaos
---
## Conteudo
"@
        $modified = $true
        Write-Host "  Template injetado em: $($file.Name)" -ForegroundColor Yellow
    }
    $content = $content -replace "Conte\xC3\xBAdo", "Conteudo"
    $content = $content -replace "\xC3\xA3", "ao"
    $content = $content -replace "\xC3\xBA", "u"
    $content = $content -replace "\xC3\xB3", "o"
    $content = $content -replace "\xC3\xA9", "e"
    $content = $content -replace "\xC3\xAD", "i"
    $content = $content -replace "\xC3\xA7", "c"
    $content = $content -replace "Ingest\xC3\xA3o", "Ingestao"
    $content = $content -replace "Propaga\xC3\xA7\xC3\xA3o", "Propagacao"
    $content = $content -replace "Configura\xC3\xA7\xC3\xA3o", "Configuracao"
    $content = $content -replace "Configura\xC3\xA7\xC3\xB5es", "Configuracoes"
    $content = $content -replace "Otimiza\xC3\xA7\xC3\xA3o", "Otimizacao"
    $content = $content -replace "Funda\xC3\xA7\xC3\xA3o", "Fundacao"
    $content = $content -replace "Inten\xC3\xA7\xC3\xB5es", "Intencoes"
    $content = $content -replace "Integra\xC3\xA7\xC3\xB5es", "Integracoes"
    $content = $content -replace "Sem\xC3\xA2ntico", "Semantico" 
    $content = $content -replace "Especifica\xC3\xA7\xC3\xA3o", "Especificacao"
    $content = $content -replace "Especifica\xC3\xA7\xC3\xB5es", "Especificacoes"
    $content = $content -replace "T\xC3\xA9cnica", "Tecnica"
    $content = $content -replace "Mem\xC3\xB3ria", "Memoria"
    $content = $content -replace "Inten\xC3\xA7\xC3\xB5es", "Intencoes"
    $content = $content -replace "Vis\xC3\xA3o", "Visao"
    $content = $content -replace "\xC3\x89", "E"
    $content = $content -replace "\xC3\x93", "O"
    $content = $content -replace "\xC3\x8D", "I"
    $content = $content -replace "\xC3\x81", "A"
    if ($content -ne (Get-Content -Path $file.FullName -Raw -Encoding UTF8)) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8
        Write-Host "  Corrigido: $($file.Name)" -ForegroundColor Green
        $count++
    }
}
Write-Host "Concluido! $count arquivos corrigidos." -ForegroundColor Cyan
