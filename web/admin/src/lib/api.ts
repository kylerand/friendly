type RequestOptions = RequestInit & { body?: string }

const baseUrl = (import.meta.env.VITE_ADMIN_API_URL as string | undefined)?.replace(/\/$/, '') ?? ''

export async function adminFetch<T>(
  path: string,
  accessToken: string,
  options: RequestOptions = {},
): Promise<T> {
  if (!baseUrl) {
    throw new Error('Missing VITE_ADMIN_API_URL')
  }

  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`,
      ...(options.headers ?? {}),
    },
  })

  if (!response.ok) {
    let detail = `${response.status} ${response.statusText}`
    try {
      const body = await response.json()
      detail = body?.detail ?? detail
    } catch (err) {
      // ignore parse error
    }
    throw new Error(detail)
  }

  if (response.status === 204) {
    return {} as T
  }

  return response.json() as Promise<T>
}
