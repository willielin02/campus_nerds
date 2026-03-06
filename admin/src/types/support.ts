export type TicketCategory = 'school_verification' | 'payment' | 'bug_report' | 'other'
export type TicketStatus = 'open' | 'in_progress' | 'resolved' | 'closed'
export type SenderType = 'user' | 'admin'

export interface SupportTicket {
  id: string
  user_id: string
  category: TicketCategory
  subject: string
  status: TicketStatus
  created_at: string
  updated_at: string
  resolved_at: string | null
}

export interface SupportMessage {
  id: string
  ticket_id: string
  sender_type: SenderType
  sender_id: string
  content: string | null
  image_path: string | null
  created_at: string
}

export interface TicketWithUser extends SupportTicket {
  user_nickname: string | null
  user_gender: string | null
  university_name: string | null
}

export const TICKET_CATEGORY_LABELS: Record<TicketCategory, string> = {
  school_verification: '學校驗證',
  payment: '付款問題',
  bug_report: 'Bug 回報',
  other: '其他',
}

export const TICKET_STATUS_LABELS: Record<TicketStatus, string> = {
  open: '待處理',
  in_progress: '處理中',
  resolved: '已解決',
  closed: '已關閉',
}

export const TICKET_STATUS_COLORS: Record<TicketStatus, string> = {
  open: 'bg-amber-100 text-amber-800',
  in_progress: 'bg-blue-100 text-blue-800',
  resolved: 'bg-emerald-100 text-emerald-800',
  closed: 'bg-gray-100 text-gray-500',
}
