import { useNavigate } from 'react-router-dom'
import { ChevronRight, Database, Hash, Scale, ShieldCheck } from 'lucide-react'

const azul = '#0B3D91'
const azulClaro = '#EEF4FF'
const cinzaBorda = '#E5E7EB'

const garantias = [
  {
    titulo: 'Anónima ou Identificada',
    texto: 'O estudante escolhe a modalidade da denúncia. Na denúncia anónima, a autoria não é associada ao relato.',
    icon: ShieldCheck,
  },
  {
    titulo: 'Vínculo Académico Verificado',
    texto: 'O registo e a validação confirmam a ligação à Universidade Licungo, garantindo autenticidade e legitimidade.',
    icon: Scale,
  },
  {
    titulo: 'Código Único',
    texto: 'Acompanhe o seu caso com um código único, preservando a confidencialidade conforme a modalidade escolhida.',
    icon: Hash,
  },
  {
    titulo: 'Dados Protegidos',
    texto: 'Criptografia e acesso restrito protegem dados pessoais e evidências.',
    icon: Database,
  },
]

export default function Landing() {
  const navigate = useNavigate()

  return (
    <div className="min-h-screen bg-white">
      <header className="sticky top-0 z-20 border-b bg-white" style={{ borderColor: cinzaBorda }}>
        <div className="mx-auto flex max-w-6xl flex-wrap items-center justify-between gap-3 px-6 py-4">
          <a href="#inicio" className="flex items-center gap-3">
            <img src="/logo-unilicungo.jpg" alt="Universidade Licungo" className="h-10 w-10 rounded-full object-cover" />
            <div>
              <p className="text-lg font-bold leading-none" style={{ color: azul }}>VozUL</p>
              <p className="mt-1 text-[11px] text-gray-500">Universidade Licungo</p>
            </div>
          </a>

          <nav className="flex flex-wrap items-center justify-end gap-3 text-xs md:gap-8 md:text-sm">
            <a href="#inicio" className="font-medium text-gray-600 hover:text-gray-900">Início</a>
            <a href="#sobre" className="font-medium text-gray-600 hover:text-gray-900">Sobre</a>
            <button
              onClick={() => navigate('/register-student')}
              className="font-medium text-gray-600 hover:text-gray-900"
            >
              Cadastrar-se
            </button>
            <button
              onClick={() => navigate('/login')}
              className="rounded-lg px-4 py-2 font-semibold text-white transition hover:opacity-90"
              style={{ background: azul }}
            >
              Entrar
            </button>
          </nav>
        </div>
      </header>

      <main>
        <section id="inicio" style={{ background: azulClaro }}>
          <div className="mx-auto grid max-w-6xl gap-12 px-6 py-16 md:grid-cols-[1.2fr_0.8fr] md:items-center md:py-24">
            <div>
                <span
                  className="inline-flex items-center gap-2 rounded-full bg-white px-3 py-1 text-xs font-semibold shadow-sm"
                  style={{ color: azul }}
                >
                  <ShieldCheck className="h-4 w-4" />
                  Plataforma para a comunidade académica
                </span>

              <h1 className="mt-6 text-4xl font-bold leading-tight md:text-5xl" style={{ color: azul }}>
                A sua voz importa.
                <br />
                Denuncie com segurança.
              </h1>

                <p className="mt-5 max-w-2xl text-base leading-relaxed text-gray-600 md:text-lg">
                  A VozUL é uma plataforma de denúncias académicas desenvolvida para a comunidade da
                  Universidade Licungo, para denúncias <strong>anónimas ou identificadas</strong>,
                  conforme a escolha do estudante, sobre assédio, corrupção académica, abuso de poder,
                  discriminação e outras condutas inadequadas. O sistema verifica o vínculo académico à
                  Universidade Licungo para apoiar autenticidade e legitimidade, preservando a
                  confidencialidade conforme a modalidade escolhida e os controlos implementados.
                </p>

              <div className="mt-8 flex flex-wrap gap-3">
                <button
                  onClick={() => navigate('/register-student')}
                  className="inline-flex items-center gap-2 rounded-lg px-6 py-3 text-sm font-semibold text-white shadow-sm transition hover:opacity-90"
                  style={{ background: azul }}
                >
                  Cadastrar-se
                  <ChevronRight className="h-4 w-4" />
                </button>
                <button
                  onClick={() => navigate('/login')}
                  className="rounded-lg border bg-white px-6 py-3 text-sm font-semibold transition hover:bg-gray-50"
                  style={{ borderColor: azul, color: azul }}
                >
                  Entrar
                </button>
              </div>
            </div>

            <div className="rounded-2xl border bg-white p-7 shadow-sm" style={{ borderColor: '#DCE6F7' }}>
              <div
                className="flex h-12 w-12 items-center justify-center rounded-full"
                style={{ background: azulClaro, color: azul }}
              >
                <ShieldCheck className="h-6 w-6" />
              </div>
              <h2 className="mt-5 text-xl font-bold" style={{ color: azul }}>
                Confidencialidade e legitimidade
              </h2>
                <p className="mt-3 text-sm leading-relaxed text-gray-600">
                  O VozUL verifica o vínculo académico à Universidade Licungo para apoiar a autenticidade
                  das denúncias. O estudante escolhe se a denúncia será anónima ou identificada.
                </p>
                <ul className="mt-5 space-y-2 text-sm text-gray-600">
                  {['Denúncia anónima ou identificada, à escolha do estudante', 'Verificação do vínculo académico à Universidade Licungo', 'Confidencialidade tratada conforme a modalidade escolhida e controlos de acesso'].map((item) => (
                  <li key={item} className="flex items-start gap-2">
                    <span className="mt-1.5 h-1.5 w-1.5 rounded-full" style={{ background: azul }} />
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </section>

        <section id="sobre" className="bg-white py-16">
          <div className="mx-auto max-w-6xl px-6">
            <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
              {garantias.map((garantia) => {
                const Icon = garantia.icon
                return (
                  <article
                    key={garantia.titulo}
                    className="rounded-xl border bg-white p-6 text-center shadow-sm"
                    style={{ borderColor: cinzaBorda }}
                  >
                    <div
                      className="mx-auto flex h-12 w-12 items-center justify-center rounded-full"
                      style={{ background: azulClaro, color: azul }}
                    >
                      <Icon className="h-6 w-6" />
                    </div>
                    <h3 className="mt-4 font-bold" style={{ color: azul }}>{garantia.titulo}</h3>
                    <p className="mt-2 text-sm leading-relaxed text-gray-600">{garantia.texto}</p>
                  </article>
                )
              })}
            </div>
          </div>
        </section>

        <section className="py-14" style={{ background: azulClaro }}>
          <div className="mx-auto max-w-3xl px-6 text-center">
            <h2 className="text-2xl font-bold md:text-3xl" style={{ color: azul }}>
              Precisa de apoio?
            </h2>
            <p className="mt-3 text-sm leading-relaxed text-gray-600 md:text-base">
              Se está a viver uma situação difícil, procure também apoio psicológico ou jurídico na
              sua instituição.
            </p>
            <p className="mt-5 text-sm font-semibold" style={{ color: azul }}>
              Gabinete de Apoio ao Estudante — Universidade Licungo
            </p>
          </div>
        </section>
      </main>

      <footer className="bg-gray-100 py-6">
        <div className="mx-auto max-w-6xl px-6 text-center text-xs text-gray-500">
          <p>© 2026 VozUL — Universidade Licungo. Todos os direitos reservados.</p>
        </div>
      </footer>
    </div>
  )
}
