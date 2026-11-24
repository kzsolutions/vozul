import { useEffect, useState } from 'react'
import { useLocation } from 'react-router-dom'
import { supabase } from '../config/supabase'
import { useAuth } from '../contexts/AuthContext'

export function useNaoLidas(): number {
  const { user } = useAuth()
  const location = useLocation()
  const [naoLidas, setNaoLidas] = useState(0)

  useEffect(() => {
    if (!user?.id) {
      setNaoLidas(0)
      return
    }

    let ativo = true

    async function carregar() {
      const { data } = await supabase.rpc('listar_minhas_denuncias')
      if (!ativo) return
      const total = ((data as any[]) ?? []).reduce(
        (soma, item) => soma + Number(item?.nao_lidas ?? 0),
        0,
      )
      setNaoLidas(total)
    }

    carregar()
    const intervalo = setInterval(carregar, 60000)
    return () => {
      ativo = false
      clearInterval(intervalo)
    }
  }, [user?.id, location.pathname])

  return naoLidas
}
