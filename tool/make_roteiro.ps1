$ErrorActionPreference = 'Stop'
$outPath = 'C:\Users\Keide Zecas\StudioProjects\voz_ul\Roteiro_Apresentacao_VozUL.docx'

$word = New-Object -ComObject Word.Application
$word.Visible = $false
$doc = $word.Documents.Add()
$sel = $word.Selection

function Reset-Font($size = 11, $bold = $false, $italic = $false) {
    $sel.Font.Size = $size
    $sel.Font.Bold = $bold
    $sel.Font.Italic = $italic
}

function Type-Line($text) {
    $sel.TypeText($text)
    $sel.TypeParagraph()
}

function Add-Para($text) {
    Reset-Font 11 $false $false
    $sel.ParagraphFormat.LeftIndent = 0
    $sel.ParagraphFormat.SpaceAfter = 6
    Type-Line $text
}

function Add-Empty {
    Reset-Font 11 $false $false
    $sel.ParagraphFormat.SpaceAfter = 6
    $sel.TypeParagraph()
}

function Add-Head1($text) {
    Reset-Font 16 $true $false
    $sel.ParagraphFormat.SpaceBefore = 18
    $sel.ParagraphFormat.SpaceAfter = 8
    Type-Line $text
}

function Add-Head2($text) {
    Reset-Font 13 $true $true
    $sel.ParagraphFormat.SpaceBefore = 12
    $sel.ParagraphFormat.SpaceAfter = 6
    Type-Line $text
}

function Add-Bullet($text) {
    Reset-Font 11 $false $false
    $sel.ParagraphFormat.LeftIndent = 0
    $sel.Range.ListFormat.ApplyBulletDefault() | Out-Null
    Type-Line $text
    $sel.Range.ListFormat.RemoveNumbers(1) | Out-Null
    $sel.ParagraphFormat.LeftIndent = 0
}

function Add-NumItem($text) {
    Reset-Font 11 $false $false
    $sel.ParagraphFormat.LeftIndent = 0
    $sel.Range.ListFormat.ApplyNumberDefault() | Out-Null
    Type-Line $text
    $sel.ParagraphFormat.LeftIndent = 0
}

function Add-Table($rows) {
    $n = $rows.Count
    $cols = $rows[0].Count
    $tbl = $doc.Tables.Add($sel.Range, $n, $cols)
    try { $tbl.Borders.Enable = $true } catch { }
    for ($r = 0; $r -lt $n; $r++) {
        for ($c = 0; $c -lt $cols; $c++) {
            $tbl.Cell($r + 1, $c + 1).Range.Text = [string]$rows[$r][$c]
        }
    }
    $sel.EndKey(6) | Out-Null
    Reset-Font 11 $false $false
    $sel.ParagraphFormat.LeftIndent = 0
    $sel.TypeParagraph()
}

# Margens
$cm = 1.8
$doc.PageSetup.TopMargin = $cm * 28.35
$doc.PageSetup.BottomMargin = $cm * 28.35
$doc.PageSetup.LeftMargin = $cm * 28.35
$doc.PageSetup.RightMargin = $cm * 28.35

# Titulo
Reset-Font 26 $true $false
$sel.ParagraphFormat.SpaceAfter = 4
Type-Line 'VozUL - Roteiro de Apresentação'
Reset-Font 12 $false $true
$sel.ParagraphFormat.SpaceAfter = 18
Type-Line 'Jornadas Científicas - Exposição e Demonstração de Projetos  |  Universidade Licungo (Quelimane)'

# 1. Ficha do projeto
Add-Head1 '1. Ficha do projeto'
Add-Table @(
    @('Parâmetro', 'Descrição'),
    @('Nome', 'VozUL - A voz da Universidade Licungo'),
    @('Tipo', 'Aplicação móvel (Android) + painel de gestão web'),
    @('Objetivo', 'Canal seguro, fácil e anónimo de denúncias na comunidade académica'),
    @('Público', 'Estudantes (denunciantes) e Comissão de disciplina / Coordenação (gestores)'),
    @('Tecnologias', 'Flutter (app), Supabase (nuvem e base de dados), Edge Functions'),
    @('Notificações', 'SMS aos gestores (Infobip) e email ao estudante (Resend)'),
    @('Estado', 'Funcional - demo com fluxos reais testados')
)

# 2. Roteiro passo a passo
Add-Head1 '2. Roteiro passo a passo (12-15 minutos)'
Add-Table @(
    @('Momento', 'Tempo', 'Cena / ecrã', 'O que dizer'),
    @('Abertura', '1 min', 'Slide / cartaz com logótipo', 'Saudação, nome do projeto e, em 1 frase, o problema que resolve.'),
    @('Problema', '2 min', 'Slide do problema', 'Medo de denunciar, risco de retaliação, processos em papel, sem acompanhamento.'),
    @('Solução VozUL', '2 min', 'App no telemóvel', 'App gratuita: denúncia anónima (sem nome) ou identificada, com código para acompanhar.'),
    @('Demonstração', '5-6 min', 'Telemóvel projetado + painel web', '1 denúncia anónima de exemplo, código gerado, separador Acompanhar, receção no painel, chat e mudança de estado.'),
    @('Tecnologia e segurança', '2 min', 'Painel admin + base', 'Dados na nuvem (Supabase), alertas por SMS/email, código separa a identidade da denúncia.'),
    @('Impacto / próximos passos', '1 min', 'Slide final', 'Menos retaliação, mais resolução; expansão a outras faculdades.'),
    @('Perguntas e respostas', '3 min', 'Todos', 'Ver secção 6 com respostas prontas.')
)

# 3. Guião de abertura
Add-Head1 '3. Guião de abertura (para ler)'
Add-Para 'Bom dia. O projeto chama-se VozUL - a voz da Universidade Licungo. É uma aplicação móvel que permite que qualquer estudante denuncie faltas, assédio, corrupção ou problemas de segurança dentro da universidade, de forma segura e podendo fazê-lo totalmente anónimo.'
Add-Para 'O problema é conhecido: muita gente sabe de situações irregulares mas não denuncia por medo de represálias. E quem denuncia não tem forma de acompanhar se a sua denúncia foi tratada. A VozUL resolve os dois lados: o estudante ganha um código secreto para acompanhar e o gestor recebe o alerta na hora, podendo responder e resolver.'
Add-Para 'Vou agora mostrar como funciona, do registo da denúncia até à resposta dos gestores.'

# 4. Demonstração
Add-Head1 '4. Roteiro da demonstração'
Add-NumItem 'Abrir a app no telemóvel e mostrar o ecrã de login/cadastro (entrar como estudante de demonstração).'
Add-NumItem 'Entrar em Nova Denúncia: escolher anónima, selecionar a categoria (ex.: assédio), a faculdade, o local e escrever a descrição. Mostrar que o campo de nome fica vazio no modo anónimo.'
Add-NumItem 'Opção extra: deixar um email para receber notificações (sem ser obrigatório, preserva o anonimato).'
Add-NumItem 'Submeter: aparece o código UNI-XXXXX. Explicar a importância: é com ele que se acompanha, e não guarda nome nem telefone.'
Add-NumItem 'Abrir o separador Acompanhar: mostrar que o código ficou guardado automaticamente (denúncias anónimas guardadas).'
Add-NumItem 'Mudar para o painel de gestão (computador): a denúncia aparece na lista; abrir o detalhe e ler a mensagem.'
Add-NumItem 'Mostrar o chat: o gestor responde uma pergunta; voltar ao telemóvel e mostrar a resposta.'
Add-NumItem 'Mudar o estado para "Em análise" ou "Resolvida": mostrar a notificação por email que chega ao estudante (usar o email opcional).'
Add-NumItem 'Fechar com o painel de relatórios: número de denúncias por categoria e por estado, para o gestor tomar decisões.'

# 5. Mensagens-chave
Add-Head1 '5. Mensagens-chave'
Add-Bullet 'Anonimato real: o código separa a denúncia da identidade; não há nome, email nem telefone obrigatórios.'
Add-Bullet 'Acompanhamento: o estudante sabe, a cada momento, o estado da sua denúncia - sem criar conta.'
Add-Bullet 'Resposta rápida: o gestor recebe o alerta por SMS ao abrir a denúncia; o estudante é avisado por email.'
Add-Bullet 'Simples de expandir: a mesma base serve todas as faculdades da Universidade Licungo.'
Add-Empty

# 6. FAQ
Add-Head1 '6. Perguntas frequentes (preparação)'
Add-Table @(
    @('Pergunta', 'Resposta'),
    @('O anonimato é mesmo garantido?', 'Sim. No modo anónimo só fica o código; nem os gestores veem a identidade.'),
    @('Como acompanho a denúncia sem conta?', 'Com o código UNI-XXXXX, na aba Acompanhar. O código fica guardado no telemóvel.'),
    @('Onde ficam armazenados os dados?', 'Na nuvem Supabase, com acesso protegido por permissões (regras de segurança).'),
    @('Quem recebe a denúncia?', 'Só gestores autorizados, filtrados por faculdade e nível de acesso.'),
    @('Quanto custa?', 'A app é gratuita; os alertas SMS têm um custo mínimo por mensagem; o email é gratuito.'),
    @('Funciona noutras universidades?', 'Sim. A plataforma é configurável por instituição, faculdade e categorias.'),
    @('E se perder o código?', 'No modo anónimo não há recuperação (por segurança); anote-o ou guarde-o no separador Acompanhar.'),
    @('Porquê app móvel e não só web?', 'Acesso imediato, no local dos factos, com privacidade e facilidade de uso.'),
    @('Há custos escondidos?', 'Não. As notificações são controladas e o custo do SMS é transparente e mínimo.')
)

# 7. QR Code
Add-Head1 '7. Distribuição da app - é possível gerar um QR Code de download?'
Add-Para 'Sim, é possível - e é o método recomendado para as Jornadas. As pessoas escaneiam o QR code com a câmara do Android e o APK é descarregado no telemóvel delas, sem precisares de o enviar uma a uma. Passos:'
Add-NumItem 'Fazer upload do ficheiro APK (build\app\outputs\flutter-apk\app-release.apk, cerca de 56 MB) para o Google Drive (ou Dropbox / GitHub Releases).'
Add-NumItem 'No Drive: partilhar como "Qualquer pessoa com o link", com permissão de descarga. O link direto fica com o formato https://drive.google.com/uc?export=download&id=ID_DO_ARQUIVO.'
Add-NumItem 'Gerar um QR Code gratuito com esse link (qr-code-generator.com, canva.com ou semelhante) e imprimir num cartaz/cartão para o estande.'
Add-NumItem 'Sugestão técnica para gerar a imagem via API: https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=LINK_DO_APK'
Add-Empty
Add-Head2 'Avisos importantes para o visitante'
Add-Bullet 'O Android pede autorização para instalar aplicações de "origens desconhecidas" - basta aceitar (ativar a instalação de fontes desconhecidas para o navegador).'
Add-Bullet 'A app precisa de internet (nuvem Supabase) para funcionar; na demonstração usar dados móveis ou Wi-Fi.'
Add-Bullet 'O APK é uma instalação independente (release), sem conta especial para o público.'
Add-Empty
Add-Head2 'Opcional para um aspeto mais profissional'
Add-Bullet 'Colocar o APK nos GitHub Releases do projeto: gera uma página pública de descarga com QR automático.'
Add-Bullet 'Criar um cartão A6 com o QR + logótipo + frase de impacto, para distribuir nas Jornadas.'
Add-Empty
Add-Para 'Nota: o tempo e os exemplos podem ser ajustados ao número de minutos atribuído pela comissão organizadora.'

try {
    try {
        $props = $doc.BuiltInDocumentProperties
        $props.Item('Title').Value = 'VozUL - Roteiro de Apresentação (Jornadas Científicas)'
        $props.Item('Subject').Value = 'Roteiro para exposição/demonstração do APK'
    } catch { }

    $doc.SaveAs($outPath, 16)
} finally {
    $doc.Close($false) | Out-Null
    $word.Quit() | Out-Null
}

[System.Runtime.InteropServices.Marshal]::ReleaseComObject($sel) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($doc) | Out-Null
[System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null

Write-Output "DOC_OK $outPath"