import { useState } from 'react'
import type { FormEvent } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Loader2, Plus, Trash2, UserCog } from 'lucide-react'
import { toast } from 'sonner'
import { useAuth } from '../../lib/auth'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  Badge,
  Button,
  Card,
  CardContent,
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  Input,
  Label,
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
  Separator,
  Skeleton,
} from '../../components/ui'
import { listarAdmins, atualizarNivelAdmin, removerAdmin } from '../../lib/api/admins'
import { criarAdmin, eliminarAuthUser } from '../../lib/api/admin-users'
import { listarFaculdades, listarPolos } from '../../lib/api/catalogo'
import { registrarAcesso } from '../../lib/api/historico'
import { rotuloRole, siglaNome } from '../../lib/format'
import type { Profile, Role } from '../../../lib/types'

const ROLES_GESTAO: Role[] = ['super_admin', 'admin']

export function AdminsScreen() {
  const queryClient = useQueryClient()
  const { profile: perfil } = useAuth()
  const [modalCriar, setModalCriar] = useState(false)
  const [adminRemocao, setAdminRemocao] = useState<Profile | null>(null)

  const { data: admins = [], isLoading } = useQuery({
    queryKey: ['admins-lista'],
    queryFn: () => listarAdmins(null),
  })

  const { data: polos = [] } = useQuery({
    queryKey: ['catalogo-polos'],
    queryFn: listarPolos,
    staleTime: 5 * 60 * 1000,
  })

  const { data: faculdades = [] } = useQuery({
    queryKey: ['catalogo-faculdades-todas'],
    queryFn: async () => (await Promise.all(polos.map((p) => listarFaculdades(p.id)))).flat(),
    enabled: polos.length > 0,
    staleTime: 5 * 60 * 1000,
  })

  const nomePolo = (id: string | null) =>
    id ? (polos.find((p) => p.id === id)?.nome ?? id) : 'Sem delegação'

  const responsaveisPolo = (poloId: string) =>
    admins.filter((a) => a.role === 'admin' && a.polo_id === poloId)

  const responsavelFaculdade = (faculdadeId: string, nome: string) =>
    admins.find(
      (a) =>
        a.role === 'admin' &&
        (a.faculdade_id === faculdadeId || a.faculdade === nome),
    )

  const mutations = {
    atualizarNivel: useMutation({
      mutationFn: async ({ id, role }: { id: string; role: Role }) => {
        await atualizarNivelAdmin(id, role)
        const alvo = admins.find((a) => a.id === id)
        await registrarAcesso({
          usuarioId: perfil?.id ?? '',
          acao: 'Alteração de papel',
          recurso: 'administradores',
          registroId: alvo?.id ?? id,
          detalhes: `${alvo?.email ?? id} → ${role}`,
        })
      },
      onSuccess: () => {
        toast.success('Nível atualizado')
        queryClient.invalidateQueries({ queryKey: ['admins-lista'] })
      },
      onError: (e: Error) => toast.error(e.message),
    }),
    remover: useMutation({
      mutationFn: async (admin: Profile) => {
        await eliminarAuthUser(admin.id)
        await removerAdmin(admin.id)
        await registrarAcesso({
          usuarioId: perfil?.id ?? '',
          acao: 'Remoção de utilizador',
          recurso: 'administradores',
          registroId: admin.id,
          detalhes: admin.email ?? admin.id,
        })
      },
      onSuccess: () => {
        toast.success('Administrador removido')
        setAdminRemocao(null)
        queryClient.invalidateQueries({ queryKey: ['admins-lista'] })
      },
      onError: (e: Error) => toast.error(e.message),
    }),
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">{admins.length} utilizador(es) de gestão</p>
        <Button onClick={() => setModalCriar(true)}>
          <Plus /> Criar utilizador
        </Button>
      </div>

      {perfil?.role === 'super_admin' && polos.length > 0 && (
        <Card>
          <CardContent className="space-y-3 p-4">
            <div>
              <h2 className="text-sm font-semibold">Responsáveis por delegação/faculdade</h2>
              <p className="text-xs text-muted-foreground">
                Atribuições activas por delegação. Faculdades sem responsável ficam destacadas.
              </p>
            </div>
            <div className="grid gap-3 md:grid-cols-2">
              {polos.map((polo) => {
                const daPolo = responsaveisPolo(polo.id)
                const filhas = faculdades.filter((f) => f.polo_id === polo.id)
                return (
                  <div key={polo.id} className="space-y-2 rounded-lg border p-3">
                    <div className="flex items-center justify-between gap-2">
                      <p className="text-sm font-medium">{polo.nome}</p>
                      {daPolo.length === 0 && (
                        <Badge variant="destructive">Sem responsável na delegação</Badge>
                      )}
                    </div>
                    {daPolo.length > 0 && (
                      <p className="text-xs text-muted-foreground">
                        {daPolo.map((a) => a.nome_completo ?? a.email).join(', ')}
                      </p>
                    )}
                    {filhas.length > 0 && (
                      <ul className="space-y-1 border-t pt-2">
                        {filhas.map((f) => {
                          const responsavel = responsavelFaculdade(f.id, f.nome)
                          return (
                            <li key={f.id} className="flex items-center justify-between gap-2 text-xs">
                              <span className="truncate text-muted-foreground">
                                {f.nome.replace('Faculdade de ', '')}
                              </span>
                              {responsavel ? (
                                <span className="truncate font-medium">
                                  {responsavel.nome_completo ?? responsavel.email}
                                </span>
                              ) : (
                                <Badge variant="destructive">Sem responsável</Badge>
                              )}
                            </li>
                          )
                        })}
                      </ul>
                    )}
                  </div>
                )
              })}
            </div>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <div className="space-y-3">
          <Skeleton className="h-14" />
          <Skeleton className="h-14" />
        </div>
      ) : admins.length === 0 ? (
        <p className="text-sm text-muted-foreground">Nenhum utilizador registado.</p>
      ) : (
        <div className="space-y-3">
          {admins.map((a) => (
            <Card key={a.id}>
              <CardContent className="flex items-center gap-4 p-4">
                <div className="flex size-10 items-center justify-center rounded-full bg-primary/10 text-sm font-bold text-primary">
                  {siglaNome(a.nome_completo)}
                </div>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-medium">{a.nome_completo ?? '—'}</p>
                  <p className="truncate text-xs text-muted-foreground">{a.email}</p>
                  <p className="truncate text-[11px] text-muted-foreground">
                    {a.role === 'admin'
                      ? `${nomePolo(a.polo_id)} · ${
                          a.faculdade?.replace('Faculdade de ', '') ?? 'Sem faculdade'
                        }`
                      : 'Acesso global'}
                  </p>
                </div>
                <Badge variant="secondary" className="hidden sm:inline-flex">
                  {rotuloRole(a.role)}
                </Badge>
                <Select
                  value={a.role ?? 'admin'}
                  disabled={a.role === 'super_admin'}
                  onValueChange={(v) =>
                    mutations.atualizarNivel.mutate({
                      id: a.id,
                      role: v as Role,
                    })
                  }
                >
                  <SelectTrigger className="w-36">
                    <UserCog /> Nível
                  </SelectTrigger>
                  <SelectContent>
                    {ROLES_GESTAO.map((r) => (
                      <SelectItem key={r} value={r}>
                        {r === 'super_admin' ? 'Super Admin' : 'Admin'}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <Button
                  variant="ghost"
                  size="icon"
                  onClick={() => setAdminRemocao(a)}
                  className="text-destructive hover:bg-destructive/10"
                >
                  <Trash2 />
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <DialogCriar open={modalCriar} onClose={() => setModalCriar(false)} />
      <AlertDialog open={!!adminRemocao} onOpenChange={(open) => !open && setAdminRemocao(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remover administrador</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja remover <strong>{adminRemocao?.nome_completo ?? adminRemocao?.email}</strong>?
              Esta ação é irreversível.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              className="bg-destructive text-white hover:bg-destructive/90"
              disabled={mutations.remover.isPending}
              onClick={() => adminRemocao && mutations.remover.mutate(adminRemocao)}
            >
              {mutations.remover.isPending && <Loader2 className="animate-spin" />}
              Remover
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

function DialogCriar({ open, onClose }: { open: boolean; onClose: () => void }) {
  const queryClient = useQueryClient()
  const { profile } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [nome, setNome] = useState('')
  const [celular, setCelular] = useState('')
  const [poloId, setPoloId] = useState('')
  const [faculdade, setFaculdade] = useState('')
  const [role, setRole] = useState<Role>('admin')
  const [submitting, setSubmitting] = useState(false)

  const { data: polos = [] } = useQuery({
    queryKey: ['catalogo-polos'],
    queryFn: listarPolos,
    staleTime: 5 * 60 * 1000,
  })

  const { data: faculdades = [] } = useQuery({
    queryKey: ['catalogo-faculdades', poloId],
    queryFn: () => listarFaculdades(poloId),
    enabled: !!poloId,
    staleTime: 5 * 60 * 1000,
  })

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault()
    if (!celularValido(celular)) {
      toast.error('Celular inválido (ex: 87 000 0000)')
      return
    }
    if (role === 'admin' && (!poloId || !faculdade)) {
      toast.error('Selecione a delegação e a faculdade do administrador')
      return
    }
    setSubmitting(true)
    try {
      const emailCriado = email.trim().toLowerCase()
      await criarAdmin({
        email: emailCriado,
        password,
        nomeCompleto: nome.trim(),
        celular: celular.trim(),
        poloId: role === 'admin' ? poloId : undefined,
        faculdade: role === 'admin' ? faculdade : '',
        role,
      })
      await registrarAcesso({
        usuarioId: profile?.id ?? '',
        acao: 'Criação de administrador',
        recurso: 'administradores',
        registroId: emailCriado,
        detalhes: `${role} · ${nome.trim()}`,
      })
      toast.success('Utilizador criado com sucesso')
      queryClient.invalidateQueries({ queryKey: ['admins-lista'] })
      setEmail('')
      setPassword('')
      setNome('')
      setCelular('')
      setPoloId('')
      setFaculdade('')
      onClose()
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao criar utilizador')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>Criar utilizador</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label>Papel</Label>
            <Select
              value={role}
              onValueChange={(v) => {
                setRole(v as Role)
                setPoloId('')
                setFaculdade('')
              }}
            >
              <SelectTrigger className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="super_admin">Super Administrador</SelectItem>
                <SelectItem value="admin">Administrador</SelectItem>
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-2">
            <Label>Nome completo</Label>
            <Input value={nome} onChange={(e) => setNome(e.target.value)} required />
          </div>
          <div className="space-y-2">
            <Label>Email</Label>
            <Input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
          </div>
          <div className="space-y-2">
            <Label>Celular</Label>
            <Input
              value={celular}
              onChange={(e) => setCelular(e.target.value)}
              required
              inputMode="tel"
              placeholder="87 000 0000"
            />
            <p className="text-[11px] text-muted-foreground">
              Obrigatório para administradores (notificações e contacto).
            </p>
          </div>
          <div className="space-y-2">
            <Label>Palavra-passe</Label>
            <Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required minLength={6} />
          </div>
          {role === 'admin' ? (
            <>
              <div className="space-y-2">
                <Label>Delegação</Label>
                <Select
                  value={poloId}
                  onValueChange={(v) => {
                    setPoloId(v)
                    setFaculdade('')
                  }}
                >
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Selecione a delegação" />
                  </SelectTrigger>
                  <SelectContent>
                  {polos
                    .slice()
                    .sort((a, b) => {
                      if (a.principal && !b.principal) return -1
                      if (!a.principal && b.principal) return 1
                      if (a.id === 'licungo-ead' && b.id !== 'licungo-ead') return 1
                      if (b.id === 'licungo-ead' && a.id !== 'licungo-ead') return -1
                      return a.nome.localeCompare(b.nome)
                    })
                    .map((p) => (
                      <SelectItem key={p.id} value={p.id}>
                        {p.nome}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label>Faculdade</Label>
                <Select value={faculdade} onValueChange={setFaculdade} disabled={!poloId}>
                  <SelectTrigger className="w-full">
                    <SelectValue
                      placeholder={
                        poloId ? 'Selecione a faculdade' : 'Escolha primeiro a delegação'
                      }
                    />
                  </SelectTrigger>
                  <SelectContent className="max-h-72">
                    {faculdades.map((f) => (
                      <SelectItem key={f.id} value={f.nome}>
                        {f.nome.replace('Faculdade de ', '')}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-[11px] text-muted-foreground">
                  Este administrador verá apenas as denúncias desta faculdade na
                  delegação selecionada e ficará responsável pelas que ainda não
                  tenham responsável.
                </p>
              </div>
            </>
          ) : (
            <p className="rounded-md bg-muted p-3 text-xs text-muted-foreground">
              Super Administradores têm acesso global a todas as delegações e faculdades.
            </p>
          )}
          <Separator />
          <div className="flex justify-end gap-2">
            <Button type="button" variant="ghost" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" disabled={submitting}>
              {submitting && <Loader2 className="animate-spin" />}
              Criar
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  )
}

function celularValido(valor: string): boolean {
  const digitos = valor.replace(/\D/g, '')
  if (digitos.startsWith('258')) return /^2588[2-7]\d{7}$/.test(digitos)
  return /^8[2-7]\d{7}$/.test(digitos)
}
