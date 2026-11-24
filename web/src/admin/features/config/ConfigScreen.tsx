import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Loader2, Settings2 } from 'lucide-react'
import { toast } from 'sonner'
import { Button, Card, CardContent, Input, Skeleton } from '../../components/ui'
import { listarConfiguracoes, atualizarConfiguracao } from '../../lib/api/config'
import { formatarDataHora } from '../../lib/format'

export function ConfigScreen() {
  const queryClient = useQueryClient()
  const { data: configs, isLoading } = useQuery({
    queryKey: ['admin-config'],
    queryFn: listarConfiguracoes,
  })

  const mutation = useMutation({
    mutationFn: ({ id, valor }: { id: number; valor: string }) =>
      atualizarConfiguracao(id, valor),
    onSuccess: () => {
      toast.success('Configuração guardada')
      queryClient.invalidateQueries({ queryKey: ['admin-config'] })
    },
    onError: (e: Error) => toast.error(e.message),
  })

  return (
    <div className="mx-auto max-w-2xl space-y-4">
      {isLoading ? (
        <div className="space-y-3">
          <Skeleton className="h-16" />
          <Skeleton className="h-16" />
        </div>
      ) : !configs || configs.length === 0 ? (
        <Card>
          <CardContent className="flex flex-col items-center gap-3 p-10 text-center">
            <Settings2 className="size-10 text-muted-foreground" />
            <p className="font-medium">Sem configurações</p>
          </CardContent>
        </Card>
      ) : (
        configs.map((c) => (
          <Card key={c.id}>
            <CardContent className="p-4">
              <p className="font-medium">{c.chave}</p>
              {c.descricao && (
                <p className="mt-0.5 text-xs text-muted-foreground">{c.descricao}</p>
              )}
              <div className="mt-3 flex items-center gap-2">
                <Input
                  defaultValue={c.valor}
                  key={c.valor}
                  disabled={mutation.isPending}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      mutation.mutate({ id: c.id, valor: (e.target as HTMLInputElement).value })
                    }
                  }}
                  onBlur={(e) => {
                    if (e.target.value !== c.valor) {
                      mutation.mutate({ id: c.id, valor: e.target.value })
                    }
                  }}
                />
                <Button variant="ghost" size="icon" disabled>
                  <Loader2 className="size-4" />
                </Button>
              </div>
              <p className="mt-2 text-[11px] text-muted-foreground">
                Atualizada em {formatarDataHora(c.updated_at)}
              </p>
            </CardContent>
          </Card>
        ))
      )}
    </div>
  )
}