import { useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import {
  Badge,
  Button,
  Card,
  CardContent,
  CardHeader,
  CardTitle,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Skeleton,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { listarAdmins } from '../../lib/api/admins'
import { registrarAcesso } from '../../lib/api/historico'
import {
  listarPermissoes,
  listarPermissoesAdmin,
  listarPermissoesPerfil,
  removerPermissoesAdmin,
  salvarPermissaoAdmin,
  salvarPermissaoPerfil,
  type PermissaoRole,
} from '../../lib/api/permissoes'
import { siglaNome } from '../../lib/format'

const PERFIS: Array<{ role: PermissaoRole; rotulo: string }> = [
  { role: 'admin', rotulo: 'Admin' },
  { role: 'super_admin', rotulo: 'Super Admin' },
]

const valor = (permitido: boolean) => (permitido ? 'sim' : 'nao')

export function PermissoesScreen() {
  const queryClient = useQueryClient()
  const { profile } = useAuth()
  const [adminSelecionado, setAdminSelecionado] = useState('')

  const { data: permissoes = [], isLoading } = useQuery({
    queryKey: ['permissoes-catalogo'],
    queryFn: listarPermissoes,
  })

  const { data: perfis = [] } = useQuery({
    queryKey: ['permissoes-perfil'],
    queryFn: listarPermissoesPerfil,
  })

  const { data: ajustes = [] } = useQuery({
    queryKey: ['permissoes-admin'],
    queryFn: listarPermissoesAdmin,
  })

  const { data: admins = [] } = useQuery({
    queryKey: ['admins-lista'],
    queryFn: () => listarAdmins(null),
  })

  const admin = admins.find((a) => a.id === adminSelecionado)
  const ajustesDoAdmin = useMemo(
    () => ajustes.filter((a) => a.usuario_id === adminSelecionado),
    [ajustes, adminSelecionado],
  )

  const registar = async (
    acao: string,
    recurso: string,
    registroId: string,
    detalhes: string,
  ) => {
    await registrarAcesso({
      usuarioId: profile?.id ?? '',
      acao,
      recurso,
      registroId,
      detalhes,
    })
  }

  const mutations = {
    perfil: useMutation({
      mutationFn: async ({
        role,
        chave,
        permitido,
      }: {
        role: PermissaoRole
        chave: string
        permitido: boolean
      }) => {
        await salvarPermissaoPerfil(role, chave, permitido)
        await registar(
          'Alteração de permissão (perfil)',
          'permissoes',
          `${role}:${chave}`,
          `${chave} → ${permitido ? 'permitido' : 'negado'}`,
        )
      },
      onSuccess: () => {
        toast.success('Permissão do perfil atualizada')
        queryClient.invalidateQueries({ queryKey: ['permissoes-perfil'] })
        queryClient.invalidateQueries({ queryKey: ['permissoes-admin'] })
      },
      onError: (e: Error) => toast.error(e.message),
    }),
    admin: useMutation({
      mutationFn: async ({
        chave,
        permitido,
      }: {
        chave: string
        permitido: boolean
      }) => {
        if (!admin) return
        await salvarPermissaoAdmin(admin.id, chave, permitido)
        await registar(
          'Alteração de permissão (administrador)',
          'permissoes',
          `${admin.id}:${chave}`,
          `${admin.email ?? admin.id}: ${chave} → ${permitido ? 'permitido' : 'negado'}`,
        )
      },
      onSuccess: () => {
        toast.success('Permissão do administrador atualizada')
        queryClient.invalidateQueries({ queryKey: ['permissoes-admin'] })
      },
      onError: (e: Error) => toast.error(e.message),
    }),
    remover: useMutation({
      mutationFn: async () => {
        if (!admin) return
        await removerPermissoesAdmin(admin.id)
        await registar(
          'Remoção de ajustes de permissão',
          'permissoes',
          admin.id,
          admin.email ?? admin.id,
        )
      },
      onSuccess: () => {
        toast.success('Ajustes removidos; permissões do perfil restauradas')
        queryClient.invalidateQueries({ queryKey: ['permissoes-admin'] })
      },
      onError: (e: Error) => toast.error(e.message),
    }),
  }

  const permissaoPerfil = (role: PermissaoRole, chave: string) =>
    perfis.find((p) => p.role === role && p.permissao_chave === chave)?.permitido ?? false

  const permissaoEfetiva = (chave: string) => {
    const ajuste = ajustesDoAdmin.find((a) => a.permissao_chave === chave)
    return ajuste?.permitido ?? (admin ? permissaoPerfil(admin.role as PermissaoRole, chave) : false)
  }

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-lg font-bold">Matriz de Permissões</h2>
        <p className="text-sm text-muted-foreground">
          Defina as permissões por perfil e ajuste individualmente cada administrador.
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Permissões por perfil</CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-full" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <div className="min-w-[560px]">
                <div className="grid grid-cols-[minmax(0,2fr)_minmax(140px,1fr)_minmax(140px,1fr)] gap-3 border-b pb-2 text-xs font-semibold text-muted-foreground">
                  <span>Permissão</span>
                  {PERFIS.map((p) => (
                    <span key={p.role}>{p.rotulo}</span>
                  ))}
                </div>
                {permissoes.map((p) => (
                  <div
                    key={p.chave}
                    className="grid grid-cols-[minmax(0,2fr)_minmax(140px,1fr)_minmax(140px,1fr)] items-center gap-3 border-b py-2 text-sm last:border-b-0"
                  >
                    <div className="min-w-0">
                      <p className="truncate font-medium">{p.rotulo}</p>
                      <div className="mt-1 flex flex-wrap items-center gap-2">
                        <Badge variant="outline" className="text-[10px]">
                          {p.modulo}
                        </Badge>
                        {p.descricao && (
                          <span className="text-xs text-muted-foreground">
                            {p.descricao}
                          </span>
                        )}
                      </div>
                    </div>
                    {PERFIS.map((perfil) => (
                      <div key={perfil.role} className="min-w-0">
                        <Select
                          value={valor(permissaoPerfil(perfil.role, p.chave))}
                          onValueChange={(v) =>
                            mutations.perfil.mutate({
                              role: perfil.role,
                              chave: p.chave,
                              permitido: v === 'sim',
                            })
                          }
                        >
                          <SelectTrigger className="w-full min-w-0">
                            <SelectValue />
                          </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="sim">Permitido</SelectItem>
                          <SelectItem value="nao">Negado</SelectItem>
                        </SelectContent>
                      </Select>
                      </div>
                    ))}
                  </div>
                ))}
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-3">
          <div>
            <CardTitle className="text-base">Ajustes por administrador</CardTitle>
            <p className="text-xs text-muted-foreground">
              Um ajuste individual substitui a predefinição do perfil.
            </p>
          </div>
          <Button
            variant="outline"
            size="sm"
            disabled={!admin || ajustesDoAdmin.length === 0 || mutations.remover.isPending}
            onClick={() => mutations.remover.mutate()}
          >
            Restaurar perfil
          </Button>
        </CardHeader>
        <CardContent className="space-y-3">
          <Select value={adminSelecionado} onValueChange={setAdminSelecionado}>
            <SelectTrigger className="w-full md:w-80">
              <SelectValue placeholder="Selecione o administrador" />
            </SelectTrigger>
            <SelectContent>
              {admins.map((a) => (
                <SelectItem key={a.id} value={a.id}>
                  {a.nome_completo ?? a.email} · {a.role === 'super_admin' ? 'Super Admin' : 'Admin'}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>

          {admin ? (
            <div className="space-y-2">
              <div className="flex flex-wrap items-center gap-3 rounded-lg bg-muted p-3">
                <div className="flex size-8 items-center justify-center rounded-full bg-primary/10 text-xs font-bold text-primary">
                  {siglaNome(admin.nome_completo)}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium">{admin.nome_completo ?? admin.email}</p>
                  <p className="text-xs text-muted-foreground">
                    {ajustesDoAdmin.length} ajuste(s)
                  </p>
                </div>
              </div>
              <div className="overflow-x-auto">
                <div className="min-w-[420px] space-y-2">
                  {permissoes.map((p) => (
                    <div
                      key={p.chave}
                      className="grid grid-cols-[minmax(0,2fr)_minmax(140px,1fr)] items-center gap-3 border-b py-2 text-sm last:border-b-0"
                    >
                      <div className="min-w-0">
                        <p className="truncate font-medium">{p.rotulo}</p>
                        <p className="truncate text-xs text-muted-foreground">
                          Perfil: {permissaoPerfil(admin.role as PermissaoRole, p.chave) ? 'permitido' : 'negado'}
                        </p>
                      </div>
                      <div className="min-w-0">
                        <Select
                          value={valor(permissaoEfetiva(p.chave))}
                          onValueChange={(v) =>
                            mutations.admin.mutate({ chave: p.chave, permitido: v === 'sim' })
                          }
                        >
                          <SelectTrigger className="w-full min-w-0">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="sim">Permitido</SelectItem>
                            <SelectItem value="nao">Negado</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              Selecione um administrador para ajustar permissões individuais.
            </p>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
