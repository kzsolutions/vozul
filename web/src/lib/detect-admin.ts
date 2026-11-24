const IMAGENS = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/bmp', 'image/svg+xml']
const VIDEOS = ['video/mp4', 'video/quicktime', 'video/webm', 'video/ogg', 'video/x-msvideo']

export function classificacaoFicheiro(mime: string): 'imagem' | 'video' | 'audio' | 'pdf' | 'documento' {
  if (IMAGENS.includes(mime)) return 'imagem'
  if (VIDEOS.includes(mime)) return 'video'
  if (mime.startsWith('audio/')) return 'audio'
  if (mime === 'application/pdf') return 'pdf'
  if (mime.includes('word') || mime.includes('spreadsheet') || mime.includes('text/')) {
    return 'documento'
  }
  return 'documento'
}

export function isImagem(mime: string): boolean {
  return classificacaoFicheiro(mime) === 'imagem'
}

export function isVideo(mime: string): boolean {
  return classificacaoFicheiro(mime) === 'video'
}

export function isAudio(mime: string): boolean {
  return classificacaoFicheiro(mime) === 'audio'
}

export function isPdf(mime: string): boolean {
  return classificacaoFicheiro(mime) === 'pdf'
}