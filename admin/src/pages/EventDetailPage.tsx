import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase, invokeConfirmGroup } from '../lib/supabase'
import type { Event, Group, GroupMemberRow, Venue, Gender } from '../types/database'
import { CATEGORY_LABELS, TIME_SLOT_LABELS, EVENT_STATUS_LABELS, GROUP_STATUS_LABELS } from '../types/database'
import StatusBadge, { eventStatusColor, groupStatusColor } from '../components/StatusBadge'

export default function EventDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [event, setEvent] = useState<Event | null>(null)
  const [groups, setGroups] = useState<Group[]>([])
  const [groupMembers, setGroupMembers] = useState<Record<string, GroupMemberRow[]>>({})
  const [venues, setVenues] = useState<Venue[]>([])
  const [bookingStats, setBookingStats] = useState({ total: 0, male: 0, female: 0 })
  const [loading, setLoading] = useState(true)
  const [expandedGroup, setExpandedGroup] = useState<string | null>(null)
  const [selectedVenues, setSelectedVenues] = useState<Record<string, string>>({})
  const [confirming, setConfirming] = useState<string | null>(null)
  const [transitioning, setTransitioning] = useState(false)

  useEffect(() => {
    if (id) loadAll()
  }, [id])

  async function loadAll() {
    setLoading(true)
    await Promise.all([loadEvent(), loadGroups(), loadBookingStats()])
    setLoading(false)
  }

  async function loadEvent() {
    const { data } = await supabase
      .from('events')
      .select('*, city:cities(name)')
      .eq('id', id!)
      .single()
    if (data) {
      setEvent(data as unknown as Event)
      loadVenues(data.city_id, data.category)
    }
  }

  async function loadGroups() {
    const { data } = await supabase
      .from('groups')
      .select('*, venue:venues(id, name, address, start_at)')
      .eq('event_id', id!)
      .order('created_at')
    if (data) {
      setGroups(data as unknown as Group[])
      // Load members for each group
      for (const group of data) {
        loadGroupMembers(group.id)
      }
    }
  }

  async function loadGroupMembers(groupId: string) {
    const { data } = await supabase
      .from('group_members')
      .select('id, group_id, booking_id, bookings!inner(user_id, users!inner(id, nickname, gender))')
      .eq('group_id', groupId)
      .is('left_at', null)
    if (data) {
      setGroupMembers((prev) => ({ ...prev, [groupId]: data as unknown as GroupMemberRow[] }))
    }
  }

  async function loadVenues(cityId: string, category: string) {
    const { data } = await supabase
      .from('venues')
      .select('*')
      .eq('city_id', cityId)
      .eq('category', category)
      .eq('is_active', true)
      .order('name')
    if (data) setVenues(data)
  }

  async function loadBookingStats() {
    const { data } = await supabase
      .from('bookings')
      .select('user_id, users!inner(gender)')
      .eq('event_id', id!)
      .eq('status', 'active')
    if (data) {
      const male = data.filter((b) => (b.users as unknown as { gender: Gender }).gender === 'male').length
      const female = data.filter((b) => (b.users as unknown as { gender: Gender }).gender === 'female').length
      setBookingStats({ total: data.length, male, female })
    }
  }

  async function handleConfirmGroup(groupId: string) {
    const venueId = selectedVenues[groupId]
    if (!venueId) {
      alert('請先選擇場地')
      return
    }

    const venue = venues.find((v) => v.id === venueId)
    if (!venue?.start_at || !event) {
      alert('場地缺少開始時間')
      return
    }

    if (!confirm('確定要確認此分組嗎？系統會先同步 Facebook 好友再驗證。')) return

    setConfirming(groupId)

    // Compute timing fields from venue start_at and event time_slot
    const startAt = new Date(venue.start_at)
    const chatOpenAt = new Date(startAt.getTime() - 60 * 60 * 1000).toISOString()
    const goalCloseAt = new Date(startAt.getTime() + 60 * 60 * 1000).toISOString()

    // feedback_sent_at: event_date at 12:00/17:00/22:00 based on time_slot
    const feedbackHour = event.time_slot === 'morning' ? 12 : event.time_slot === 'afternoon' ? 17 : 22
    const feedbackDate = new Date(`${event.event_date}T${String(feedbackHour).padStart(2, '0')}:00:00+08:00`)
    const feedbackSentAt = feedbackDate.toISOString()

    const result = await invokeConfirmGroup({
      group_id: groupId,
      venue_id: venueId,
      chat_open_at: chatOpenAt,
      goal_close_at: goalCloseAt,
      feedback_sent_at: feedbackSentAt,
    })

    if (result.success) {
      alert('分組確認成功！')
      loadGroups()
    } else {
      alert(`確認失敗: ${result.details || result.message || result.error}`)
    }
    setConfirming(null)
  }

  async function handleTransitionToScheduled() {
    if (!event) return
    if (!confirm('確定要開放報名嗎？活動將對用戶顯示在首頁。')) return

    setTransitioning(true)
    const { error } = await supabase
      .from('events')
      .update({ status: 'scheduled' })
      .eq('id', event.id)

    if (error) {
      alert(`狀態更新失敗: ${error.message}`)
    } else {
      alert('已開放報名！')
      loadEvent()
    }
    setTransitioning(false)
  }

  async function handleTransitionToNotified() {
    if (!event) return

    const draftGroups = groups.filter((g) => g.status === 'draft')
    if (draftGroups.length > 0) {
      alert(`還有 ${draftGroups.length} 個未確認的分組，請先全部確認。`)
      return
    }

    if (!confirm('確定要發送通知嗎？所有報名用戶將收到分組結果通知。')) return

    setTransitioning(true)
    const { error } = await supabase
      .from('events')
      .update({ status: 'notified' })
      .eq('id', event.id)

    if (error) {
      alert(`狀態更新失敗: ${error.message}`)
    } else {
      alert('已發送通知！')
      loadEvent()
    }
    setTransitioning(false)
  }

  if (loading) {
    return <div className="text-center py-12 text-tertiary-text">載入中...</div>
  }

  if (!event) {
    return <div className="text-center py-12 text-tertiary-text">找不到活動</div>
  }

  const cityName = (event.city as unknown as { name: string })?.name ?? '-'

  return (
    <div>
      <div className="mb-6">
        <Link to="/events" className="text-sm text-secondary-text hover:text-primary-text">
          ← 返回活動列表
        </Link>
      </div>

      {/* Event info card */}
      <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-5 mb-6">
        <div className="flex items-start justify-between">
          <div>
            <h2 className="text-lg font-semibold">
              {event.event_date} {TIME_SLOT_LABELS[event.time_slot]}
            </h2>
            <p className="text-sm text-secondary-text mt-1">
              {CATEGORY_LABELS[event.category]} · {cityName} · 分組大小 {event.default_group_size} 人
            </p>
            <p className="text-xs text-tertiary-text mt-2">
              報名開放：{new Date(event.signup_open_at).toLocaleString('zh-TW')}<br />
              報名截止：{new Date(event.signup_deadline_at).toLocaleString('zh-TW')}
            </p>
          </div>
          <div className="flex items-center gap-3">
            <StatusBadge label={EVENT_STATUS_LABELS[event.status]} color={eventStatusColor(event.status)} />
            {event.status === 'draft' && (
              <button
                onClick={handleTransitionToScheduled}
                disabled={transitioning}
                className="px-3 py-2 bg-alternate text-primary-text rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
              >
                {transitioning ? '處理中...' : '開放報名'}
              </button>
            )}
            {event.status === 'scheduled' && (
              <button
                onClick={handleTransitionToNotified}
                disabled={transitioning}
                className="px-3 py-2 bg-success text-white rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
              >
                {transitioning ? '處理中...' : '發送通知'}
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Booking stats */}
      <div className="grid grid-cols-3 gap-4 mb-6">
        <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4 text-center">
          <p className="text-2xl font-semibold">{bookingStats.total}</p>
          <p className="text-xs text-secondary-text">總報名</p>
        </div>
        <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4 text-center">
          <p className="text-2xl font-semibold">{bookingStats.male}</p>
          <p className="text-xs text-secondary-text">男生</p>
        </div>
        <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4 text-center">
          <p className="text-2xl font-semibold">{bookingStats.female}</p>
          <p className="text-xs text-secondary-text">女生</p>
        </div>
      </div>

      {/* Groups */}
      <h3 className="text-base font-semibold mb-3">分組列表 ({groups.length})</h3>
      {groups.length === 0 ? (
        <p className="text-sm text-tertiary-text">尚無分組（自動分組會在{(() => {
          // Auto-grouping runs at event_date - 2 days, 00:00 Taipei time (UTC+8)
          const groupingAt = new Date(`${event.event_date}T00:00:00+08:00`)
          groupingAt.setDate(groupingAt.getDate() - 2)
          const now = new Date()
          const diffMs = groupingAt.getTime() - now.getTime()
          if (diffMs <= 0) return '報名截止後執行'
          const days = Math.floor(diffMs / (1000 * 60 * 60 * 24))
          const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
          if (days > 0) return ` ${days} 天 ${hours} 小時後執行`
          return ` ${hours} 小時後執行`
        })()}）</p>
      ) : (
        <div className="space-y-3">
          {groups.map((group) => {
            const members = groupMembers[group.id] || []
            const maleCount = members.filter((m) => m.bookings?.users?.gender === 'male').length
            const femaleCount = members.filter((m) => m.bookings?.users?.gender === 'female').length
            const isExpanded = expandedGroup === group.id
            const venueName = (group.venue as unknown as Venue)?.name

            return (
              <div key={group.id} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
                <div
                  className="flex items-center justify-between px-4 py-3 cursor-pointer hover:bg-alternate/30 transition-colors"
                  onClick={() => setExpandedGroup(isExpanded ? null : group.id)}
                >
                  <div className="flex items-center gap-4">
                    <span className="text-xs font-mono text-tertiary-text">{group.id.slice(0, 8)}</span>
                    <span className="text-sm">
                      {members.length}/{group.max_size} 人（男 {maleCount} · 女 {femaleCount}）
                    </span>
                    {venueName && (
                      <span className="text-xs text-tertiary-text">{venueName}</span>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusBadge label={GROUP_STATUS_LABELS[group.status]} color={groupStatusColor(group.status)} />
                    <span className="text-tertiary-text text-xs">{isExpanded ? '▲' : '▼'}</span>
                  </div>
                </div>

                {isExpanded && (
                  <div className="border-t border-tertiary px-4 py-3 bg-alternate/20">
                    {/* Members */}
                    <p className="text-xs font-medium text-secondary-text mb-2">成員</p>
                    <div className="space-y-1 mb-4">
                      {members.map((m) => (
                        <div key={m.id} className="flex items-center gap-3 text-sm">
                          <span className="text-xs text-tertiary-text">
                            {m.bookings?.users?.gender === 'male' ? '♂' : '♀'}
                          </span>
                          <span>{m.bookings?.users?.nickname || '(未設定暱稱)'}</span>
                        </div>
                      ))}
                    </div>

                    {/* Confirm controls for draft groups */}
                    {group.status === 'draft' && (
                      <div className="flex items-end gap-3 pt-3 border-t border-tertiary">
                        <label className="flex-1">
                          <span className="text-xs text-secondary-text">選擇場地</span>
                          <select
                            value={selectedVenues[group.id] || ''}
                            onChange={(e) => setSelectedVenues((prev) => ({ ...prev, [group.id]: e.target.value }))}
                            className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                          >
                            <option value="">選擇場地...</option>
                            {venues.map((v) => (
                              <option key={v.id} value={v.id}>{v.name}</option>
                            ))}
                          </select>
                        </label>
                        <button
                          onClick={() => handleConfirmGroup(group.id)}
                          disabled={confirming === group.id || !selectedVenues[group.id]}
                          className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                        >
                          {confirming === group.id ? '確認中...' : '確認分組'}
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}