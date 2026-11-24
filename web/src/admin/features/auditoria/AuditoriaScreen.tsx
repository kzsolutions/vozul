import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { History as HistoryIcon } from 'lucide-react'
import { Badge, Card, CardContent, Input, Select, SelectContent, SelectItem, SelectTrigger, SelectValue, Skeleton } from '../../components/ui'
import { listarHistoricoAcessos } from '../../lib/api/historico'
import { formatarDataHora, siglaNome } from '../../lib/format'
import type { HistoricoAcesso } from '../../../lib/types'

type TipoFiltro = 'todos' | 'acesso' | 'alteracao' | 'consulta' | 'outro'
type Estado = 'sucesso' | 'atencao' | 'registado'
type EstadoFiltro = 'todos' | Estado

const LABEL_TIPO: Record<TipoFiltro, string> = {
  todos: 'Todos os tipos',
  acesso: 'Acessos',
  alteracao: 'Alterações',
  consulta: 'Consultas',
  outro: 'Outros',
}

const LABEL_ESTADO: Record<Estado, string> = {
  sucesso: 'Sucesso',
  atencao: 'Atenção',
  registado: 'Registado',
}

function tipoRegistro(r: HistoricoAcesso): Exclude<TipoFiltro, 'todos'> {
  if (r.recurso === 'autenticacao' || /login|logout|acesso/i.test(r.acao)) return 'acesso'
  if (['administradores', 'permissoes', 'configuracoes'].includes(r.recurso ?? '')) return 'alteracao'
  if (['denuncias', 'mensagens', 'relatorios'].includes(r.recurso ?? '')) return 'consulta'
  return 'outro'
}

function estadoRegistro(r: HistoricoAcesso): Estado {
  if (/login|logout|acesso/i.test(r.acao)) return 'sucesso'
  if (/remo|permiss|alter|cria/i.test(r.acao)) return 'atencao'
  return 'registado'
}

function classeEstado(estado: Estado): string {
  switch (estado) {
    case 'sucesso':
      return 'border-emerald-200 bg-emerald-50 text-emerald-700'
    case 'atencao':
      return 'border-amber-200 bg-amber-50 text-amber-700'
    default:
      return 'border-slate-200 bg-slate-50 text-slate-600'
  }
}

function nomeUsuario(r: HistoricoAcesso): string {
  return r.profiles?.nome_completo ?? r.usuario_id.slice(0, 8)
}

export function AuditoriaScreen() {
  const [busca, setBusca] = useState('')
  const [tipo, setTipo] = useState<TipoFiltro>('todos')
  const [estado, setEstado] = useState<EstadoFiltro>('todos')
  const [utilizador, setUtilizador] = useState('todos')
  const [recurso, setRecurso] = useState('todos')

  const { data: registos = [], isLoading } = useQuery({
    queryKey: ['auditoria-lista'],
    queryFn: () => listarHistoricoAcessos(null),
    refetchInterval: 60_000,
  })

  const recursos = useMemo(
    () => [...new Set(registos.map((r) => r.recurso).filter((r): r is string => !!r))].sort(),
    [registos],
  )

  const utilizadores = useMemo(() => {
    const mapa = new Map<string, string>()
    registos.forEach((r) => {
      if (r.usuario_id) mapa.set(r.usuario_id, nomeUsuario(r))
    })
    return [...mapa.entries()]
      .map(([id, nome]) => ({ id, nome }))
      .sort((a, b) => a.nome.localeCompare(b.nome))
  }, [registos])

  const filtrados = useMemo(() => {
    const termo = busca.trim().toLowerCase()
    return registos.filter((r) => {
      if (tipo !== 'todos' && tipoRegistro(r) !== tipo) return false
      if (estado !== 'todos' && estadoRegistro(r) !== estado) return false
      if (utilizador !== 'todos' && r.usuario_id !== utilizador) return false
      if (recurso !== 'todos' && r.recurso !== recurso) return false
      if (!termo) return true
      return [
        r.acao,
        r.detalhes,
        r.recurso,
        r.registro_id,
        r.ip_address,
        r.profiles?.nome_completo,
        r.profiles?.email,
      ]
        .filter(Boolean)
        .some((valor) => String(valor).toLowerCase().includes(termo))
    })
  }, [busca, tipo, estado, utilizador, recurso, registos])

  if (isLoading) {
    return (
      <div className="space-y-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <Skeleton key={i} className="h-12 w-full" />
        ))}
      </div>
    )
  }

  return (
    <div className="space-y-3">
      <div className="grid gap-2 md:grid-cols-2 xl:grid-cols-5">
        <Input
          className="md:col-span-2 xl:col-span-1"
          placeholder="Buscar utilizador, ação, detalhe ou IP"
          value={busca}
          onChange={(e) => setBusca(e.target.value)}
        />
        <Select value={tipo} onValueChange={(v) => setTipo(v as TipoFiltro)}>
          <SelectTrigger>
            <SelectValue placeholder="Tipo" />
          </SelectTrigger>
          <SelectContent>
            {(Object.keys(LABEL_TIPO) as TipoFiltro[]).map((chave) => (
              <SelectItem key={chave} value={chave}>
                {LABEL_TIPO[chave]}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={estado} onValueChange={(v) => setEstado(v as EstadoFiltro)}>
          <SelectTrigger>
            <SelectValue placeholder="Estado" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todos os estados</SelectItem>
            <SelectItem value="sucesso">{LABEL_ESTADO.sucesso}</SelectItem>
            <SelectItem value="atencao">{LABEL_ESTADO.atencao}</SelectItem>
            <SelectItem value="registado">{LABEL_ESTADO.registado}</SelectItem>
          </SelectContent>
        </Select>
        <Select value={utilizador} onValueChange={setUtilizador}>
          <SelectTrigger>
            <SelectValue placeholder="Utilizador" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todos os utilizadores</SelectItem>
            {utilizadores.map((u) => (
              <SelectItem key={u.id} value={u.id}>
                {u.nome}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={recurso} onValueChange={setRecurso}>
          <SelectTrigger>
            <SelectValue placeholder="Recurso" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="todos">Todos os recursos</SelectItem>
            {recursos.map((r) => (
              <SelectItem key={r} value={r}>
                {r}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <p className="text-xs text-muted-foreground">{filtrados.length} registo(s)</p>

      {filtrados.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 p-10 text-center">
            <HistoryIcon className="size-10 text-muted-foreground" />
            <p className="font-medium">Sem registos de auditoria</p>
            <p className="text-sm text-muted-foreground">
              Ajuste os filtros ou aguarde novas ações no painel.
            </p>
          </CardContent>
        </Card>
      ) : (
        <Card className="overflow-hidden">
          <CardContent className="p-0">
            <div className="overflow-x-auto">
              <table className="w-full min-w-[980px] border-collapse text-sm">
                <thead className="bg-muted/50 text-left text-xs uppercase tracking-wide text-muted-foreground">
                  <tr>
                    <th className="px-4 py-3 font-semibold">Data</th>
                    <th className="px-4 py-3 font-semibold">Utilizador</th>
                    <th className="px-4 py-3 font-semibold">Ação</th>
                    <th className="px-4 py-3 font-semibold">Estado</th>
                    <th className="px-4 py-3 font-semibold">Detalhe</th>
                    <th className="px-4 py-3 font-semibold">IP</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {filtrados.map((r) => {
                    const est = estadoRegistro(r)
                    return (
                      <tr key={r.id} className="hover:bg-muted/30">
                        <td className="whitespace-nowrap px-4 py-3 text-xs text-muted-foreground">
                          {formatarDataHora(r.created_at)}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-primary/10 text-[11px] font-bold text-primary">
                              {siglaNome(r.profiles?.nome_completo)}
                            </span>
                            <div className="min-w-0">
                              <p className="truncate font-medium">{nomeUsuario(r)}</p>
                              {r.profiles?.email && (
                                <p className="truncate text-xs text-muted-foreground">{r.profiles.email}</p>
                              )}
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <p className="font-medium">{r.acao}</p>
                          <p className="text-xs text-muted-foreground">{LABEL_TIPO[tipoRegistro(r)]}</p>
                        </td>
                        <td className="px-4 py-3">
                          <Badge className={classeEstado(est)}>{LABEL_ESTADO[est]}</Badge>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex flex-wrap items-center gap-1">
                            {r.recurso && <Badge variant="outline">{r.recurso}</Badge>}
                            {r.registro_id && (
                              <span className="font-mono text-xs text-muted-foreground">{r.registro_id}</span>
                            )}
                          </div>
                          {r.detalhes && (
                            <p className="mt-1 max-w-md truncate text-xs text-muted-foreground" title={r.detalhes}>
                              {r.detalhes}
                            </p>
                          )}
                        </td>
                        <td className="whitespace-nowrap px-4 py-3 font-mono text-xs text-muted-foreground">
                          {r.ip_address ?? '—'}
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
