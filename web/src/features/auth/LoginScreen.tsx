import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { supabase } from '../../config/supabase'
import { Mail, Lock } from 'lucide-react'
import { colors } from '../../config/theme'


export default function LoginScreen() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [erro, setErro] = useState('')

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setErro('')
    setLoading(true)
    try {
      const { data, error } = await supabase.auth.signInWithPassword({ email: email.trim(), password })
      if (error) throw error
      const user = data.user
      const sessao = data.session
      if (!user || !sessao) throw new Error('Sessão não disponível')
      const { data: perfil } = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single()
            if (perfil?.role === 'admin' || perfil?.role === 'super_admin') {
        navigate('/admin/dashboard')
        return
      }
      navigate('/student')

    } catch (err: any) {
      setErro(err.message)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center p-4" style={{ background: 'linear-gradient(180deg, ' + colors.primario + ' 0%, ' + colors.primarioEscuro + ' 100%)' }}>
      <div className="w-full max-w-md">
        <div className="text-center mb-6">
          <div className="flex justify-center mb-4">
            <img src="/logo-unilicungo.jpg" alt="Universidade Licungo" className="h-20 w-20 rounded-full object-cover border-4 border-white/20" />
          </div>
          <h1 className="text-3xl font-bold text-white">Bem-vindo ao VozUL</h1>
          <p className="text-white/90 mt-1">Voz da Universidade Licungo</p>
          <p className="text-white/80 text-sm mt-1">Canal seguro de denúncias académicas</p>
        </div>
        <div className="bg-white rounded-xl shadow-xl p-6" style={{ borderColor: colors.cinzaBorda }}>
          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <label className="text-sm mb-1 block text-gray-700">Email</label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{ color: colors.cinza }} />
                <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{ borderColor: colors.cinzaBorda }} />
              </div>
            </div>
            <div>
              <label className="text-sm mb-1 block text-gray-700">Palavra-passe</label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{ color: colors.cinza }} />
                <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{ borderColor: colors.cinzaBorda }} />
              </div>
              <button type="button" className="mt-1 text-sm" style={{ color: colors.primario }}>Esqueceu a senha?</button>
            </div>
            {erro && <p className="text-sm" style={{ color: colors.vermelho }}>{erro}</p>}
            <button disabled={loading} className="w-full rounded-lg py-2.5 text-white font-semibold" style={{ background: colors.primario }}>{loading ? 'A entrar...' : 'Entrar'}</button>
          </form>
          <div className="mt-4 text-center">
            <button onClick={() => navigate('/register-student')} className="text-sm font-semibold" style={{ color: colors.primario }}>Registar estudante</button>
          </div>
        </div>
        <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-3">
          <div className="bg-white/95 rounded-lg p-3">
            <p className="text-sm font-semibold" style={{ color: colors.primario }}>Informação de segurança</p>
            <p className="text-xs text-gray-600">Confidencialidade garantida</p>
          </div>
          <div className="bg-white/95 rounded-lg p-3">
            <p className="text-sm font-semibold" style={{ color: colors.primario }}>Proteção de dados</p>
            <p className="text-xs text-gray-600">Tratamento responsável das informações</p>
          </div>
        </div>
        <div className="mt-4 text-center text-xs text-white/80">VozUL v1.0.0</div>
      </div>
    </div>
  )
}
