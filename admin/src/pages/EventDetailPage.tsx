import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase, invokeConfirmGroup } from '../lib/supabase'
import type { Event, Group, GroupMemberRow, Venue, Gender, UserProfile } from '../types/database'
import { CATEGORY_LABELS, TIME_SLOT_LABELS, EVENT_STATUS_LABELS, GROUP_STATUS_LABELS, LOCATION_DETAIL_LABELS } from '../types/database'
import StatusBadge, { eventStatusColor, groupStatusColor } from '../components/StatusBadge'
import { formatEventDate, formatDateTime } from '../lib/date'
import { serverNow } from '../lib/serverClock'

interface UnmatchedBooking {
  booking_id: string
  user_id: string
  nickname: string | null
  gender: Gender | null
  age: number | null
  university_name: string | null
}

export default function EventDetailPage() {
  const { id } = useParams<{ id: string }>()
  const [event, setEvent] = useState<Event | null>(null)
  const [groups, setGroups] = useState<Group[]>([])
  const [groupMembers, setGroupMembers] = useState<Record<string, GroupMemberRow[]>>({})
  const [venues, setVenues] = useState<Venue[]>([])
  const [bookingStats, setBookingStats] = useState({ total: 0, male: 0, female: 0 })
  const [loading, setLoading] = useState(true)
  const [expandedGroups, setExpandedGroups] = useState<Set<string>>(new Set())
  const [selectedVenues, setSelectedVenues] = useState<Record<string, string>>({})
  const [userProfiles, setUserProfiles] = useState<Record<string, UserProfile>>({})
  const [unmatchedBookings, setUnmatchedBookings] = useState<UnmatchedBooking[]>([])
  const [selectedAddMember, setSelectedAddMember] = useState<Record<string, string>>({})
  const [confirming, setConfirming] = useState<string | null>(null)
  const [transitioning, setTransitioning] = useState(false)
  const [editingMaxSize, setEditingMaxSize] = useState<Record<string, number>>({})

  useEffect(() => {
    if (id) loadAll()
  }, [id])

  async function loadAll() {
    setLoading(true)
    await Promise.all([loadEvent(), loadGroups(), loadBookingStats(), loadUnmatchedBookings()])
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
    if (!data) return
    setGroups(data as unknown as Group[])

    // Pre-populate venue selections from saved venue_id
    const venueSelections: Record<string, string> = {}
    for (const g of data) {
      if (g.venue_id) venueSelections[g.id] = g.venue_id as string
    }
    setSelectedVenues((prev) => ({ ...venueSelections, ...prev }))

    const groupIds = data.map((g) => g.id)
    if (groupIds.length === 0) return

    // Load all members at once
    const { data: membersData } = await supabase
      .from('group_members')
      .select('id, group_id, booking_id, bookings!inner(user_id, users!inner(id, nickname, gender))')
      .in('group_id', groupIds)
      .is('left_at', null)
    if (!membersData) return

    const membersMap: Record<string, GroupMemberRow[]> = {}
    for (const m of membersData) {
      const gid = (m as any).group_id
      if (!membersMap[gid]) membersMap[gid] = []
      membersMap[gid].push(m as unknown as GroupMemberRow)
    }
    setGroupMembers(membersMap)

    // Fetch user profiles for age & university
    const userIds = membersData.map((m) => (m as any).bookings?.users?.id).filter(Boolean)
    if (userIds.length === 0) return
    const { data: profiles } = await supabase
      .from('user_profile_v')
      .select('id, nickname, gender, age, university_name')
      .in('id', userIds)
    if (profiles) {
      const map: Record<string, UserProfile> = {}
      for (const p of profiles) {
        map[(p as any).id] = p as unknown as UserProfile
      }
      setUserProfiles(map)
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

  async function loadUnmatchedBookings() {
    const { data: bookings } = await supabase
      .from('bookings')
      .select('id, user_id')
      .eq('event_id', id!)
      .eq('status', 'active')
    if (!bookings) { setUnmatchedBookings([]); return }

    const { data: activeMembers } = await supabase
      .from('group_members')
      .select('booking_id')
      .eq('event_id', id!)
      .is('left_at', null)
    const groupedIds = new Set((activeMembers || []).map((m) => m.booking_id))

    const unmatched = bookings.filter((b) => !groupedIds.has(b.id))
    if (unmatched.length === 0) { setUnmatchedBookings([]); return }

    const userIds = unmatched.map((b) => b.user_id)
    const { data: profiles } = await supabase
      .from('user_profile_v')
      .select('id, nickname, gender, age, university_name')
      .in('id', userIds)
    const pMap: Record<string, any> = {}
    for (const p of profiles || []) pMap[(p as any).id] = p

    setUnmatchedBookings(
      unmatched.map((b) => ({
        booking_id: b.id,
        user_id: b.user_id,
        nickname: pMap[b.user_id]?.nickname ?? null,
        gender: pMap[b.user_id]?.gender ?? null,
        age: pMap[b.user_id]?.age ?? null,
        university_name: pMap[b.user_id]?.university_name ?? null,
      }))
    )
  }

  async function handleRemoveMember(memberId: string) {
    if (!confirm('確定要從分組中移除此成員嗎？')) return

    const { error } = await supabase
      .from('group_members')
      .update({ left_at: new Date().toISOString() })
      .eq('id', memberId)
      .is('left_at', null)

    if (error) {
      alert(`移除失敗: ${error.message}`)
    } else {
      await Promise.all([loadGroups(), loadUnmatchedBookings()])
    }
  }

  async function handleAddMember(groupId: string) {
    const bookingId = selectedAddMember[groupId]
    if (!bookingId) return

    const { error } = await supabase
      .from('group_members')
      .insert({ group_id: groupId, booking_id: bookingId, event_id: id! })

    if (error) {
      alert(`新增失敗: ${error.message}`)
    } else {
      setSelectedAddMember((prev) => ({ ...prev, [groupId]: '' }))
      await Promise.all([loadGroups(), loadUnmatchedBookings()])
    }
  }

  async function handleUpdateMaxSize(groupId: string, newSize: number) {
    if (newSize < 1) return
    const { error } = await supabase
      .from('groups')
      .update({ max_size: newSize })
      .eq('id', groupId)
    if (error) {
      alert(`更新失敗: ${error.message}`)
    } else {
      await loadGroups()
    }
  }

  async function handleSaveVenue(groupId: string) {
    const venueId = selectedVenues[groupId]
    if (!venueId) return

    // Clear timing fields so trg_set_group_times recalculates from new venue
    const { error } = await supabase
      .from('groups')
      .update({ venue_id: venueId, chat_open_at: null, goal_close_at: null, feedback_sent_at: null })
      .eq('id', groupId)

    if (error) {
      alert(`場地儲存失敗: ${error.message}`)
    } else {
      await loadGroups()
    }
  }

  async function handleDeleteGroup(groupId: string) {
    const members = groupMembers[groupId] || []
    const msg = members.length > 0
      ? `此分組有 ${members.length} 位成員，刪除後成員將回到未分組狀態。確定要刪除嗎？`
      : '確定要刪除此空分組嗎？'
    if (!confirm(msg)) return

    // Remove ALL members first (including left_at IS NOT NULL) — FK is NO ACTION
    const { error: memError } = await supabase
      .from('group_members')
      .delete()
      .eq('group_id', groupId)
    if (memError) {
      alert(`刪除成員失敗: ${memError.message}`)
      return
    }

    const { error } = await supabase
      .from('groups')
      .delete()
      .eq('id', groupId)

    if (error) {
      alert(`刪除分組失敗: ${error.message}`)
    } else {
      await Promise.all([loadGroups(), loadUnmatchedBookings()])
    }
  }

  async function handleCreateGroup() {
    if (!event) return
    const { error } = await supabase
      .from('groups')
      .insert({ event_id: event.id, max_size: event.default_group_size, status: 'draft' })
    if (error) {
      alert(`建立失敗: ${error.message}`)
    } else {
      await Promise.all([loadGroups(), loadUnmatchedBookings()])
    }
  }

  async function handleLockGroup(groupId: string) {
    const group = groups.find((g) => g.id === groupId)
    if (!group?.venue_id) {
      alert('請先儲存場地')
      return
    }

    const members = groupMembers[groupId] || []
    const maleCount = members.filter((m) => m.bookings?.users?.gender === 'male').length
    const femaleCount = members.filter((m) => m.bookings?.users?.gender === 'female').length
    const warnings: string[] = []

    if (group.max_size % 2 !== 0) {
      warnings.push(`分組人數為奇數（${group.max_size}人）`)
    }
    if (maleCount !== femaleCount) {
      warnings.push(`性別比不為 1:1（男性 ${maleCount} · 女性 ${femaleCount}）`)
    }

    if (warnings.length > 0) {
      if (!confirm(`⚠ 注意：\n${warnings.map((w) => `• ${w}`).join('\n')}\n\n確定仍要鎖定此分組嗎？系統會先同步 Facebook 好友再驗證。`)) return
    } else {
      if (!confirm('確定要鎖定此分組嗎？系統會先同步 Facebook 好友再驗證。')) return
    }

    setConfirming(groupId)

    const result = await invokeConfirmGroup({ group_id: groupId })

    if (result.success) {
      alert('分組已鎖定！')
      loadGroups()
    } else {
      alert(`鎖定失敗: ${result.details || result.message || result.error}`)
    }
    setConfirming(null)
  }

  async function handleUnlockGroup(groupId: string) {
    if (!confirm('確定要解除鎖定此分組嗎？解除後可重新編輯成員與場地。')) return

    setConfirming(groupId)
    const { error } = await supabase
      .from('groups')
      .update({ status: 'draft' })
      .eq('id', groupId)

    if (error) {
      alert(`解除鎖定失敗: ${error.message}`)
    } else {
      await loadGroups()
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
      alert(`還有 ${draftGroups.length} 個未鎖定的分組，請先全部鎖定。`)
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
    <div className="max-w-4xl">
      <div className="mb-4">
        <Link to="/events" className="text-sm text-secondary-text hover:text-primary-text transition-colors">
          ← 返回活動列表
        </Link>
      </div>

      {/* Event header card */}
      <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-5 mb-6">
        <div className="flex items-start justify-between">
          <div>
            <h2 className="text-lg font-semibold">
              {formatEventDate(event.event_date)} {TIME_SLOT_LABELS[event.time_slot]}{'\u00A0\u00A0'}{LOCATION_DETAIL_LABELS[event.location_detail] ?? event.location_detail}
            </h2>
            <p className="text-sm text-secondary-text mt-1">
              {CATEGORY_LABELS[event.category]} · {cityName} · 預設分組 {event.default_group_size} 人
            </p>
          </div>
          <div className="flex items-center gap-2">
            <StatusBadge label={EVENT_STATUS_LABELS[event.status]} color={eventStatusColor(event.status)} />
            {event.status === 'draft' && (
              <button
                onClick={handleTransitionToScheduled}
                disabled={transitioning}
                className="px-3 py-1.5 bg-alternate text-primary-text rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
              >
                {transitioning ? '處理中...' : '開放報名'}
              </button>
            )}
            {event.status === 'scheduled' && (() => {
              const lockedCount = groups.filter((g) => g.status === 'scheduled').length
              const allLocked = groups.length > 0 && lockedCount === groups.length
              return (
                <button
                  onClick={handleTransitionToNotified}
                  disabled={transitioning || !allLocked}
                  title={!allLocked ? `尚有 ${groups.length - lockedCount} 個未鎖定的分組` : ''}
                  className="px-3 py-1.5 bg-secondary-text text-white rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                >
                  {transitioning ? '處理中...' : '發送通知'}
                </button>
              )
            })()}
          </div>
        </div>

        {/* Inline stats + signup window */}
        <div className="flex items-center justify-between mt-3 pt-3 border-t border-tertiary">
          <div className="flex items-center gap-4 text-sm">
            <span>報名 <strong>{bookingStats.total}</strong> 人</span>
            <span className="text-secondary-text">男性 {bookingStats.male}</span>
            <span className="text-secondary-text">女性 {bookingStats.female}</span>
          </div>
          <p className="text-xs text-tertiary-text">
            {formatDateTime(event.signup_open_at)} ~ {formatDateTime(event.signup_deadline_at)}
          </p>
        </div>
      </div>

      {/* Groups section */}
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <h3 className="text-base font-semibold">分組列表 ({groups.length})</h3>
          {groups.length > 0 && (
            <span className="text-xs text-secondary-text">
              已鎖定 {groups.filter((g) => g.status === 'scheduled').length}/{groups.length}
            </span>
          )}
        </div>
        <button
          onClick={handleCreateGroup}
          className="px-3 py-1.5 bg-alternate text-primary-text rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 transition-opacity"
        >
          新增分組
        </button>
      </div>

      {groups.length === 0 ? (
        <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] px-5 py-8 text-center">
          <p className="text-sm text-tertiary-text">尚無分組（自動分組會在{(() => {
            const groupingAt = new Date(`${event.event_date}T00:00:00+08:00`)
            groupingAt.setDate(groupingAt.getDate() - 2)
            const now = serverNow()
            const diffMs = groupingAt.getTime() - now.getTime()
            if (diffMs <= 0) {
              let reason = '其他'
              if (bookingStats.total === 0) {
                reason = '無人報名'
              } else {
                reason = `報名人數不足；目前男性 ${bookingStats.male} 女性 ${bookingStats.female}`
              }
              return `已執行，未成功分組（原因：${reason}）`
            }
            const days = Math.floor(diffMs / (1000 * 60 * 60 * 24))
            const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
            const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60))
            if (days > 0) return ` ${days} 天 ${hours} 小時 ${minutes} 分鐘後執行`
            return ` ${hours} 小時 ${minutes} 分鐘後執行`
          })()}）</p>
        </div>
      ) : (
        <div className="space-y-3">
          {groups.map((group) => {
            const members = groupMembers[group.id] || []
            const maleCount = members.filter((m) => m.bookings?.users?.gender === 'male').length
            const femaleCount = members.filter((m) => m.bookings?.users?.gender === 'female').length
            const isExpanded = expandedGroups.has(group.id)
            const venueName = (group.venue as unknown as Venue)?.name
            const isDraft = group.status === 'draft'

            return (
              <div key={group.id} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
                {/* Collapsed header */}
                <div
                  className="flex items-center justify-between px-4 py-3 cursor-pointer hover:bg-alternate/30 transition-colors"
                  onClick={() => setExpandedGroups(prev => {
                    const next = new Set(prev)
                    if (isExpanded) next.delete(group.id)
                    else next.add(group.id)
                    return next
                  })}
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xs font-mono text-tertiary-text">{group.id.slice(0, 8)}</span>
                    <span className="text-sm font-medium">
                      {members.length}/{group.max_size} 人
                    </span>
                    <span className="text-xs text-secondary-text">
                      男 {maleCount} · 女 {femaleCount}
                    </span>
                    {venueName && (
                      <span className="text-xs text-tertiary-text">· {venueName}</span>
                    )}
                  </div>
                  <div className="flex items-center gap-2">
                    <StatusBadge label={GROUP_STATUS_LABELS[group.status]} color={groupStatusColor(group.status)} />
                    <span className="text-tertiary-text text-xs">{isExpanded ? '▲' : '▼'}</span>
                  </div>
                </div>

                {/* Expanded panel */}
                {isExpanded && (
                  <div className="border-t-2 border-tertiary">
                    {/* ── Members table ── */}
                    <table className="w-full text-sm">
                      <thead>
                        <tr className="bg-alternate/40">
                          <th className="text-left px-4 py-2 text-xs font-medium text-secondary-text w-[28%]">暱稱</th>
                          <th className="text-left px-4 py-2 text-xs font-medium text-secondary-text w-[12%]">年齡</th>
                          <th className="text-left px-4 py-2 text-xs font-medium text-secondary-text w-[12%]">性別</th>
                          <th className="text-left px-4 py-2 text-xs font-medium text-secondary-text">學校</th>
                          <th className="w-14" />
                        </tr>
                      </thead>
                      <tbody>
                        {members.map((m) => {
                          const userId = m.bookings?.users?.id
                          const profile = userId ? userProfiles[userId] : null
                          return (
                            <tr key={m.id} className="border-t border-tertiary/50 hover:bg-alternate/20 transition-colors">
                              <td className="px-4 py-2 font-medium">{m.bookings?.users?.nickname || '(未設定)'}</td>
                              <td className="px-4 py-2 text-secondary-text">{profile?.age != null ? `${profile.age}` : '-'}</td>
                              <td className="px-4 py-2 text-secondary-text">{m.bookings?.users?.gender === 'male' ? '男' : '女'}</td>
                              <td className="px-4 py-2 text-secondary-text">{profile?.university_name || '-'}</td>
                              <td className="px-4 py-2 text-right">
                                {isDraft && (
                                  <button
                                    onClick={(e) => { e.stopPropagation(); handleRemoveMember(m.id) }}
                                    className="text-xs text-tertiary-text hover:text-error transition-colors"
                                  >
                                    移除
                                  </button>
                                )}
                              </td>
                            </tr>
                          )
                        })}
                        {/* Empty placeholder rows for unfilled slots */}
                        {Array.from({ length: group.max_size - members.length }).map((_, i) => (
                          <tr key={`empty-${i}`} className="border-t border-tertiary/50">
                            <td className="px-4 py-2 text-tertiary-text italic">(空位)</td>
                            <td className="px-4 py-2">-</td>
                            <td className="px-4 py-2">-</td>
                            <td className="px-4 py-2">-</td>
                            <td className="w-14" />
                          </tr>
                        ))}
                      </tbody>
                    </table>

                    {/* ── Draft: Settings toolbar ── */}
                    {isDraft && (
                      <div className="px-4 py-3 border-t-2 border-tertiary bg-alternate/20 flex items-center gap-6 flex-wrap">
                        {/* Max size */}
                        <div className="flex items-center gap-2">
                          <span className="text-xs text-secondary-text whitespace-nowrap">人數上限</span>
                          <input
                            type="number"
                            min={1}
                            value={editingMaxSize[group.id] ?? group.max_size}
                            onChange={(e) => setEditingMaxSize((prev) => ({ ...prev, [group.id]: Number(e.target.value) }))}
                            className="w-16 border-2 border-tertiary rounded-lg px-2 py-1 text-sm bg-secondary text-center"
                          />
                          {(editingMaxSize[group.id] != null && editingMaxSize[group.id] !== group.max_size) && (
                            <button
                              onClick={() => handleUpdateMaxSize(group.id, editingMaxSize[group.id])}
                              className="px-2 py-1 bg-alternate text-primary-text rounded-lg text-xs font-semibold hover:opacity-80 transition-opacity"
                            >
                              儲存
                            </button>
                          )}
                          {editingMaxSize[group.id] != null && editingMaxSize[group.id] % 2 !== 0 && (
                            <span className="text-xs text-warning">奇數</span>
                          )}
                        </div>

                        <div className="h-4 w-px bg-tertiary" />

                        {/* Venue */}
                        <div className="flex items-center gap-2 flex-1 min-w-0">
                          <span className="text-xs text-secondary-text whitespace-nowrap">場地</span>
                          <select
                            value={selectedVenues[group.id] || ''}
                            onChange={(e) => setSelectedVenues((prev) => ({ ...prev, [group.id]: e.target.value }))}
                            className="flex-1 min-w-0 border-2 border-tertiary rounded-lg px-2 py-1 text-sm bg-secondary"
                          >
                            <option value="">選擇場地...</option>
                            {venues.map((v) => (
                              <option key={v.id} value={v.id}>
                                {v.name}{v.start_at ? ` (${v.start_at.slice(0, 5)})` : ''}
                              </option>
                            ))}
                          </select>
                          {selectedVenues[group.id] && selectedVenues[group.id] !== group.venue_id && (
                            <button
                              onClick={() => handleSaveVenue(group.id)}
                              className="px-2 py-1 bg-alternate text-primary-text rounded-lg text-xs font-semibold hover:opacity-80 transition-opacity whitespace-nowrap"
                            >
                              儲存場地
                            </button>
                          )}
                          {group.venue_id && selectedVenues[group.id] === group.venue_id && (
                            <span className="text-xs text-success whitespace-nowrap">已儲存</span>
                          )}
                        </div>

                      </div>
                    )}

                    {/* ── Draft: Unmatched users ── */}
                    {isDraft && unmatchedBookings.length > 0 && (
                      <div className="px-4 py-3 border-t border-tertiary flex items-center gap-3">
                        <span className="text-xs text-secondary-text whitespace-nowrap">
                          未分組 ({unmatchedBookings.length})
                        </span>
                        <select
                          value={selectedAddMember[group.id] || ''}
                          onChange={(e) => setSelectedAddMember((prev) => ({ ...prev, [group.id]: e.target.value }))}
                          className="flex-1 min-w-0 border-2 border-tertiary rounded-lg px-2 py-1.5 text-sm bg-secondary"
                        >
                          <option value="">選擇要加入的用戶...</option>
                          {unmatchedBookings.map((ub) => (
                            <option key={ub.booking_id} value={ub.booking_id}>
                              {ub.nickname || '(未設定)'} · {ub.age != null ? `${ub.age}歲` : '-'} · {ub.gender === 'male' ? '男' : '女'} · {ub.university_name || '-'}
                            </option>
                          ))}
                        </select>
                        <button
                          onClick={() => handleAddMember(group.id)}
                          disabled={!selectedAddMember[group.id]}
                          className="px-3 py-1.5 bg-alternate text-primary-text rounded-lg text-xs font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity whitespace-nowrap"
                        >
                          新增成員
                        </button>
                      </div>
                    )}

                    {/* ── Scheduled: Venue info + unlock ── */}
                    {!isDraft && (
                      <div className="px-4 py-3 border-t-2 border-tertiary bg-alternate/10 flex items-center justify-between">
                        <div className="text-sm text-secondary-text">
                          {venueName && (
                            <>
                              場地：{venueName}
                              {(group.venue as unknown as Venue)?.address && (
                                <span className="text-tertiary-text"> · {(group.venue as unknown as Venue).address}</span>
                              )}
                            </>
                          )}
                        </div>
                        <button
                          onClick={() => handleUnlockGroup(group.id)}
                          disabled={confirming === group.id}
                          className="px-4 py-2 bg-secondary border-2 border-tertiary text-secondary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                        >
                          {confirming === group.id ? '處理中...' : '解除鎖定'}
                        </button>
                      </div>
                    )}

                    {/* ── Draft: Lock action bar ── */}
                    {isDraft && (
                      <div className="px-4 py-3 border-t-2 border-tertiary bg-alternate/10 flex items-center justify-between">
                        <p className="text-xs text-tertiary-text">
                          {group.venue_id ? '鎖定後將同步 Facebook 好友並驗證分組' : '請先選擇並儲存場地'}
                        </p>
                        <div className="flex items-center gap-3">
                          <button
                            onClick={(e) => { e.stopPropagation(); handleDeleteGroup(group.id) }}
                            className="px-4 py-2 bg-secondary border-2 border-tertiary text-secondary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 transition-opacity"
                          >
                            刪除分組
                          </button>
                          <button
                            onClick={() => handleLockGroup(group.id)}
                            disabled={confirming === group.id || !group.venue_id}
                            className="px-5 py-2 bg-secondary-text text-white rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                          >
                            {confirming === group.id ? '鎖定中...' : '鎖定分組'}
                          </button>
                        </div>
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