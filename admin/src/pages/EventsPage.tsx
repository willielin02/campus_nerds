import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import type { Event, EventStatus, EventCategory, EventTimeSlot, City } from '../types/database'
import { CATEGORY_LABELS, TIME_SLOT_LABELS, EVENT_STATUS_LABELS } from '../types/database'
import StatusBadge, { eventStatusColor } from '../components/StatusBadge'

export default function EventsPage() {
  const [events, setEvents] = useState<(Event & { booking_count: number })[]>([])
  const [cities, setCities] = useState<City[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<EventStatus | ''>('')
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [creating, setCreating] = useState(false)

  // Create form state
  const [newCategory, setNewCategory] = useState<EventCategory>('focused_study')
  const [newDate, setNewDate] = useState('')
  const [newTimeSlot, setNewTimeSlot] = useState<EventTimeSlot>('morning')
  const [newCityId, setNewCityId] = useState('')
  const [newGroupSize, setNewGroupSize] = useState(4)

  useEffect(() => {
    loadCities()
    loadEvents()
  }, [statusFilter])

  async function loadCities() {
    const { data } = await supabase.from('cities').select('*').order('name')
    if (data) setCities(data)
  }

  async function loadEvents() {
    setLoading(true)
    let query = supabase
      .from('events')
      .select('*, city:cities(name)')
      .order('event_date', { ascending: false })

    if (statusFilter) {
      query = query.eq('status', statusFilter)
    }

    const { data: eventsData } = await query

    if (eventsData) {
      // Fetch booking counts for each event
      const eventsWithCounts = await Promise.all(
        eventsData.map(async (event) => {
          const { count } = await supabase
            .from('bookings')
            .select('*', { count: 'exact', head: true })
            .eq('event_id', event.id)
            .eq('status', 'active')
          return { ...event, booking_count: count ?? 0 }
        })
      )
      setEvents(eventsWithCounts as (Event & { booking_count: number })[])
    }
    setLoading(false)
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault()
    if (!newCityId || !newDate) return

    setCreating(true)
    const { error } = await supabase.from('events').insert({
      category: newCategory,
      event_date: newDate,
      time_slot: newTimeSlot,
      city_id: newCityId,
      default_group_size: newGroupSize,
      status: 'draft',
    })

    if (error) {
      alert(`建立失敗: ${error.message}`)
    } else {
      setShowCreateForm(false)
      setNewDate('')
      loadEvents()
    }
    setCreating(false)
  }

  // Preview computed signup times
  const previewSignupOpen = newDate
    ? new Date(new Date(newDate).getTime() - 23 * 24 * 60 * 60 * 1000).toLocaleDateString('zh-TW')
    : ''
  const previewSignupDeadline = newDate
    ? new Date(new Date(newDate).getTime() - 3 * 24 * 60 * 60 * 1000).toLocaleDateString('zh-TW')
    : ''

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-semibold">活動管理</h2>
        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 transition-opacity"
        >
          {showCreateForm ? '取消' : '建立活動'}
        </button>
      </div>

      {/* Create form */}
      {showCreateForm && (
        <form onSubmit={handleCreate} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-5 mb-6">
          <h3 className="text-sm font-semibold mb-4">建立新活動</h3>
          <div className="grid grid-cols-2 gap-4">
            <label className="block">
              <span className="text-xs text-secondary-text">類別</span>
              <select
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value as EventCategory)}
                className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
              >
                <option value="focused_study">專注讀書</option>
                <option value="english_games">英文遊戲</option>
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">日期</span>
              <input
                type="date"
                value={newDate}
                onChange={(e) => setNewDate(e.target.value)}
                required
                className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
              />
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">時段</span>
              <select
                value={newTimeSlot}
                onChange={(e) => setNewTimeSlot(e.target.value as EventTimeSlot)}
                className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
              >
                <option value="morning">上午</option>
                <option value="afternoon">下午</option>
                <option value="evening">晚上</option>
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">城市</span>
              <select
                value={newCityId}
                onChange={(e) => setNewCityId(e.target.value)}
                required
                className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
              >
                <option value="">選擇城市</option>
                {cities.map((c) => (
                  <option key={c.id} value={c.id}>{c.name}</option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">分組大小（必須偶數）</span>
              <input
                type="number"
                value={newGroupSize}
                onChange={(e) => setNewGroupSize(Number(e.target.value))}
                min={2}
                step={2}
                className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
              />
            </label>
            {newDate && (
              <div className="block">
                <span className="text-xs text-secondary-text">系統自動計算</span>
                <p className="mt-1 text-xs text-tertiary-text">
                  報名開放：{previewSignupOpen}<br />
                  報名截止：{previewSignupDeadline} 23:59
                </p>
              </div>
            )}
          </div>
          <div className="mt-4 flex justify-end">
            <button
              type="submit"
              disabled={creating}
              className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
            >
              {creating ? '建立中...' : '確認建立'}
            </button>
          </div>
        </form>
      )}

      {/* Filters */}
      <div className="mb-4">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as EventStatus | '')}
          className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
        >
          <option value="">全部狀態</option>
          {Object.entries(EVENT_STATUS_LABELS).map(([key, label]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>
      </div>

      {/* Events table */}
      <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-tertiary bg-alternate/50">
              <th className="text-left px-4 py-3 font-medium text-secondary-text">日期</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">時段</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">類別</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">城市</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">報名人數</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">狀態</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-tertiary-text">載入中...</td></tr>
            ) : events.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-tertiary-text">暫無活動</td></tr>
            ) : (
              events.map((event) => (
                <tr key={event.id} className="border-b border-tertiary last:border-0 hover:bg-alternate/30 transition-colors">
                  <td className="px-4 py-3">
                    <Link to={`/events/${event.id}`} className="text-primary-text hover:underline font-medium">
                      {event.event_date}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-secondary-text">{TIME_SLOT_LABELS[event.time_slot]}</td>
                  <td className="px-4 py-3 text-secondary-text">{CATEGORY_LABELS[event.category]}</td>
                  <td className="px-4 py-3 text-secondary-text">{(event.city as unknown as { name: string })?.name ?? '-'}</td>
                  <td className="px-4 py-3 text-secondary-text">{event.booking_count}</td>
                  <td className="px-4 py-3">
                    <StatusBadge label={EVENT_STATUS_LABELS[event.status]} color={eventStatusColor(event.status)} />
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}