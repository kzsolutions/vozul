export function getAdminDashboardUrl() {
  const url = import.meta.env.VITE_ADMIN_DASHBOARD_URL as string | undefined
  if (url && url.length > 0) return url.replace(/\/$/, '')
  if (typeof window !== 'undefined' && ['localhost', '127.0.0.1'].includes(window.location.hostname)) {
    return 'http://localhost:5174'
  }
  return ''
}

export function getAdminHandoffUrl(token: string) {
  const base = getAdminDashboardUrl()
  const caminho = `${base}/handoff#token=${encodeURIComponent(token)}`
  if (!base) return caminho
  if (typeof window !== 'undefined') {
    try {
      return new URL(caminho, window.location.origin).toString()
    } catch {
      return caminho
    }
  }
  return caminho
}

export function isAdminDashboardSameOrigin() {
  const base = getAdminDashboardUrl()
  if (!base) return true
  if (typeof window === 'undefined') return false
  try {
    return new URL(base, window.location.origin).origin === window.location.origin
  } catch {
    return false
  }
}

