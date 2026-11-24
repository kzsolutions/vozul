import { useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Loader2, Printer, Table } from 'lucide-react'
import { toast } from 'sonner'
import * as XLSX from 'xlsx'
import {
  Button,
  Card,
  CardContent,
  Input,
  Label,
  Separator,
  Skeleton,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  StatusBadge,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { registrarAcesso } from '../../lib/api/historico'
import { listarDenunciasParaRelatorio } from '../../lib/api/denuncias'
import { CATEGORIAS_DENUNCIA, FACULDADES, STATUS_DENUNCIA } from '../../lib/constants'
import { formatarData, formatarDataHora } from '../../lib/format'

export function RelatoriosScreen() {
  const { visaoGlobal, profile } = useAuth()
  const [de, setDe] = useState('')
  const [ate, setAte] = useState('')
  const [faculdade, setFaculdade] = useState<string | null>(null)
  const [status, setStatus] = useState<string | null>(null)
  const [categoria, setCategoria] = useState<string | null>(null)

  const { data, isLoading, refetch, isFetching } = useQuery({
    queryKey: ['relatorio', de, ate, faculdade, status, categoria],
    queryFn: () =>
      listarDenunciasParaRelatorio({
        de: de || null,
        ate: ate || null,
        faculdade: visaoGlobal ? faculdade : null,
        status,
        categoria,
      }),
  })

  const exportarXLSX = () => {
    if (!data || data.length === 0) {
      toast.info('Sem dados para exportar')
      return
    }
    const rows = data.map((d) => ({
      Código: d.codigo,
      'Data de registo': formatarDataHora(d.created_at),
      Status: d.status,
      Categoria: d.categoria_custom ?? d.categoria,
      Faculdade: d.faculdade,
      Curso: d.curso ?? '',
      'Denunciado': d.denunciado_nome ?? '',
      'Tipo denunciado': d.denunciado_tipo ?? '',
      Local: d.local_ocorrido ?? '',
      'Data do ocorrido': formatarData(d.data_ocorrido),
      Anónima: d.anonima ? 'Sim' : 'Não',
      Descrição: d.descricao,
    }))
    const ws = XLSX.utils.json_to_sheet(rows)
    ws['!cols'] = [
      { wch: 12 }, { wch: 18 }, { wch: 14 }, { wch: 22 }, { wch: 30 },
      { wch: 20 }, { wch: 20 }, { wch: 12 }, { wch: 24 }, { wch: 14 },
      { wch: 10 }, { wch: 60 },
    ]
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Denúncias')
    XLSX.writeFile(wb, `vozul-denuncias-${new Date().toISOString().slice(0, 10)}.xlsx`)
    toast.success('Relatório Excel exportado')
    void registrarAcesso({
      usuarioId: profile?.id ?? '',
      acao: 'Exportação de relatório',
      recurso: 'relatorios',
      detalhes: `Excel · ${data.length} denúncia(s)`,
    })
  }

  const tabelaRef = useRef<HTMLDivElement>(null)

  const exportarPDF = () => {
    if (!data || data.length === 0) {
      toast.info('Sem dados para exportar')
      return
    }
    const printWindow = window.open('', '_blank', 'width=1200,height=800')
    if (!printWindow) {
      toast.error('Não foi possível abrir nova janela')
      return
    }
    printWindow.document.write(`<!DOCTYPE html>
<html lang="pt">
<head>
<meta charset="UTF-8" />
<title>Relatório Denúncias — VozUL</title>
<style>
  * { box-sizing: border-box; }
  body { font-family: sans-serif; padding: 24px; color: #1e293b; }
  h1 { font-size: 16px; margin-bottom: 4px; }
  h2 { font-size: 11px; color: #64748b; margin: 0 0 16px; }
  table { width: 100%; border-collapse: collapse; font-size: 11px; }
  th, td { border: 1px solid #cbd5e1; padding: 6px 8px; text-align: left; }
  th { background: #f1f5f9; font-weight: 600; }
  tr:nth-child(even) td { background: #f8fafc; }
  .footer { margin-top: 16px; font-size: 10px; color: #94a3b8; text-align: center; }
</style>
</head>
<body>
<h1>Relatório de Denúncias — VozUL</h1>
<h2>${new Date().toLocaleDateString('pt-PT')} · ${data.length} denúncia(s)</h2>
<table>
<tr><th>Código</th><th>Data</th><th>Estado</th><th>Categoria</th><th>Faculdade</th><th>Curso</th><th>Denunciado</th><th>Local</th><th>Anónima</th></tr>
${data
  .map(
    (d) =>
      `<tr>
        <td>${d.codigo}</td>
        <td>${formatarData(d.created_at)}</td>
        <td>${d.status}</td>
        <td>${d.categoria_custom ?? d.categoria}</td>
        <td>${d.faculdade}</td>
        <td>${d.curso ?? ''}</td>
        <td>${d.denunciado_nome ?? '—'}</td>
        <td>${d.local_ocorrido ?? '—'}</td>
        <td>${d.anonima ? 'Sim' : 'Não'}</td>
      </tr>`,
  )
  .join('')}
</table>
<p class="footer">VozUL · Painel da Comissão de Ética · Universidade Licungo</p>
</body></html>`)
    printWindow.document.close()
    printWindow.print()
    toast.success('PDF aberto para impressão')
    void registrarAcesso({
      usuarioId: profile?.id ?? '',
      acao: 'Exportação de relatório',
      recurso: 'relatorios',
      detalhes: `PDF · ${data.length} denúncia(s)`,
    })
  }

  return (
    <div className="space-y-4">
      <Card>
        <CardContent className="flex flex-wrap items-end gap-4 p-4">
          <div className="space-y-1.5">
            <Label className="text-xs">Data início</Label>
            <Input
              type="date"
              className="w-44"
              value={de}
              onChange={(e) => setDe(e.target.value)}
            />
          </div>
          <div className="space-y-1.5">
            <Label className="text-xs">Data fim</Label>
            <Input
              type="date"
              className="w-44"
              value={ate}
              onChange={(e) => setAte(e.target.value)}
            />
          </div>
          {visaoGlobal && (
            <div className="space-y-1.5">
              <Label className="text-xs">Faculdade</Label>
              <Select value={faculdade ?? '__all__'} onValueChange={(v) => setFaculdade(v === '__all__' ? null : v)}>
                <SelectTrigger className="w-52">
                  <SelectValue placeholder="Todas" />
                </SelectTrigger>
                <SelectContent className="max-h-72">
                  <SelectItem value="__all__">Todas</SelectItem>
                  {FACULDADES.map((f) => (
                    <SelectItem key={f} value={f}>{f.replace('Faculdade de ', '')}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
          <div className="space-y-1.5">
            <Label className="text-xs">Estado</Label>
            <Select value={status ?? '__all__'} onValueChange={(v) => setStatus(v === '__all__' ? null : v)}>
              <SelectTrigger className="w-40">
                <SelectValue placeholder="Todos" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="__all__">Todos</SelectItem>
                {STATUS_DENUNCIA.map((s) => (
                  <SelectItem key={s} value={s}>{s}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-1.5">
            <Label className="text-xs">Categoria</Label>
            <Select value={categoria ?? '__all__'} onValueChange={(v) => setCategoria(v === '__all__' ? null : v)}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Todas" />
              </SelectTrigger>
              <SelectContent className="max-h-72">
                <SelectItem value="__all__">Todas</SelectItem>
                {CATEGORIAS_DENUNCIA.map((c) => (
                  <SelectItem key={c} value={c}>{c}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <Separator orientation="vertical" className="hidden h-8 sm:block" />
          <Button variant="outline" onClick={() => refetch()} disabled={isFetching}>
            {isFetching && <Loader2 className="animate-spin" />}
            Gerar relatório
          </Button>
        </CardContent>
      </Card>

      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">
          {isLoading ? 'A gerar…' : `${data?.length ?? 0} denúncia(s) no relatório`}
        </p>
        <div className="flex gap-2">
          <Button variant="outline" size="sm" onClick={exportarXLSX} disabled={!data || data.length === 0}>
            <Table /> Exportar Excel
          </Button>
          <Button variant="outline" size="sm" onClick={exportarPDF} disabled={!data || data.length === 0}>
            <Printer /> Exportar PDF
          </Button>
        </div>
      </div>

      <div ref={tabelaRef}>
        {isLoading ? (
          <Skeleton className="h-40" />
        ) : !data || data.length === 0 ? (
          <Card>
            <CardContent className="p-10 text-center text-sm text-muted-foreground">
              Nenhuma denúncia encontrada para os filtros selecionados.
            </CardContent>
          </Card>
        ) : (
          <div className="overflow-x-auto rounded-lg border bg-card">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b bg-muted/50 text-left text-xs font-medium text-muted-foreground">
                  <th className="p-3">Código</th>
                  <th className="p-3">Data</th>
                  <th className="p-3">Estado</th>
                  <th className="p-3">Categoria</th>
                  <th className="p-3 hidden lg:table-cell">Faculdade</th>
                  <th className="p-3 hidden xl:table-cell">Curso</th>
                  <th className="p-3 hidden xl:table-cell">Denunciado</th>
                  <th className="p-3 hidden 2xl:table-cell">Local</th>
                </tr>
              </thead>
              <tbody className="divide-y">
                {data.slice(0, 100).map((d) => (
                  <tr key={d.id} className="hover:bg-muted/30">
                    <td className="p-3 font-mono text-xs font-semibold">{d.codigo}</td>
                    <td className="p-3 text-xs">{formatarData(d.created_at)}</td>
                    <td className="p-3">
                      <StatusBadge status={d.status} className="text-[10px]" />
                    </td>
                    <td className="p-3 text-xs">{d.categoria_custom ?? d.categoria}</td>
                    <td className="hidden p-3 text-xs lg:table-cell">{d.faculdade}</td>
                    <td className="hidden p-3 text-xs xl:table-cell">{d.curso ?? '—'}</td>
                    <td className="hidden p-3 text-xs xl:table-cell">
                      {d.anonima ? (
                        <span className="text-muted-foreground italic">Anónima</span>
                      ) : (
                        d.denunciado_nome ?? '—'
                      )}
                    </td>
                    <td className="hidden p-3 text-xs 2xl:table-cell">{d.local_ocorrido ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}