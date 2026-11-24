$ErrorActionPreference = 'Stop'

# Gera docs\Projeto_Voz_UL.docx a partir de tool\conteudo_projeto.md escrevendo
# OOXML directamente. Evita a automação Word (COM), que neste ambiente bloqueia
# de forma imprevisível ao gravar o ficheiro.

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$contentPath = Join-Path $root 'tool\conteudo_projeto.md'
$outDir = Join-Path $root 'docs'
$outPath = Join-Path $outDir 'Projeto_Voz_UL.docx'

if (-not (Test-Path -LiteralPath $contentPath)) { throw "Conteudo ausente: $contentPath" }
if (-not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

# --- Leitura do conteudo -----------------------------------------------------
$cap = [ordered]@{}
$blocks = New-Object System.Collections.ArrayList

foreach ($line in @(Get-Content -LiteralPath $contentPath -Encoding UTF8)) {
    if ($line.Length -eq 0) { continue }
    if ($line -match '^#CAP\|([^|]*)\|(.*)$') { $cap[$matches[1]] = $matches[2]; continue }
    if ($line -eq '#TOC') { [void]$blocks.Add(@{ Tag = '#TOC'; Text = '' }); continue }
    if ($line -match '^#(H1|H2|H3|P|LI)\|(.+)$') {
        [void]$blocks.Add(@{ Tag = ('#' + $matches[1]); Text = $matches[2] })
        continue
    }
    throw "Linha nao reconhecida no conteudo: $line"
}

foreach ($k in @('INSTITUICAO', 'UNIDADE', 'CURSO', 'TITULO', 'AUTOR', 'SUPERVISOR', 'ANO')) {
    if (-not $cap.Contains($k)) { throw "Chave de capa em falta: $k" }
}

# --- Constantes de formato (twips / meios-pontos) ---------------------------
$fontName = 'Times New Roman'
$marginTop = 1417      # 2,5 cm
$marginBottom = 1417   # 2,5 cm
$marginLeft = 1701     # 3,0 cm
$marginRight = 1134    # 2,0 cm
$indentFirstLine = 709 # 1,25 cm
$indentBullet = 709
$line15 = 360          # 1,5 linhas

function XmlEsc([string]$s) {
    if ($null -eq $s) { return '' }
    return $s.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;')
}

function RPr([int]$halfPt, [bool]$bold, [bool]$italic) {
    $x = '<w:rPr><w:rFonts w:ascii="' + $fontName + '" w:hAnsi="' + $fontName + '" w:cs="' + $fontName + '"/>'
    if ($bold) { $x += '<w:b/>' }
    if ($italic) { $x += '<w:i/>' }
    $x += '<w:sz w:val="' + $halfPt + '"/><w:szCs w:val="' + $halfPt + '"/></w:rPr>'
    return $x
}

function Run([string]$text, [int]$halfPt, [bool]$bold, [bool]$italic) {
    return '<w:r>' + (RPr $halfPt $bold $italic) + '<w:t xml:space="preserve">' + (XmlEsc $text) + '</w:t></w:r>'
}

function ParaCentered([string]$text, [int]$halfPt, [bool]$bold, [bool]$italic, [int]$spaceAfter) {
    $p = '<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:after="' + $spaceAfter + '" w:line="240" w:lineRule="auto"/></w:pPr>'
    $p += (Run $text $halfPt $bold $italic)
    return $p + '</w:p>'
}

function ParaEmpty([int]$count) {
    $x = ''
    for ($i = 0; $i -lt $count; $i++) { $x += '<w:p><w:pPr><w:spacing w:line="240" w:lineRule="auto"/></w:pPr></w:p>' }
    return $x
}

function ParaBody([string]$text) {
    $p = '<w:p><w:pPr><w:ind w:firstLine="' + $indentFirstLine + '"/><w:spacing w:after="120" w:line="' + $line15 + '" w:lineRule="auto"/><w:jc w:val="both"/></w:pPr>'
    $p += (Run $text 24 $false $false)
    return $p + '</w:p>'
}

function ParaBullet([string]$text) {
    $p = '<w:p><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="1"/></w:numPr>'
    $p += '<w:ind w:left="' + $indentBullet + '" w:hanging="283"/><w:spacing w:after="80" w:line="' + $line15 + '" w:lineRule="auto"/><w:jc w:val="both"/></w:pPr>'
    $p += (Run $text 24 $false $false)
    return $p + '</w:p>'
}

function ParaHeading([int]$level, [string]$text) {
    $p = '<w:p><w:pPr><w:pStyle w:val="Heading' + $level + '"/></w:pPr>'
    $p += '<w:r><w:t xml:space="preserve">' + (XmlEsc $text) + '</w:t></w:r>'
    return $p + '</w:p>'
}

$pageBreak = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'

$tocField = @'
<w:p><w:pPr><w:spacing w:after="120" w:line="240" w:lineRule="auto"/></w:pPr><w:r><w:fldChar w:fldCharType="begin" w:dirty="true"/></w:r><w:r><w:instrText xml:space="preserve"> TOC \o "1-3" \h \z \u </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:rPr><w:i/><w:sz w:val="20"/></w:rPr><w:t xml:space="preserve">O índice é gerado automaticamente ao abrir o documento. Para o actualizar manualmente, prima Ctrl+A e depois F9.</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p>
'@

# --- Corpo do documento -----------------------------------------------------
$stats = @{ H1 = 0; H2 = 0; H3 = 0; P = 0; LI = 0; TOC = 0 }
$body = New-Object System.Text.StringBuilder

[void]$body.Append((ParaCentered $cap['INSTITUICAO'] 28 $true $false 80))
[void]$body.Append((ParaCentered $cap['UNIDADE'] 26 $false $false 40))
[void]$body.Append((ParaCentered $cap['CURSO'] 26 $false $false 840))
[void]$body.Append((ParaCentered $cap['TITULO'] 40 $true $false 520))
[void]$body.Append((ParaCentered ('Trabalho de projeto apresentado no âmbito do curso de ' + $cap['CURSO']) 22 $false $true 600))
[void]$body.Append((ParaEmpty 2))
[void]$body.Append((ParaCentered ($cap['AUTOR_LABEL'] + ': ' + $cap['AUTOR']) 24 $false $false 80))
[void]$body.Append((ParaCentered ($cap['SUPERVISOR_LABEL'] + ': ' + $cap['SUPERVISOR']) 24 $false $false 600))
[void]$body.Append((ParaEmpty 3))
[void]$body.Append((ParaCentered $cap['ANO'] 24 $false $false 0))
[void]$body.Append($pageBreak)

foreach ($block in $blocks) {
    switch ($block.Tag) {
        '#TOC' {
            # Paragrafo normal (nao um estilo de titulo) para o indice nao se listar a si proprio
            [void]$body.Append((ParaCentered 'Índice' 32 $true $false 280))
            [void]$body.Append($tocField)
            [void]$body.Append($pageBreak)
            $stats.TOC = 1
        }
        '#H1' { [void]$body.Append((ParaHeading 1 $block.Text)); $stats.H1++ }
        '#H2' { [void]$body.Append((ParaHeading 2 $block.Text)); $stats.H2++ }
        '#H3' { [void]$body.Append((ParaHeading 3 $block.Text)); $stats.H3++ }
        '#P'  { [void]$body.Append((ParaBody $block.Text)); $stats.P++ }
        '#LI' { [void]$body.Append((ParaBullet $block.Text)); $stats.LI++ }
    }
}

$sectPr = '<w:sectPr><w:footerReference w:type="default" r:id="rId4"/>' +
          '<w:pgSz w:w="11906" w:h="16838"/>' +
          '<w:pgMar w:top="' + $marginTop + '" w:right="' + $marginRight + '" w:bottom="' + $marginBottom + '" w:left="' + $marginLeft + '" w:header="708" w:footer="708" w:gutter="0"/>' +
          '<w:docGrid w:linePitch="360"/></w:sectPr>'

$documentXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' +
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
    '<w:body>' + $body.ToString() + $sectPr + '</w:body></w:document>'

# --- Partes fixas -----------------------------------------------------------
$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/><Override PartName="/word/footer1.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>
'@

$rootRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/></Relationships>
'@

$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" Target="footer1.xml"/></Relationships>
'@

$settingsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:zoom w:percent="100"/><w:defaultTabStop w:val="709"/><w:updateFields w:val="true"/><w:compat><w:compatSetting w:name="compatibilityMode" w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat></w:settings>
'@

$numberingXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="hybridMultilevel"/><w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="bullet"/><w:lvlText w:val="&#xF0B7;"/><w:lvlJc w:val="left"/><w:pPr><w:ind w:left="709" w:hanging="283"/></w:pPr><w:rPr><w:rFonts w:ascii="Symbol" w:hAnsi="Symbol" w:hint="default"/></w:rPr></w:lvl></w:abstractNum><w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num></w:numbering>
'@

$footerXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:p><w:pPr><w:jc w:val="center"/><w:spacing w:line="240" w:lineRule="auto"/></w:pPr><w:r><w:fldChar w:fldCharType="begin"/></w:r><w:r><w:instrText xml:space="preserve"> PAGE </w:instrText></w:r><w:r><w:fldChar w:fldCharType="separate"/></w:r><w:r><w:rPr><w:sz w:val="20"/></w:rPr><w:t>1</w:t></w:r><w:r><w:fldChar w:fldCharType="end"/></w:r></w:p></w:ftr>
'@

function StyleHeading([int]$level, [int]$halfPt, [int]$spaceBefore, [int]$spaceAfter, [bool]$italic) {
    $x = '<w:style w:type="paragraph" w:styleId="Heading' + $level + '"><w:name w:val="heading ' + $level + '"/>'
    $x += '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/>'
    $x += '<w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="' + $spaceBefore + '" w:after="' + $spaceAfter + '" w:line="240" w:lineRule="auto"/><w:outlineLvl w:val="' + ($level - 1) + '"/></w:pPr>'
    $x += '<w:rPr><w:rFonts w:ascii="' + $fontName + '" w:hAnsi="' + $fontName + '" w:cs="' + $fontName + '"/>'
    $x += '<w:b/>'
    if ($italic) { $x += '<w:i/>' }
    $x += '<w:sz w:val="' + $halfPt + '"/><w:szCs w:val="' + $halfPt + '"/></w:rPr></w:style>'
    return $x
}

function StyleToc([int]$level, [int]$indent) {
    $x = '<w:style w:type="paragraph" w:styleId="TOC' + $level + '"><w:name w:val="toc ' + $level + '"/>'
    $x += '<w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:uiPriority w:val="39"/>'
    $x += '<w:pPr><w:ind w:left="' + $indent + '"/><w:spacing w:after="60" w:line="240" w:lineRule="auto"/><w:tabs><w:tab w:val="right" w:leader="dot" w:pos="9070"/></w:tabs></w:pPr>'
    $x += '<w:rPr><w:rFonts w:ascii="' + $fontName + '" w:hAnsi="' + $fontName + '"/><w:sz w:val="24"/></w:rPr></w:style>'
    return $x
}

$stylesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
    '<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="' + $fontName + '" w:hAnsi="' + $fontName + '" w:cs="' + $fontName + '"/><w:sz w:val="24"/><w:szCs w:val="24"/><w:lang w:val="pt-PT"/></w:rPr></w:rPrDefault>' +
    '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="' + $line15 + '" w:lineRule="auto"/><w:jc w:val="both"/></w:pPr></w:pPrDefault></w:docDefaults>' +
    '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>' +
    (StyleHeading 1 32 400 240 $false) +
    (StyleHeading 2 26 280 160 $false) +
    (StyleHeading 3 24 240 120 $true) +
    (StyleToc 1 0) +
    (StyleToc 2 220) +
    (StyleToc 3 440) +
    '<w:style w:type="character" w:styleId="Hyperlink"><w:name w:val="Hyperlink"/><w:rPr><w:color w:val="0563C1"/><w:u w:val="single"/></w:rPr></w:style>' +
    '</w:styles>'

$nowIso = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$coreXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
    'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" ' +
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
    '<dc:title>' + (XmlEsc $cap['TITULO']) + '</dc:title>' +
    '<dc:subject>' + (XmlEsc ($cap['CURSO'] + ' - ' + $cap['UNIDADE'])) + '</dc:subject>' +
    '<dc:creator>' + (XmlEsc $cap['AUTOR']) + '</dc:creator>' +
    '<cp:lastModifiedBy>' + (XmlEsc $cap['AUTOR']) + '</cp:lastModifiedBy>' +
    '<dcterms:created xsi:type="dcterms:W3CDTF">' + $nowIso + '</dcterms:created>' +
    '<dcterms:modified xsi:type="dcterms:W3CDTF">' + $nowIso + '</dcterms:modified>' +
    '</cp:coreProperties>'

$appXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes"><Application>VozUL build tool</Application></Properties>
'@

# --- Escrita do pacote ------------------------------------------------------
Add-Type -AssemblyName System.IO.Compression | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null

$parts = [ordered]@{
    '[Content_Types].xml'          = $contentTypes
    '_rels/.rels'                  = $rootRels
    'docProps/core.xml'            = $coreXml
    'docProps/app.xml'             = $appXml
    'word/document.xml'            = $documentXml
    'word/_rels/document.xml.rels' = $docRels
    'word/styles.xml'              = $stylesXml
    'word/settings.xml'            = $settingsXml
    'word/numbering.xml'           = $numberingXml
    'word/footer1.xml'             = $footerXml
}

# Validar cada parte como XML antes de compactar
foreach ($k in $parts.Keys) {
    try { [xml]$null = $parts[$k] }
    catch { throw "XML invalido em ${k}: $($_.Exception.Message)" }
}

if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }

$zip = [System.IO.Compression.ZipFile]::Open($outPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($k in $parts.Keys) {
        $entry = $zip.CreateEntry($k, [System.IO.Compression.CompressionLevel]::Optimal)
        $stream = $entry.Open()
        $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($parts[$k])
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Dispose()
    }
}
finally {
    $zip.Dispose()
}

$file = Get-Item -LiteralPath $outPath
Write-Output "DOC_OK $($file.FullName)"
Write-Output ("TOC=" + $stats.TOC + " H1=" + $stats.H1 + " H2=" + $stats.H2 + " H3=" + $stats.H3 + " P=" + $stats.P + " LI=" + $stats.LI)
Write-Output ("Bytes=" + $file.Length)