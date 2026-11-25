import { useState } from 'react'
import { Outlet } from 'react-router-dom'
import { Menu, X } from 'lucide-react'
import Sidebar from './Sidebar'
import Header from './Header'

export default function StudentLayout() {
  const [menuAberto, setMenuAberto] = useState(false)

  return (
    <div className="min-h-screen" style={{ background: '#F5F6FA' }}>
      <div className="hidden md:fixed md:inset-y-0 md:flex md:w-72">
        <Sidebar className="w-72" />
      </div>

      {menuAberto && (
        <div className="fixed inset-0 z-40 md:hidden">
          <button
            aria-label="Fechar menu"
            className="absolute inset-0 bg-black/40"
            onClick={() => setMenuAberto(false)}
          />
          <div className="relative h-full w-72 max-w-[85vw]">
            <Sidebar onNavigate={() => setMenuAberto(false)} />
            <button
              aria-label="Fechar menu"
              className="absolute right-3 top-4 rounded-md p-1 text-white/80 hover:bg-white/10 hover:text-white"
              onClick={() => setMenuAberto(false)}
            >
              <X className="h-5 w-5" />
            </button>
          </div>
        </div>
      )}

      <div className="flex min-w-0 flex-1 flex-col md:ml-72">
        <div className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b bg-white px-4 md:hidden">
          <button
            aria-label="Abrir menu"
            className="rounded-md p-2 text-gray-700 hover:bg-gray-100"
            onClick={() => setMenuAberto(true)}
          >
            <Menu className="h-5 w-5" />
          </button>
          <img src="/logo-unilicungo.jpg" alt="VozUL" className="h-8 w-8 rounded-full object-cover" />
          <span className="font-semibold text-gray-900">VozUL</span>
        </div>
        <Header />
        <main className="min-w-0 flex-1 p-4 md:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
