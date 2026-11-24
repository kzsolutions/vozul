import { Navigate, Route, Routes } from 'react-router-dom'
import LoginScreen from './features/auth/LoginScreen'
import RegisterStudent from './features/auth/RegisterStudent'
import ProtectedRoute from './routes/ProtectedRoute'
import RoleRoute from './routes/RoleRoute'
import StudentLayout from './components/layout/StudentLayout'
import StudentHome from './features/student/StudentHome'
import DenunciaForm from './features/student/DenunciaForm'
import Acompanhar from './features/student/Acompanhar'
import Mensagens from './features/student/Mensagens'
import Chat from './features/student/Chat'
import Perfil from './features/student/Perfil'
import Landing from './features/public/Landing'
import { useAuth } from './contexts/AuthContext'
import AdminApp from './admin/App'

function RootRedirect() {
  const { user, profile, loading } = useAuth()
  if (loading) return <div className='flex h-screen items-center justify-center'>A carregar...</div>
  if (!user) return <Landing />
  if (profile?.role === 'estudante') return <Navigate to='/student' replace />
  if (profile?.role === 'admin' || profile?.role === 'super_admin') return <Navigate to='/admin/dashboard' replace />
  return <Landing />
}

export default function App() {
  return (
    <Routes>
      <Route path='/' element={<RootRedirect />} />
      <Route path='/login' element={<LoginScreen />} />
      <Route path='/register-student' element={<RegisterStudent />} />
      <Route path='/register/student' element={<RegisterStudent />} />
      <Route path='/acompanhar' element={<Acompanhar publico />} />
      <Route element={<ProtectedRoute />}>
        <Route element={<RoleRoute allowed={['estudante']} />}>
          <Route element={<StudentLayout />}>
            <Route path='/student' element={<StudentHome />} />
            <Route path='/student/denuncia' element={<DenunciaForm />} />
            <Route path='/student/acompanhamento' element={<Acompanhar />} />
            <Route path='/student/mensagens' element={<Mensagens />} />
            <Route path='/student/chat' element={<Chat />} />
            <Route path='/student/perfil' element={<Perfil />} />
          </Route>
        </Route>
      </Route>
      <Route path='/admin/*' element={<AdminApp />} />
      <Route path='*' element={<Navigate to='/' replace />} />
    </Routes>
  )
}
