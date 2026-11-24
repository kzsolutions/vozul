import { Navigate, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { Toaster } from 'sonner'
import { RequireAuth, RequireSuper } from './lib/guards'
import { AppLayout } from './components/layout/AppLayout'
import { DashboardScreen } from './features/dashboard/DashboardScreen'
import { DenunciasListScreen } from './features/denuncias/DenunciasListScreen'
import { DenunciaDetailScreen } from './features/denuncias/DenunciaDetailScreen'
import { MensagensListScreen } from './features/mensagens/MensagensListScreen'
import { ChatScreen } from './features/mensagens/ChatScreen'
import { AdminsScreen } from './features/admins/AdminsScreen'
import { PermissoesScreen } from './features/permissoes/PermissoesScreen'
import { AuditoriaScreen } from './features/auditoria/AuditoriaScreen'
import { RelatoriosScreen } from './features/relatorios/RelatoriosScreen'
import { PerfilScreen } from './features/perfil/PerfilScreen'
import { ConfigScreen } from './features/config/ConfigScreen'

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, refetchOnWindowFocus: false, staleTime: 30_000 } },
})

export default function AdminApp() {
  return (
    <QueryClientProvider client={queryClient}>
      <div className="admin-shell min-h-screen">
        <Routes>
          <Route element={<RequireAuth />}>
            <Route element={<AppLayout />}>
              <Route index element={<Navigate to="dashboard" replace />} />
              <Route path="dashboard" element={<DashboardScreen />} />
              <Route path="denuncias" element={<DenunciasListScreen />} />
              <Route path="denuncias/:id" element={<DenunciaDetailScreen />} />
              <Route path="mensagens" element={<MensagensListScreen />} />
              <Route path="mensagens/:id" element={<ChatScreen />} />
              <Route path="administradores" element={<RequireSuper><AdminsScreen /></RequireSuper>} />
              <Route path="permissoes" element={<RequireSuper><PermissoesScreen /></RequireSuper>} />
              <Route path="auditoria" element={<RequireSuper><AuditoriaScreen /></RequireSuper>} />
              <Route path="relatorios" element={<RelatoriosScreen />} />
              <Route path="perfil" element={<PerfilScreen />} />
              <Route path="configuracoes" element={<RequireSuper><ConfigScreen /></RequireSuper>} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="dashboard" replace />} />
        </Routes>
      </div>
      <Toaster richColors position="top-right" />
    </QueryClientProvider>
  )
}