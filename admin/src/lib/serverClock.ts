import { supabase } from './supabase'

/**
 * Server clock utility that syncs with Supabase mock time.
 * Equivalent to Flutter's AppClock — calls get_server_now() RPC on init,
 * stores the offset, and provides a now() that respects mock time.
 */

let offsetMs = 0
let synced = false

/** Sync the clock offset with the Supabase server. Call once on app load. */
export async function syncServerClock(): Promise<void> {
  try {
    const { data, error } = await supabase.rpc('get_server_now')
    if (error || !data) return

    const serverNow = new Date(data as string).getTime()
    offsetMs = serverNow - Date.now()
    synced = true
  } catch {
    // If sync fails, use browser time (offset stays 0)
    offsetMs = 0
  }
}

/** Current time adjusted by the server offset. Use instead of new Date(). */
export function serverNow(): Date {
  return new Date(Date.now() + offsetMs)
}

/** Whether the clock has been synced with the server. */
export function isClockSynced(): boolean {
  return synced
}
