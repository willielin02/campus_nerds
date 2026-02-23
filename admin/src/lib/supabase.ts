import { createClient } from '@supabase/supabase-js'

const ENV_KEY = 'admin_env'

export type AdminEnv = 'dev' | 'prod'

export function getAdminEnv(): AdminEnv {
  try {
    return (localStorage.getItem(ENV_KEY) as AdminEnv) || 'dev'
  } catch {
    return 'dev'
  }
}

export function switchAdminEnv(env: AdminEnv) {
  localStorage.setItem(ENV_KEY, env)
  window.location.reload()
}

const env = getAdminEnv()

const supabaseUrl = env === 'prod'
  ? import.meta.env.VITE_PROD_SUPABASE_URL as string
  : import.meta.env.VITE_DEV_SUPABASE_URL as string

const supabaseServiceRoleKey = env === 'prod'
  ? import.meta.env.VITE_PROD_SUPABASE_SERVICE_ROLE_KEY as string
  : import.meta.env.VITE_DEV_SUPABASE_SERVICE_ROLE_KEY as string

if (!supabaseUrl || !supabaseServiceRoleKey) {
  throw new Error(
    `Missing Supabase credentials for ${env} environment. ` +
    `Check VITE_${env.toUpperCase()}_SUPABASE_URL and VITE_${env.toUpperCase()}_SUPABASE_SERVICE_ROLE_KEY`
  )
}

export const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function invokeConfirmGroup(params: {
  group_id: string
}) {
  const res = await fetch(`${supabaseUrl}/functions/v1/confirm-group`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${supabaseServiceRoleKey}`,
    },
    body: JSON.stringify(params),
  })
  return res.json()
}