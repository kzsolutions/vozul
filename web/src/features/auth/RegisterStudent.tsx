import { useState, useEffect } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { FunctionsFetchError, FunctionsHttpError } from '@supabase/supabase-js'
import { supabase } from '../../config/supabase'
import { Mail, Lock, User, Phone, Hash, ArrowLeft, Info } from 'lucide-react'
import { colors } from '../../config/theme'
import { normalizarNumeroEstudante, validarNumeroEstudante, MSG_NUMERO_INVALIDO } from '../../lib/validators/studentNumber'

interface Polo { id: string; nome: string; principal: boolean }
interface Faculdade { id: string; nome: string; polo_id: string }
interface Curso { id: string; nome: string; faculdade_id: string }

export default function RegisterStudent() {
  const navigate = useNavigate()
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [numero, setNumero] = useState('')
  const [celular, setCelular] = useState('')
  const [password, setPassword] = useState('')
  const [confirm, setConfirm] = useState('')
  const [poloId, setPoloId] = useState('')
  const [faculdade, setFaculdade] = useState('')
  const [curso, setCurso] = useState('')
  const [polos, setPolos] = useState<Polo[]>([])
  const [faculdades, setFaculdades] = useState<Faculdade[]>([])
  const [cursos, setCursos] = useState<Curso[]>([])
  const [loading, setLoading] = useState(false)
  const [erro, setErro] = useState('')
  const [aviso, setAviso] = useState('')

  useEffect(() => {
    supabase.from('polos').select('id,nome,principal').eq('activo',true).order('principal',{ascending:false}).order('nome').then(({data})=>setPolos(data||[]))
  }, [])

  useEffect(() => {
    if (!poloId) return
    supabase.from('faculdades').select('id,nome,polo_id').eq('polo_id',poloId).eq('activo',true).order('nome').then(({data})=>setFaculdades(data||[]))
  }, [poloId])

  useEffect(() => {
    const f = faculdades.find(x=>x.nome===faculdade)
    if (!f) return
    supabase.from('cursos').select('id,nome,faculdade_id').eq('faculdade_id',f.id).eq('activo',true).order('nome').then(({data})=>setCursos(data||[]))
  }, [faculdade, faculdades])

  async function validarNumeroNoServidor(numeroEstudante: string) {
    try {
      const { data, error } = await supabase.functions.invoke('validar-estudante', {
        body: { numero: numeroEstudante, instituicao: 'licungo', polo: poloId || null },
      })
      if (error) {
        if (error instanceof FunctionsHttpError) {
          const corpo = await error.context.json().catch(() => null) as { mensagem?: string; erro?: string } | null
          if (corpo?.mensagem) return { valido: null, mensagem: corpo.mensagem }
          if (corpo?.erro === 'indisponivel') return { valido: null, mensagem: 'O sistema universitário está indisponível. Tente mais tarde.' }
        }
        if (error instanceof FunctionsFetchError) {
          return { valido: null, mensagem: 'Não foi possível validar o número de estudante. Verifique a sua ligação e tente novamente.' }
        }
        return { valido: null, mensagem: error.message }
      }
      const resposta = (data || {}) as { valido?: boolean | null; mensagem?: string }
      if (resposta.valido === true) return { valido: true, mensagem: resposta.mensagem || 'Número de estudante validado.' }
      if (resposta.valido === false) return { valido: false, mensagem: resposta.mensagem || MSG_NUMERO_INVALIDO }
      return { valido: null, mensagem: resposta.mensagem || 'Não foi possível validar o número de estudante. Tente novamente.' }
    } catch (err) {
      return { valido: null, mensagem: err instanceof Error ? err.message : 'Não foi possível validar o número de estudante.' }
    }
  }

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    setErro('')
    setAviso('')
    const numeroNormalizado = normalizarNumeroEstudante(numero)
    if (!validarNumeroEstudante(numeroNormalizado)) {
      setErro(MSG_NUMERO_INVALIDO)
      return
    }
    if (!poloId || !faculdade || !curso) { setErro('Selecione o campus, a faculdade e o curso.'); return }
    if (password !== confirm) { setErro('As palavras-passe não coincidem'); return }
    if (password.length < 6) { setErro('A palavra-passe deve ter pelo menos 6 caracteres'); return }
    setLoading(true)
    try {
      const validacao = await validarNumeroNoServidor(numeroNormalizado)
      if (validacao.valido === false) {
        setErro(validacao.mensagem)
        return
      }
      const pendente = validacao.valido === null

      const { error } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: { data: { role: 'estudante', nome_completo: nome.trim(), numero_estudante: numeroNormalizado, celular: celular.trim(), faculdade, curso, polo_id: poloId } }
      })
      if (error) throw error
      if (pendente) {
        setAviso(`${validacao.mensagem} Conta criada; a validação institucional ficará pendente.`)
        setTimeout(() => navigate('/login'), 1200)
        return
      }
      navigate('/login')
    } catch (err) {
      setErro(err instanceof Error ? err.message : 'Não foi possível concluir o registo.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen" style={{ background: '#F5F6FA' }}>
      <div className="px-4 py-4" style={{ background: colors.primario }}>
        <button onClick={()=>navigate(-1)} className="flex items-center gap-2 text-white"><ArrowLeft className="h-4 w-4"/> Voltar</button>
      </div>
      <div className="mx-auto max-w-2xl px-4 py-6">
        <div className="bg-white rounded-xl shadow border p-6" style={{ borderColor: colors.cinzaBorda }}>
          <div className="flex items-center gap-3 mb-4">
            <img src="/logo-unilicungo.jpg" alt="Universidade Licungo" className="h-10 w-10 rounded-full object-cover" />
            <h1 className="text-xl font-semibold" style={{ color: colors.primario }}>Registo de Estudante</h1>
          </div>
          <div className="mb-6 rounded-lg border p-4 flex items-start gap-3" style={{ borderColor: 'rgba(39,174,96,0.4)', background: '#f0fdf4' }}>
            <Info className="h-5 w-5 mt-0.5" style={{ color: colors.verde }} />
            <p className="text-sm" style={{ color: colors.verde }}>Os seus dados académicos são usados para verificar o seu vínculo à Universidade Licungo. Ao submeter uma denúncia, poderá escolher a modalidade anónima ou identificada, com confidencialidade conforme a opção escolhida.</p>
          </div>
          <form onSubmit={submit} className="space-y-4">
            <div>
              <label className="text-sm mb-1 block text-gray-700">Nome completo</label>
              <div className="relative"><User className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{color:colors.cinza}}/><input value={nome} onChange={e=>setNome(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}/></div>
            </div>
            <div>
              <label className="text-sm mb-1 block text-gray-700">Email</label>
              <div className="relative"><Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{color:colors.cinza}}/><input type="email" value={email} onChange={e=>setEmail(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}/></div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm mb-1 block text-gray-700">Número de estudante</label>
              <div className="relative"><Hash className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{color:colors.cinza}}/><input value={numero} onChange={e=>setNumero(e.target.value)} placeholder="05.1234.2026" required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}/></div>
              <p className="mt-1 text-xs text-gray-500">Formato esperado: 00.0000.0000. Enquanto a integração oficial não está ativa, são aceites números de teste com este formato (ex.: 05.1234.2026).</p>
              </div>
              <div>
                <label className="text-sm mb-1 block text-gray-700">Número de celular</label>
                <div className="relative"><Phone className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{color:colors.cinza}}/><input value={celular} onChange={e=>setCelular(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}/></div>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label className="text-sm mb-1 block text-gray-700">Campus / delegação</label>
                <select value={poloId} onChange={e=>{setPoloId(e.target.value); setFaculdade(''); setCurso('')}} className="w-full rounded-lg border p-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}>
                  <option value="">Selecionar...</option>
                  {polos.map(p=><option key={p.id} value={p.id}>{p.nome}</option>)}
                </select>
              </div>
              <div>
                <label className="text-sm mb-1 block text-gray-700">Faculdade</label>
                <select value={faculdade} onChange={e=>{setFaculdade(e.target.value); setCurso('')}} disabled={!poloId} className="w-full rounded-lg border p-2.5 bg-white disabled:bg-gray-50" style={{borderColor:colors.cinzaBorda}}>
                  <option value="">Selecionar...</option>
                  {faculdades.map(f=><option key={f.id} value={f.nome}>{f.nome}</option>)}
                </select>
              </div>
              <div>
                <label className="text-sm mb-1 block text-gray-700">Curso</label>
                <select value={curso} onChange={e=>setCurso(e.target.value)} disabled={!faculdade} className="w-full rounded-lg border p-2.5 bg-white disabled:bg-gray-50" style={{borderColor:colors.cinzaBorda}}>
                  <option value="">Selecionar...</option>
                  {cursos.map(c=><option key={c.id} value={c.nome}>{c.nome}</option>)}
                </select>
              </div>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="text-sm mb-1 block text-gray-700">Palavra-passe</label>
                <div className="relative"><Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{color:colors.cinza}}/><input type="password" value={password} onChange={e=>setPassword(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}/></div>
              </div>
              <div>
                <label className="text-sm mb-1 block text-gray-700">Confirmar palavra-passe</label>
                <div className="relative"><Lock className="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5" style={{color:colors.cinza}}/><input type="password" value={confirm} onChange={e=>setConfirm(e.target.value)} required className="w-full rounded-lg border pl-10 pr-3 py-2.5 bg-white" style={{borderColor:colors.cinzaBorda}}/></div>
              </div>
            </div>
            {erro && <p className="text-sm" style={{color:colors.vermelho}}>{erro}</p>}
            {aviso && <p className="text-sm" style={{color:colors.amarelo}}>{aviso}</p>}
            <button disabled={loading} className="w-full rounded-lg py-2.5 text-white font-semibold" style={{background:colors.primario}}>{loading?'A registar...':'Criar conta'}</button>
          </form>
          <div className="mt-4 text-center text-sm">Já tem conta? <Link to="/login" style={{color:colors.primario}}>Entrar</Link></div>
        </div>
      </div>
    </div>
  )
}
