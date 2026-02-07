import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseServiceRoleKey = import.meta.env.VITE_SUPABASE_SERVICE_ROLE_KEY as string

if (!supabaseUrl || !supabaseServiceRoleKey) {
  throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_SERVICE_ROLE_KEY')
}

export const supabase = createClient(supabaseUrl, supabaseServiceRoleKey)

export async function invokeConfirmGroup(params: {
  group_id: string
  venue_id: string
  chat_open_at: string
  goal_close_at: string
  feedback_sent_at: string
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
