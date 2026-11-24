import { useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts'
import {
  CheckCircle2,
  ClipboardCheck,
  Inbox,
  Lock,
  MailCheck,
  Search,
} from 'lucide-react'
import { useNavigate } from 'react-router-dom'
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  Skeleton,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { calcularEstatisticas, listarDenunciasParaEstatisticas } from '../../lib/api/denuncias'
import { corStatus } from '../../lib/format'
import { STATUS_DENUNCIA } from '../../lib/constants'
import type { DenunciaStatus } from '../../../lib/types'

const ICONES_STATUS: Record<DenunciaStatus, React.ComponentType<{ className?: string }>> = {
  Recebida: MailCheck,
  'Em análise': Search,
  Investigação: ClipboardCheck,
  Resolvida: CheckCircle2,
  Encerrada: Lock,
}

export function DashboardScreen() {
  const { profile, visaoGlobal } = useAuth()
  const navigate = useNavigate()
  const faculdade = visaoGlobal ? null : profile?.faculdade ?? null

  const { data: denuncias, isLoading } = useQuery({
    queryKey: ['estatisticas', faculdade],
    queryFn: () => listarDenunciasParaEstatisticas(faculdade),
  })

  const stats = useMemo(
    () => (denuncias ? calcularEstatisticas(denuncias) : null),
    [denuncias],
  )

  const cards = stats
    ? STATUS_DENUNCIA.map((s) => ({
        status: s,
        count: stats.por_status[s],
        cor: corStatus(s),
        Icon: ICONES_STATUS[s],
      }))
    : []

  const coresGrafico = STATUS_DENUNCIA.map(corStatus)

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="text-lg font-bold">
            Bem-vindo{profile?.nome_completo ? `, ${profile.nome_completo.split(' ')[0]}` : ''}
          </h2>
          <p className="text-sm text-muted-foreground">
            {visaoGlobal
              ? 'Visão geral de todas as faculdades'
              : `Visão geral da ${profile?.faculdade ?? 'sua faculdade'}`}
          </p>
        </div>
        <Button onClick={() => navigate('/admin/denuncias')}>
          <Inbox /> Ver denúncias
        </Button>
      </div>

      {/* Cartões de status */}
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-5">
        {isLoading || !stats
          ? Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-24" />
            ))
          : cards.map(({ status, count, cor, Icon }) => (
              <Card key={status} className="transition-shadow hover:shadow-md">
                <CardContent className="flex items-center gap-3 p-4">
                  <div
                    className="flex size-10 items-center justify-center rounded-lg text-white"
                    style={{ backgroundColor: cor }}
                  >
                    <Icon className="size-5" />
                  </div>
                  <div>
                    <p className="text-xl font-bold leading-none">{count}</p>
                    <p className="mt-1 text-[11px] font-medium text-muted-foreground">
                      {status}
                    </p>
                  </div>
                </CardContent>
              </Card>
            ))}
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* Categorias */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Categorias mais denunciadas</CardTitle>
          </CardHeader>
          <CardContent className="h-72">
            {!stats || stats.por_categoria.length === 0 ? (
              <EmptyGrafico vazio={!stats} />
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={stats.por_categoria.slice(0, 6)} layout="vertical" margin={{ left: 8, right: 16 }}>
                  <CartesianGrid horizontal={false} strokeDasharray="3 3" />
                  <XAxis type="number" allowDecimals={false} fontSize={12} />
                  <YAxis
                    type="category"
                    dataKey="categoria"
                    width={130}
                    fontSize={11}
                    tickLine={false}
                    axisLine={false}
                  />
                  <Tooltip
                    cursor={{ fill: 'hsl(var(--muted))' }}
                    formatter={(value, _name) => [value, 'Denúncias']}
                  />
                  <Bar dataKey="count" radius={[0, 4, 4, 0]} fill="hsl(var(--primary))" />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        {/* Distribuição por status */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Distribuição de denúncias</CardTitle>
          </CardHeader>
          <CardContent className="h-72">
            {!stats ? (
              <Skeleton className="h-full w-full" />
            ) : stats.total === 0 ? (
              <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                Sem denúncias registadas.
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={cards.map((c) => ({ name: c.status, value: c.count }))}
                    dataKey="value"
                    nameKey="name"
                    innerRadius={50}
                    outerRadius={85}
                    paddingAngle={2}
                  >
                    {cards.map((c) => (
                      <Cell key={c.status} fill={c.cor} stroke="hsl(var(--card))" />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            )}
          </CardContent>
          {stats && stats.total > 0 && (
            <div className="flex flex-wrap justify-center gap-2 px-4 pb-4">
              {cards
                .filter((c) => c.count > 0)
                .map((c) => (
                  <Badge key={c.status} variant="outline" className="gap-2">
                    <span className="size-2 rounded-full" style={{ backgroundColor: c.cor }} />
                    {c.status} · {c.count}
                  </Badge>
                ))}
            </div>
          )}
        </Card>

        {/* Faculdades (visão global) */}
        {visaoGlobal && stats && (
          <Card className="lg:col-span-2">
            <CardHeader>
              <CardTitle className="text-base">Todas as faculdades</CardTitle>
            </CardHeader>
            <CardContent className="h-72">
              {stats.por_faculdade.length === 0 ? (
                <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                  Sem registos.
                </div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={stats.por_faculdade} margin={{ top: 8 }}>
                    <CartesianGrid vertical={false} strokeDasharray="3 3" />
                    <XAxis dataKey="faculdade" fontSize={10} tickFormatter={(v) => v.replace('Faculdade de ', '')} />
                    <YAxis allowDecimals={false} fontSize={12} />
                    <Tooltip
                      cursor={{ fill: 'hsl(var(--muted))' }}
                      formatter={(value, _name) => [value, 'Denúncias']}
                    />
                    <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                      {stats.por_faculdade.map((_, i) => (
                        <Cell key={i} fill={coresGrafico[i % coresGrafico.length]} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        )}
      </div>

    </div>
  )
}

function EmptyGrafico({ vazio }: { vazio: boolean }) {
  if (vazio) return <Skeleton className="h-full w-full" />
  return (
    <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
      Sem denúncias registadas.
    </div>
  )
}