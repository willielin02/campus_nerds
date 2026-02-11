import { useEffect, useState } from 'react'
import { useParams, Link } from 'react-router-dom'
import { supabase, invokeConfirmGroup } from '../lib/supabase'
import type { Event, Group, GroupMemberRow, Venue, Gender, UserProfile } from '../types/database'
import { CATEGORY_LABELS, TIME_SLOT_LABELS, EVENT_STATUS_LABELS, GROUP_STATUS_LABELS } from '../types/database'
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
  const [expandedGroup, setExpandedGroup] = useState<string | null>(null)
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

  async function handleConfirmGroup(groupId: string) {
    const group = groups.find((g) => g.id === groupId)
    if (!group?.venue_id) {
      alert('請先儲存場地')
      return
    }

    // Check for warnings before confirming
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
      if (!confirm(`⚠ 注意：\n${warnings.map((w) => `• ${w}`).join('\n')}\n\n確定仍要確認此分組嗎？系統會先同步 Facebook 好友再驗證。`)) return
    } else {
      if (!confirm('確定要確認此分組嗎？系統會先同步 Facebook 好友再驗證。')) return
    }

    setConfirming(groupId)

    const result = await invokeConfirmGroup({ group_id: groupId })

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
              {formatEventDate(event.event_date)} {TIME_SLOT_LABELS[event.time_slot]}
            </h2>
            <p className="text-sm text-secondary-text mt-1">
              {CATEGORY_LABELS[event.category]} · {cityName} · 分組大小 {event.default_group_size} 人
            </p>
            <p className="text-xs text-tertiary-text mt-2">
              報名開放：{formatDateTime(event.signup_open_at)}<br />
              報名截止：{formatDateTime(event.signup_deadline_at)}
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
                className="px-3 py-2 bg-secondary-text text-white rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
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
          <p className="text-xs text-secondary-text">男性</p>
        </div>
        <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4 text-center">
          <p className="text-2xl font-semibold">{bookingStats.female}</p>
          <p className="text-xs text-secondary-text">女性</p>
        </div>
      </div>

      {/* Groups */}
      <h3 className="text-base font-semibold mb-3">分組列表 ({groups.length})</h3>
      {groups.length === 0 ? (
        <p className="text-sm text-tertiary-text">尚無分組（自動分組會在{(() => {
          // Auto-grouping runs at event_date - 2 days, 00:00 Taipei time (UTC+8)
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
                      {members.length}/{group.max_size} 人（男性 {maleCount} · 女性 {femaleCount}）
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
                      {members.map((m) => {
                        const userId = m.bookings?.users?.id
                        const profile = userId ? userProfiles[userId] : null
                        return (
                          <div key={m.id} className="flex items-center gap-3 text-sm">
                            <span>{m.bookings?.users?.nickname || '(未設定暱稱)'}</span>
                            <span className="text-xs text-tertiary-text">
                              {profile?.age != null ? `${profile.age}歲` : '-'}
                              {' · '}
                              {m.bookings?.users?.gender === 'male' ? '男性' : '女性'}
                              {' · '}
                              {profile?.university_name || '-'}
                            </span>
                            {group.status === 'draft' && (
                              <button
                                onClick={(e) => { e.stopPropagation(); handleRemoveMember(m.id) }}
                                className="ml-auto px-2 py-0.5 text-xs text-tertiary-text hover:text-primary-text border border-tertiary rounded-lg hover:bg-alternate transition-colors"
                              >
                                移除
                              </button>
                            )}
                          </div>
                        )
                      })}
                    </div>

                    {/* Edit max_size for draft groups */}
                    {group.status === 'draft' && (
                      <div className="flex items-center gap-3 mb-4">
                        <span className="text-xs text-secondary-text">分組人數上限</span>
                        <input
                          type="number"
                          min={1}
                          value={editingMaxSize[group.id] ?? group.max_size}
                          onChange={(e) => setEditingMaxSize((prev) => ({ ...prev, [group.id]: Number(e.target.value) }))}
                          className="w-20 border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-1.5 text-sm bg-secondary text-center"
                        />
                        {(editingMaxSize[group.id] != null && editingMaxSize[group.id] !== group.max_size) && (
                          <button
                            onClick={() => handleUpdateMaxSize(group.id, editingMaxSize[group.id])}
                            className="px-3 py-1.5 bg-alternate text-primary-text rounded-[var(--radius-app)] text-xs font-semibold hover:opacity-80 transition-opacity"
                          >
                            儲存
                          </button>
                        )}
                        {editingMaxSize[group.id] != null && editingMaxSize[group.id] % 2 !== 0 && (
                          <span className="text-xs text-tertiary-text">⚠ 奇數人數，性別比將無法 1:1</span>
                        )}
                      </div>
                    )}

                    {/* Add member from unmatched bookings (draft groups only) */}
                    {group.status === 'draft' && unmatchedBookings.length > 0 && (
                      <div className="mb-4">
                        <p className="text-xs font-medium text-secondary-text mb-2">
                          未分組用戶 ({unmatchedBookings.length})
                        </p>
                        <div className="flex items-end gap-3">
                          <select
                            value={selectedAddMember[group.id] || ''}
                            onChange={(e) => setSelectedAddMember((prev) => ({ ...prev, [group.id]: e.target.value }))}
                            className="flex-1 border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                          >
                            <option value="">選擇要加入的用戶...</option>
                            {unmatchedBookings.map((ub) => (
                              <option key={ub.booking_id} value={ub.booking_id}>
                                {ub.nickname || '(未設定暱稱)'} {ub.age != null ? `${ub.age}歲` : '-'} · {ub.gender === 'male' ? '男性' : '女性'} · {ub.university_name || '-'}
                              </option>
                            ))}
                          </select>
                          <button
                            onClick={() => handleAddMember(group.id)}
                            disabled={!selectedAddMember[group.id]}
                            className="px-4 py-2 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                          >
                            新增
                          </button>
                        </div>
                      </div>
                    )}

                    {/* Venue selection for draft groups */}
                    {group.status === 'draft' && (
                      <div className="flex items-end gap-3 pt-3 border-t border-tertiary">
                        <label className="flex-1">
                          <span className="text-xs text-secondary-text">場地</span>
                          <select
                            value={selectedVenues[group.id] || ''}
                            onChange={(e) => setSelectedVenues((prev) => ({ ...prev, [group.id]: e.target.value }))}
                            className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                          >
                            <option value="">選擇場地...</option>
                            {venues.map((v) => (
                              <option key={v.id} value={v.id}>
                                {v.name}{v.start_at ? ` (${new Date(v.start_at).toLocaleTimeString('zh-TW', { hour: '2-digit', minute: '2-digit' })})` : ''}
                              </option>
                            ))}
                          </select>
                        </label>
                        {selectedVenues[group.id] && selectedVenues[group.id] !== group.venue_id && (
                          <button
                            onClick={() => handleSaveVenue(group.id)}
                            className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 transition-opacity"
                          >
                            儲存場地
                          </button>
                        )}
                        {group.venue_id && selectedVenues[group.id] === group.venue_id && (
                          <span className="px-3 py-2 text-xs text-tertiary-text">已儲存</span>
                        )}
                      </div>
                    )}

                    {/* Confirm button for draft groups (only when venue is saved) */}
                    {group.status === 'draft' && group.venue_id && (
                      <div className="flex justify-end pt-3">
                        <button
                          onClick={() => handleConfirmGroup(group.id)}
                          disabled={confirming === group.id}
                          className="px-4 py-3 bg-secondary-text text-white rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
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