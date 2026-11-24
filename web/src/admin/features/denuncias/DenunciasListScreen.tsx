import { useMemo, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useNavigate, useSearchParams } from 'react-router-dom'
import { ChevronLeft, ChevronRight, Filter, Inbox, Search } from 'lucide-react'
import {
  Badge,
  Button,
  Card,
  CardContent,
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  Input,
  Skeleton,
  StatusBadge,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { listarDenunciasAdmin, listarEvidencias, obterUrlAssinada } from '../../lib/api/denuncias'
import { CATEGORIAS_DENUNCIA, FACULDADES, STATUS_DENUNCIA } from '../../lib/constants'
import { formatarDataCurta } from '../../lib/format'
import { isImagem, isVideo } from '../../lib/detect'
import type { Denuncia } from '../../../lib/types'

const PAGINA = 20

export function DenunciasListScreen() {
  const { visaoGlobal } = useAuth()
  const [params, setParams] = useSearchParams()

  const [busca, setBusca] = useState(params.get('busca') ?? '')
  const [buscaAtiva, setBuscaAtiva] = useState<string | null>(params.get('busca'))
  const [status, setStatus] = useState<string | null>(params.get('status'))
  const [categoria, setCategoria] = useState<string | null>(params.get('categoria'))
  const [faculdade, setFaculdade] = useState<string | null>(params.get('faculdade'))
  const pagina = useMemo(() => Math.max(1, Number(params.get('pagina') ?? '1')), [params])

  const { data, isLoading, isFetching } = useQuery({
    queryKey: ['denuncias-lista', pagina, status, categoria, faculdade, buscaAtiva],
    queryFn: () =>
      listarDenunciasAdmin({
        busca: buscaAtiva,
        status,
        categoria,
        faculdade: visaoGlobal ? faculdade : null,
        offset: (pagina - 1) * PAGINA,
        limit: PAGINA,
      }),
  })

  const totalPaginas = Math.max(1, Math.ceil((data?.total ?? 0) / PAGINA))

  const aplicarBusca = () => setBuscaAtiva(busca.trim() || null)

  const limparFiltros = () => {
    setStatus(null)
    setCategoria(null)
    setFaculdade(null)
    setBusca('')
    setBuscaAtiva(null)
    setParams({})
  }

  const temFiltros = !!(status || categoria || faculdade || buscaAtiva)

  const irPagina = (p: number) => {
    if (p < 1 || p > totalPaginas) return
    const next = new URLSearchParams(params)
    next.set('pagina', String(p))
    setParams(next)
    window.scrollTo({ top: 0 })
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 md:flex-row md:items-center">
        <div className="relative flex-1">
          <Search className="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
          <Input
            className="pl-9"
            placeholder="Pesquisar por denunciado, número ou código…"
            value={busca}
            onChange={(e) => setBusca(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && aplicarBusca()}
          />
        </div>
        <div className="flex flex-wrap gap-2">
          <Button onClick={aplicarBusca}>Pesquisar</Button>
          <FiltroStatus valor={status} onChange={setStatus} />
          <FiltroCategoria valor={categoria} onChange={setCategoria} />
          {visaoGlobal && <FiltroFaculdade valor={faculdade} onChange={setFaculdade} />}
          {temFiltros && (
            <Button variant="ghost" onClick={limparFiltros}>
              <Filter /> Limpar
            </Button>
          )}
        </div>
      </div>

      <div className="flex items-center justify-between text-sm text-muted-foreground">
        <span>
          {isLoading ? 'A carregar…' : `${data?.total ?? 0} denúncia(s)`}
          {isFetching && !isLoading ? ' · a atualizar…' : ''}
        </span>
        <span>
          Página {pagina} de {totalPaginas}
        </span>
      </div>

      {isLoading ? (
        <div className="space-y-3">
          {Array.from({ length: 6 }).map((_, i) => (
            <Skeleton key={i} className="h-24" />
          ))}
        </div>
      ) : (data?.items ?? []).length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 p-10 text-center">
            <Inbox className="size-10 text-muted-foreground" />
            <p className="font-medium">Nenhuma denúncia encontrada</p>
            <p className="max-w-sm text-sm text-muted-foreground">
              Ajuste os filtros ou a pesquisa para ver mais resultados.
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {(data?.items ?? []).map((d) => (
            <DenunciaRow key={d.id} d={d} />
          ))}
        </div>
      )}

      <div className="flex items-center justify-between">
        <Button
          variant="outline"
          disabled={pagina <= 1}
          onClick={() => irPagina(pagina - 1)}
        >
          <ChevronLeft /> Anterior
        </Button>
        <span className="text-sm text-muted-foreground">
          {pagina} / {totalPaginas}
        </span>
        <Button
          variant="outline"
          disabled={pagina >= totalPaginas}
          onClick={() => irPagina(pagina + 1)}
        >
          Seguinte <ChevronRight />
        </Button>
      </div>
    </div>
  )
}

function DenunciaRow({ d }: { d: Denuncia }) {
  const navigate = useNavigate()
  return (
    <Card
      className="cursor-pointer transition-shadow hover:shadow-md"
      onClick={() => navigate(`/admin/denuncias/${d.id}`)}
    >
      <CardContent className="p-4">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div className="min-w-0 flex-1">
            <div className="flex flex-wrap items-center gap-2">
              <StatusBadge status={d.status} />
              <span className="font-mono text-xs font-semibold text-muted-foreground">
                {d.codigo}
              </span>
              {d.anonima && <Badge variant="secondary">Anónima</Badge>}
              {d.tem_provas && <Badge variant="outline">Com provas</Badge>}
            </div>
            <p className="mt-2 line-clamp-2 text-sm font-medium">{d.descricao}</p>
            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
              <span>Categoria: {d.categoria}</span>
              {d.faculdade && <span>{d.faculdade}</span>}
              {d.denunciado_nome && <span>Denunciado: {d.denunciado_nome}</span>}
              <span>{formatarDataCurta(d.created_at)}</span>
            </div>
          </div>
          <MiniProvas d={d} />
        </div>
      </CardContent>
    </Card>
  )
}

function MiniProvas({ d }: { d: Denuncia }) {
  const { data: evidencias } = useQuery({
    queryKey: ['evidencias-mini', d.id],
    queryFn: () => listarEvidencias(d.id),
    enabled: d.tem_provas,
  })

  if (!d.tem_provas || !evidencias || evidencias.length === 0) return null

  return (
    <div className="hidden shrink-0 items-center gap-1.5 sm:flex">
      {evidencias.slice(0, 3).map((ev) => (
        <MiniEvidencia key={ev.id} path={ev.file_url} tipo={ev.file_type} />
      ))}
    </div>
  )
}

function MiniEvidencia({ path, tipo }: { path: string; tipo: string }) {
  const { data: url } = useQuery({
    queryKey: ['thumb-url', path],
    queryFn: () => obterUrlAssinada(path),
  })

  if (!url) return <Skeleton className="size-10 rounded-md" />

  if (isImagem(tipo)) {
    return <img src={url} alt="prova" className="size-10 rounded-md object-cover" />
  }
  if (isVideo(tipo)) {
    return (
      <div className="flex size-10 items-center justify-center rounded-md bg-muted text-[10px] text-muted-foreground">
        ▶
      </div>
    )
  }
  return (
    <div className="flex size-10 items-center justify-center rounded-md bg-muted text-[10px] font-bold text-muted-foreground">
      PDF
    </div>
  )
}

function FiltroStatus({
  valor,
  onChange,
}: {
  valor: string | null
  onChange: (v: string | null) => void
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline">
          <Filter /> {valor ?? 'Estado'}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent>
        <DropdownMenuLabel>Estado</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuCheckboxItem checked={valor === null} onCheckedChange={() => onChange(null)}>
          Todos
        </DropdownMenuCheckboxItem>
        {STATUS_DENUNCIA.map((s) => (
          <DropdownMenuCheckboxItem
            key={s}
            checked={valor === s}
            onCheckedChange={() => onChange(valor === s ? null : s)}
          >
            {s}
          </DropdownMenuCheckboxItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

function FiltroCategoria({
  valor,
  onChange,
}: {
  valor: string | null
  onChange: (v: string | null) => void
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" className="hidden md:inline-flex">
          <Filter /> {valor ?? 'Categoria'}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="max-h-72 overflow-y-auto">
        <DropdownMenuLabel>Categoria</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuCheckboxItem checked={valor === null} onCheckedChange={() => onChange(null)}>
          Todas
        </DropdownMenuCheckboxItem>
        {CATEGORIAS_DENUNCIA.map((c) => (
          <DropdownMenuCheckboxItem
            key={c}
            checked={valor === c}
            onCheckedChange={() => onChange(valor === c ? null : c)}
          >
            {c}
          </DropdownMenuCheckboxItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

function FiltroFaculdade({
  valor,
  onChange,
}: {
  valor: string | null
  onChange: (v: string | null) => void
}) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="outline" className="hidden lg:inline-flex">
          <Filter /> {valor ? valor.replace('Faculdade de ', '') : 'Faculdade'}
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent className="max-h-72 overflow-y-auto">
        <DropdownMenuLabel>Faculdade</DropdownMenuLabel>
        <DropdownMenuSeparator />
        <DropdownMenuCheckboxItem checked={valor === null} onCheckedChange={() => onChange(null)}>
          Todas
        </DropdownMenuCheckboxItem>
        {FACULDADES.map((f) => (
          <DropdownMenuCheckboxItem
            key={f}
            checked={valor === f}
            onCheckedChange={() => onChange(valor === f ? null : f)}
          >
            {f.replace('Faculdade de ', '')}
          </DropdownMenuCheckboxItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}