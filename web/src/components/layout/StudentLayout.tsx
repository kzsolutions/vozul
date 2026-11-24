import { Outlet } from 'react-router-dom'
import Sidebar from './Sidebar'
import Header from './Header'

export default function StudentLayout() {
  return (
    <div className="min-h-screen" style={{ background: '#F5F6FA' }}>
      <Sidebar />
      <div className="ml-72">
        <Header />
        <main className="p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}
