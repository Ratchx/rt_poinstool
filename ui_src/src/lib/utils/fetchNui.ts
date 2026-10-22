const resourceName = (() => {
  // @ts-ignore
  return typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'poinstool'
})()

const TIMEOUT_MS = 15000

// @ts-ignore
export const inNui = typeof GetParentResourceName === 'function'

export const fetchNui = async <T = void>(eventName: string, data?: object): Promise<T | null> => {
  if (!inNui) return null

  const controller = new AbortController()
  const timer = window.setTimeout(() => controller.abort(), TIMEOUT_MS)

  try {
    const res = await fetch(`https://${resourceName}/${eventName}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data || {}),
      signal: controller.signal,
    })
    return (await res.json()) as T
  } catch {
    return null
  } finally {
    clearTimeout(timer)
  }
}
