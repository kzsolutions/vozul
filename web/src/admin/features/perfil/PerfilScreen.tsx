import { useState } from 'react'
import type { FormEvent } from 'react'
import { useQueryClient } from '@tanstack/react-query'
import { Loader2, Save, Shield } from 'lucide-react'
import { toast } from 'sonner'
import {
  Avatar,
  AvatarFallback,
  Button,
  Card,
  CardContent,
  Input,
  Label,
  Separator,
} from '../../components/ui'
import { useAuth } from '../../lib/auth'
import { atualizarPerfil } from '../../lib/api/profiles'
import { rotuloRole, siglaNome } from '../../lib/format'

export function PerfilScreen() {
  const { profile, refreshProfile } = useAuth()
  const queryClient = useQueryClient()
  const [nome, setNome] = useState(profile?.nome_completo ?? '')
  const [celular, setCelular] = useState(profile?.celular ?? '')
  const [submitting, setSubmitting] = useState(false)

  const salvar = async (e: FormEvent) => {
    e.preventDefault()
    if (!profile) return
    setSubmitting(true)
    try {
      await atualizarPerfil(profile.id, { nome_completo: nome.trim(), celular: celular.trim() })
      await refreshProfile()
      queryClient.setQueryData(['historico-lista'], undefined)
      toast.success('Perfil atualizado')
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao atualizar perfil')
    } finally {
      setSubmitting(false)
    }
  }

  if (!profile) return null

  return (
    <div className="mx-auto max-w-2xl space-y-4">
      <Card>
        <CardContent className="flex flex-col items-center gap-4 p-6 text-center">
          <Avatar className="size-20">
            <AvatarFallback className="bg-primary/10 text-2xl text-primary">
              {siglaNome(profile.nome_completo)}
            </AvatarFallback>
          </Avatar>
          <div>
            <h2 className="text-lg font-bold">{profile.nome_completo ?? 'Administrador'}</h2>
            <p className="text-sm text-muted-foreground">{profile.email}</p>
          </div>
          <div className="flex items-center gap-2 rounded-full bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
            <Shield className="size-3.5" /> {rotuloRole(profile.role)}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="p-6">
          <form onSubmit={salvar} className="space-y-4">
            <div className="space-y-2">
              <Label>Nome completo</Label>
              <Input value={nome} onChange={(e) => setNome(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>Celular</Label>
              <Input value={celular} onChange={(e) => setCelular(e.target.value)} placeholder="84 000 0000" />
            </div>
            <div className="space-y-2">
              <Label>Email</Label>
              <Input value={profile.email ?? ''} disabled />
            </div>
            <div className="space-y-2">
              <Label>Faculdade</Label>
              <Input value={profile.faculdade ?? '—'} disabled />
            </div>
            <Separator />
            <div className="flex justify-end">
              <Button type="submit" disabled={submitting}>
                {submitting ? <Loader2 className="animate-spin" /> : <Save />}
                Guardar alterações
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}