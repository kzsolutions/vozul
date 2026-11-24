import { useEffect, useRef, useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Link, useNavigate, useParams } from 'react-router-dom'
import {
  ArrowLeft,
  Calendar,
  FileQuestion,
  Image,
  Loader2,
  Lock,
  MessageCircle,
  Paperclip,
  Phone,
  Pin,
  ShieldAlert,
  User,
} from 'lucide-react'
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  Skeleton,
  Separator,
  StatusBadge,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import {
  listarEvidencias,
  obterDenuncia,
  obterUrlAssinada,
} from '../../lib/api/denuncias'
import { obterPerfil } from '../../lib/api/profiles'
import { registrarAcesso } from '../../lib/api/historico'
import { formatarDataHora } from '../../lib/format'
import { isImagem } from '../../lib/detect'
import type { Evidencia } from '../../../lib/types'
import { EvidenceViewer } from './EvidenceViewer'

export function DenunciaDetailScreen() {
  const { id } = useParams()
  const denunciaId = Number(id)
  const navigate = useNavigate()
  const { profile: admin, isSuperAdmin } = useAuth()
  const [provaAtiva, setProvaAtiva] = useState<Evidencia | null>(null)
  const acessoRegistado = useRef(false)

  const numeroValido = Number.isInteger(denunciaId) && denunciaId > 0

  const {
    data: denuncia,
    isLoading,
    isError,
  } = useQuery({
    queryKey: ['denuncia', denunciaId],
    queryFn: () => obterDenuncia(denunciaId),
    enabled: numeroValido,
  })

  const { data: evidencias = [] } = useQuery({
    queryKey: ['evidencias', denunciaId],
    queryFn: () => listarEvidencias(denunciaId),
    enabled: numeroValido,
  })

  const { data: responsavel } = useQuery({
    queryKey: ['perfil', denuncia?.admin_responsavel],
    queryFn: () => obterPerfil(denuncia!.admin_responsavel!),
    enabled: !!denuncia?.admin_responsavel,
  })

  const { data: estudante } = useQuery({
    queryKey: ['perfil', denuncia?.estudante_id],
    queryFn: () => obterPerfil(denuncia!.estudante_id!),
    enabled: !!denuncia?.estudante_id && !denuncia.anonima,
  })

  useEffect(() => {
    if (!denuncia || !admin || acessoRegistado.current) return
    acessoRegistado.current = true
    void registrarAcesso({
      usuarioId: admin.id,
      acao: 'Consulta de denúncia',
      recurso: 'denuncias',
      registroId: denuncia.codigo,
      detalhes: `${denuncia.categoria} · ${denuncia.faculdade}`,
    })
  }, [admin, denuncia])

  const chatSomenteLeitura = isSuperAdmin

  if (isError) {
    return (
      <Card>
        <CardContent className="p-10 text-center">
          <ShieldAlert className="mx-auto size-10 text-destructive" />
          <p className="mt-3 font-medium">Não foi possível carregar esta denúncia.</p>
          <p className="text-sm text-muted-foreground">
            Pode estar fora da sua faculdade ou não existir.
          </p>
        </CardContent>
      </Card>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => navigate('/admin/denuncias')}>
          <ArrowLeft className="size-4" />
        </Button>
        {isLoading || !denuncia ? (
          <Skeleton className="h-7 w-40" />
        ) : (
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold">{denuncia.codigo}</h2>
            <StatusBadge status={denuncia.status} />
            {denuncia.anonima && <Badge variant="secondary">Anónima</Badge>}
            {denuncia.tem_provas && (
              <Badge variant="outline">
                <Paperclip /> Com provas
              </Badge>
            )}
          </div>
        )}
      </div>

      {isLoading || !denuncia ? (
        <div className="space-y-3">
          <Skeleton className="h-40" />
          <Skeleton className="h-28" />
        </div>
      ) : (
        <>
          <div className="grid gap-4 lg:grid-cols-3">
            <Card className="lg:col-span-2">
              <CardHeader>
                <CardTitle className="text-base">Detalhes da denúncia</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4 text-sm">
                <div>
                  <p className="font-semibold">Descrição</p>
                  <p className="mt-1 whitespace-pre-wrap text-muted-foreground">
                    {denuncia.descricao || 'Sem descrição.'}
                  </p>
                </div>
                <Separator />
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                  <InfoLinha icone={FileQuestion} label="Categoria" valor={denuncia.categoria_custom ?? denuncia.categoria} />
                  <InfoLinha icone={Pin} label="Curso" valor={denuncia.curso} />
                  <InfoLinha icone={Calendar} label="Data do ocorrido" valor={formatarDataHora(denuncia.data_ocorrido)} />
                  <InfoLinha icone={Pin} label="Local" valor={denuncia.local_ocorrido} />
                  <InfoLinha icone={Calendar} label="Recebida em" valor={formatarDataHora(denuncia.created_at)} />
                  <InfoLinha icone={Calendar} label="Última atualização" valor={formatarDataHora(denuncia.updated_at)} />
                </div>
              </CardContent>
            </Card>

            <div className="space-y-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Gestão</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <p className="text-xs text-muted-foreground">
                    Consulta em modo de leitura: o estado e os anexos não podem ser alterados.
                  </p>
                  <div className="space-y-1">
                    <p className="text-xs font-medium text-muted-foreground">Estado atual</p>
                    <StatusBadge status={denuncia.status} />
                  </div>
                  <div className="space-y-1">
                    <p className="text-xs font-medium text-muted-foreground">Responsável</p>
                    <p className="text-sm font-medium">
                      {responsavel?.nome_completo ?? responsavel?.email ?? 'Sem responsável'}
                    </p>
                  </div>

                  <Separator />

                  <Button variant="outline" className="w-full" asChild>
                    <Link to={`/admin/mensagens/${denuncia.id}`}>
                      <MessageCircle /> {chatSomenteLeitura ? 'Ver conversa (só leitura)' : 'Conversa com a denúncia'}
                    </Link>
                  </Button>
                </CardContent>
              </Card>

              <Card>
                <CardHeader>
                  <CardTitle className="text-base">Denunciante</CardTitle>
                </CardHeader>
                <CardContent className="space-y-3 text-sm">
                  {denuncia.anonima ? (
                    <p className="flex items-center gap-2 text-muted-foreground">
                      <Lock className="size-4" /> Denúncia anónima
                    </p>
                  ) : estudante ? (
                    <>
                      <InfoLinha icone={User} label="Nome" valor={estudante.nome_completo} />
                      <InfoLinha icone={Pin} label="Curso" valor={estudante.curso} />
                      <InfoLinha icone={Pin} label="Faculdade" valor={estudante.faculdade} />
                      <InfoLinha icone={Phone} label="Celular" valor={estudante.celular} />
                      <InfoLinha icone={User} label="Nº de estudante" valor={estudante.numero_estudante} />
                    </>
                  ) : (
                    <div className="flex items-center gap-2 text-muted-foreground">
                      <Loader2 className="animate-spin" /> A carregar…
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>

          {/* Denunciado */}
          <Card>
            <CardHeader>
              <CardTitle className="text-base">Denunciado</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-2 lg:grid-cols-4">
                <InfoLinha icone={User} label="Tipo" valor={denuncia.denunciado_tipo} />
                <InfoLinha icone={User} label="Nome" valor={denuncia.denunciado_nome} />
                <InfoLinha icone={Pin} label="Nº" valor={denuncia.denunciado_numero} />
                <InfoLinha icone={Phone} label="Celular" valor={denuncia.denunciado_celular} />
              </div>
            </CardContent>
          </Card>

          {/* Provas */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-base">
                <Image /> Provas ({evidencias.length})
              </CardTitle>
            </CardHeader>
            <CardContent>
              {evidencias.length === 0 ? (
                <p className="text-sm text-muted-foreground">
                  Sem provas anexadas a esta denúncia.
                </p>
              ) : (
                <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
                  {evidencias.map((ev) => (
                    <button
                      key={ev.id}
                      onClick={() => setProvaAtiva(ev)}
                      className="group relative overflow-hidden rounded-lg border text-left"
                    >
                      {isImagem(ev.file_type) ? (
                        <ProvaImagem path={ev.file_url} nome={ev.file_name} />
                      ) : (
                        <div className="flex aspect-video items-center justify-center bg-muted text-xs text-muted-foreground">
                          {ev.file_type === 'application/pdf' ? 'PDF' : 'Ficheiro'}
                        </div>
                      )}
                      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/60 to-transparent p-2">
                        <p className="truncate text-xs text-white">{ev.file_name}</p>
                      </div>
                    </button>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </>
      )}

      {provaAtiva && (
        <EvidenceViewer evidencia={provaAtiva} onClose={() => setProvaAtiva(null)} />
      )}
    </div>
  )
}

function ProvaImagem({ path, nome }: { path: string; nome: string | null }) {
  const { data: url } = useQuery({
    queryKey: ['evidencia-url', path],
    queryFn: () => obterUrlAssinada(path),
  })
  if (!url) return <Skeleton className="aspect-video w-full" />
  return <img src={url} alt={nome ?? 'prova'} className="aspect-video w-full object-cover" />
}

function InfoLinha({
  icone: Icon,
  label,
  valor,
}: {
  icone: React.ComponentType<{ className?: string }>
  label: string
  valor: string | null | undefined
}) {
  return (
    <div className="flex items-start gap-2">
      <Icon className="mt-0.5 size-4 shrink-0 text-muted-foreground" />
      <div className="min-w-0">
        <p className="text-xs text-muted-foreground">{label}</p>
        <p className="truncate font-medium">{valor ?? '—'}</p>
      </div>
    </div>
  )
}

