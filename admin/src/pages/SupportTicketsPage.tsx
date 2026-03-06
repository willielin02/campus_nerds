import { useEffect, useState, useRef } from 'react'
import { supabase, invokeSendUserPush } from '../lib/supabase'
import { formatDateTime } from '../lib/date'
import type { University } from '../types/database'
import type {
  SupportTicket,
  SupportMessage,
  TicketCategory,
  TicketStatus,
} from '../types/support'
import {
  TICKET_CATEGORY_LABELS,
  TICKET_STATUS_LABELS,
  TICKET_STATUS_COLORS,
} from '../types/support'

interface TicketUser {
  id: string
  nickname: string | null
  gender: string | null
  university_name: string | null
  school_email_status: string | null
}

export default function SupportTicketsPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null)
  const [ticketUser, setTicketUser] = useState<TicketUser | null>(null)
  const [messages, setMessages] = useState<SupportMessage[]>([])
  const [messageImageUrls, setMessageImageUrls] = useState<Record<string, string>>({})
  const [replyText, setReplyText] = useState('')
  const [sending, setSending] = useState(false)
  const [statusFilter, setStatusFilter] = useState<TicketStatus | ''>('')
  const [categoryFilter, setCategoryFilter] = useState<TicketCategory | ''>('')

  // School verification quick action
  const [universities, setUniversities] = useState<University[]>([])
  const [selectedUniversityId, setSelectedUniversityId] = useState('')
  const [verifying, setVerifying] = useState(false)

  const messagesEndRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    loadTickets()
    loadUniversities()
  }, [])

  async function loadTickets() {
    setLoading(true)
    const { data } = await supabase
      .from('support_tickets')
      .select('*')
      .order('updated_at', { ascending: false })
    setTickets((data as unknown as SupportTicket[]) || [])
    setLoading(false)
  }

  async function loadUniversities() {
    const { data } = await supabase
      .from('universities')
      .select('id, name, code')
      .order('code', { ascending: true })
    setUniversities((data as unknown as University[]) || [])
  }

  async function selectTicket(ticket: SupportTicket) {
    setSelectedTicket(ticket)
    setReplyText('')
    setSelectedUniversityId('')

    // Load user info
    const { data: userData } = await supabase
      .from('user_profile_v')
      .select('id, nickname, gender, university_name, school_email_status')
      .eq('id', ticket.user_id)
      .single()
    setTicketUser(userData as unknown as TicketUser | null)

    // Load messages
    const { data: msgData } = await supabase
      .from('support_messages')
      .select('*')
      .eq('ticket_id', ticket.id)
      .order('created_at', { ascending: true })
    const msgs = (msgData as unknown as SupportMessage[]) || []
    setMessages(msgs)

    // Load signed URLs for images
    const urls: Record<string, string> = {}
    for (const msg of msgs) {
      if (msg.image_path) {
        const { data: urlData } = await supabase.storage
          .from('support-attachments')
          .createSignedUrl(msg.image_path, 3600)
        if (urlData?.signedUrl) {
          urls[msg.id] = urlData.signedUrl
        }
      }
    }
    setMessageImageUrls(urls)

    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
  }

  async function handleStatusChange(newStatus: TicketStatus) {
    if (!selectedTicket) return
    const label = TICKET_STATUS_LABELS[newStatus]
    if (!confirm(`確定將工單狀態改為「${label}」嗎？`)) return

    const updates: Record<string, unknown> = { status: newStatus }
    if (newStatus === 'resolved') {
      updates.resolved_at = new Date().toISOString()
    }

    await supabase
      .from('support_tickets')
      .update(updates)
      .eq('id', selectedTicket.id)

    await loadTickets()
    setSelectedTicket({ ...selectedTicket, status: newStatus })
  }

  async function handleSendReply() {
    if (!selectedTicket || !replyText.trim()) return
    setSending(true)

    // Get admin user ID (first admin-like user, or use a placeholder)
    // Service role inserts bypass RLS, so sender_id can be any valid UUID
    const { data: adminUser } = await supabase
      .from('users')
      .select('id')
      .limit(1)
      .single()

    const senderId = adminUser?.id || selectedTicket.user_id

    const { data: newMsg } = await supabase
      .from('support_messages')
      .insert({
        ticket_id: selectedTicket.id,
        sender_type: 'admin',
        sender_id: senderId,
        content: replyText.trim(),
      })
      .select()
      .single()

    if (newMsg) {
      setMessages((prev) => [...prev, newMsg as unknown as SupportMessage])
    }

    // Update status to in_progress if still open
    if (selectedTicket.status === 'open') {
      await supabase
        .from('support_tickets')
        .update({ status: 'in_progress' })
        .eq('id', selectedTicket.id)
      setSelectedTicket({ ...selectedTicket, status: 'in_progress' })
    }

    // Send push notification
    try {
      await invokeSendUserPush({
        user_id: selectedTicket.user_id,
        title: '客服回覆',
        body: replyText.trim().length > 50
          ? replyText.trim().substring(0, 50) + '...'
          : replyText.trim(),
        data: { type: 'support_reply', ticket_id: selectedTicket.id },
      })
    } catch (e) {
      console.warn('推播通知發送失敗:', e)
    }

    setReplyText('')
    setSending(false)
    await loadTickets()
    setTimeout(() => messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
  }

  async function handleManualVerify(e: React.FormEvent) {
    e.preventDefault()
    if (!selectedTicket || !ticketUser || !selectedUniversityId) return

    const uniName = universities.find((u) => u.id === selectedUniversityId)?.name || ''
    if (!confirm(`確定要手動驗證此用戶為「${uniName}」的學生嗎？`)) return

    setVerifying(true)

    const { data: domainRow, error: domainError } = await supabase
      .from('university_email_domains')
      .select('domain')
      .eq('university_id', selectedUniversityId)
      .limit(1)
      .single()

    if (domainError || !domainRow) {
      alert('找不到該大學的 email domain')
      setVerifying(false)
      return
    }

    const prefix = ticketUser.id.replace(/-/g, '').substring(0, 8)
    const manualEmail = `manual.${prefix}@${domainRow.domain}`

    await supabase
      .from('user_school_emails')
      .update({
        is_active: false,
        released_at: new Date().toISOString(),
        released_reason: 'manual_verification_replacement',
      })
      .eq('user_id', ticketUser.id)
      .eq('is_active', true)

    const { error } = await supabase
      .from('user_school_emails')
      .insert({
        user_id: ticketUser.id,
        school_email: manualEmail,
        status: 'verified',
        verified_at: new Date().toISOString(),
        is_active: true,
        verification_method: 'manual',
      })

    if (error) {
      alert(`驗證失敗: ${error.message}`)
    } else {
      // Close the ticket
      await supabase
        .from('support_tickets')
        .update({ status: 'resolved', resolved_at: new Date().toISOString() })
        .eq('id', selectedTicket.id)

      // Send auto-reply message
      const { data: adminUser } = await supabase
        .from('users')
        .select('id')
        .limit(1)
        .single()

      await supabase
        .from('support_messages')
        .insert({
          ticket_id: selectedTicket.id,
          sender_type: 'admin',
          sender_id: adminUser?.id || ticketUser.id,
          content: `已完成學校驗證（${uniName}）。此工單已自動結案。`,
        })

      // Send push notification
      try {
        await invokeSendUserPush({
          user_id: ticketUser.id,
          title: '學校驗證完成',
          body: '您的學校身分已驗證成功！現在可以開始報名活動了。',
          data: { type: 'school_verified' },
        })
      } catch (e) {
        console.warn('推播通知發送失敗:', e)
      }

      alert('手動驗證成功！工單已自動結案。')
      setSelectedUniversityId('')
      await loadTickets()
      // Refresh detail
      await selectTicket({ ...selectedTicket, status: 'resolved' })
    }
    setVerifying(false)
  }

  // Filter tickets
  const displayTickets = tickets.filter((t) => {
    if (statusFilter && t.status !== statusFilter) return false
    if (categoryFilter && t.category !== categoryFilter) return false
    return true
  })

  const isClosed = selectedTicket?.status === 'resolved' || selectedTicket?.status === 'closed'

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-6">客服工單</h2>

      {/* Filters */}
      <div className="flex gap-4 mb-6">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as TicketStatus | '')}
          className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
        >
          <option value="">全部狀態</option>
          {(Object.entries(TICKET_STATUS_LABELS) as [TicketStatus, string][]).map(([k, v]) => (
            <option key={k} value={k}>{v}</option>
          ))}
        </select>
        <select
          value={categoryFilter}
          onChange={(e) => setCategoryFilter(e.target.value as TicketCategory | '')}
          className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
        >
          <option value="">全部分類</option>
          {(Object.entries(TICKET_CATEGORY_LABELS) as [TicketCategory, string][]).map(([k, v]) => (
            <option key={k} value={k}>{v}</option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* Ticket list */}
        <div>
          {loading ? (
            <div className="text-center py-8 text-secondary-text text-sm">載入中...</div>
          ) : displayTickets.length > 0 ? (
            <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
              <div className="px-4 py-2 bg-alternate/50 text-xs font-medium text-secondary-text">
                工單列表 ({displayTickets.length})
              </div>
              <div className="max-h-[calc(100vh-240px)] overflow-y-auto">
                {displayTickets.map((ticket) => (
                  <div
                    key={ticket.id}
                    onClick={() => selectTicket(ticket)}
                    className={`px-4 py-3 border-b border-tertiary last:border-0 cursor-pointer hover:bg-alternate/30 transition-colors ${
                      selectedTicket?.id === ticket.id ? 'bg-alternate' : ''
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium flex-1 truncate">{ticket.subject}</p>
                      <span className={`text-[11px] px-1.5 py-0.5 rounded shrink-0 ${TICKET_STATUS_COLORS[ticket.status]}`}>
                        {TICKET_STATUS_LABELS[ticket.status]}
                      </span>
                    </div>
                    <p className="text-xs text-tertiary-text mt-0.5">
                      {TICKET_CATEGORY_LABELS[ticket.category]} · {formatDateTime(ticket.updated_at)}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-secondary-text text-sm">
              尚無工單
            </div>
          )}
        </div>

        {/* Ticket detail */}
        <div>
          {selectedTicket && (
            <div className="space-y-4">
              {/* User info */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-2">用戶資訊</h3>
                <p className="text-sm">{ticketUser?.nickname || '(未設定暱稱)'}</p>
                <p className="text-xs text-secondary-text">
                  {ticketUser?.gender === 'male' ? '男性' : ticketUser?.gender === 'female' ? '女性' : '-'} ·{' '}
                  {ticketUser?.university_name || '未驗證學校'}
                </p>
                <p className="text-xs text-tertiary-text mt-1">ID: {selectedTicket.user_id}</p>
              </div>

              {/* Ticket status */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="text-sm font-semibold">工單狀態</h3>
                  <span className={`text-[11px] px-1.5 py-0.5 rounded ${TICKET_STATUS_COLORS[selectedTicket.status]}`}>
                    {TICKET_STATUS_LABELS[selectedTicket.status]}
                  </span>
                </div>
                <p className="text-xs text-tertiary-text mb-3">
                  分類：{TICKET_CATEGORY_LABELS[selectedTicket.category]} · 建立：{formatDateTime(selectedTicket.created_at)}
                </p>
                {!isClosed && (
                  <div className="flex gap-2">
                    {selectedTicket.status === 'open' && (
                      <button
                        onClick={() => handleStatusChange('in_progress')}
                        className="px-3 py-1.5 text-xs bg-alternate rounded-[var(--radius-app)] hover:opacity-80 transition-opacity"
                      >
                        開始處理
                      </button>
                    )}
                    <button
                      onClick={() => handleStatusChange('resolved')}
                      className="px-3 py-1.5 text-xs bg-emerald-100 text-emerald-800 rounded-[var(--radius-app)] hover:opacity-80 transition-opacity"
                    >
                      標記解決
                    </button>
                    <button
                      onClick={() => handleStatusChange('closed')}
                      className="px-3 py-1.5 text-xs bg-gray-100 text-gray-500 rounded-[var(--radius-app)] hover:opacity-80 transition-opacity"
                    >
                      關閉
                    </button>
                  </div>
                )}
              </div>

              {/* Quick action: school verification */}
              {selectedTicket.category === 'school_verification' &&
                ticketUser?.school_email_status !== 'verified' &&
                !isClosed && (
                <form onSubmit={handleManualVerify} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                  <h3 className="text-sm font-semibold mb-3">快捷操作：學校驗證</h3>
                  <p className="text-xs text-tertiary-text mb-3">
                    確認證件後，選擇對應大學完成驗證。驗證成功後工單會自動結案。
                  </p>
                  <div className="flex items-end gap-3">
                    <label className="block flex-1">
                      <span className="text-xs text-secondary-text">大學</span>
                      <select
                        value={selectedUniversityId}
                        onChange={(e) => setSelectedUniversityId(e.target.value)}
                        className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                      >
                        <option value="">選擇大學...</option>
                        {universities.map((uni) => (
                          <option key={uni.id} value={uni.id}>
                            {uni.name}
                          </option>
                        ))}
                      </select>
                    </label>
                    <button
                      type="submit"
                      disabled={verifying || !selectedUniversityId}
                      className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                    >
                      {verifying ? '處理中...' : '確認驗證'}
                    </button>
                  </div>
                </form>
              )}

              {/* Messages */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-3">對話紀錄</h3>
                <div className="max-h-80 overflow-y-auto space-y-3 mb-3">
                  {messages.length === 0 ? (
                    <p className="text-xs text-tertiary-text text-center py-4">尚無訊息</p>
                  ) : (
                    messages.map((msg) => (
                      <div
                        key={msg.id}
                        className={`flex ${msg.sender_type === 'admin' ? 'justify-end' : 'justify-start'}`}
                      >
                        <div
                          className={`max-w-[80%] rounded-lg px-3 py-2 ${
                            msg.sender_type === 'admin'
                              ? 'bg-secondary-text/10 text-primary-text'
                              : 'bg-alternate text-primary-text'
                          }`}
                        >
                          <p className="text-[11px] font-medium mb-1 text-tertiary-text">
                            {msg.sender_type === 'admin' ? '客服' : '用戶'}
                          </p>
                          {msg.image_path && messageImageUrls[msg.id] && (
                            <img
                              src={messageImageUrls[msg.id]}
                              alt="附件"
                              className="max-h-40 rounded mb-1 cursor-pointer"
                              onClick={() => window.open(messageImageUrls[msg.id], '_blank')}
                            />
                          )}
                          {msg.content && (
                            <p className="text-sm whitespace-pre-wrap">{msg.content}</p>
                          )}
                          <p className="text-[10px] text-tertiary-text mt-1">
                            {formatDateTime(msg.created_at)}
                          </p>
                        </div>
                      </div>
                    ))
                  )}
                  <div ref={messagesEndRef} />
                </div>

                {/* Reply input */}
                {!isClosed && (
                  <div className="flex gap-2">
                    <textarea
                      value={replyText}
                      onChange={(e) => setReplyText(e.target.value)}
                      placeholder="輸入回覆..."
                      rows={2}
                      className="flex-1 border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary resize-none"
                    />
                    <button
                      onClick={handleSendReply}
                      disabled={sending || !replyText.trim()}
                      className="px-4 py-2 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity self-end"
                    >
                      {sending ? '...' : '發送'}
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
