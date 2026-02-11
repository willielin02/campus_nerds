import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Venue, VenueType, EventCategory, City } from '../types/database'
import { VENUE_TYPE_LABELS, CATEGORY_LABELS } from '../types/database'
import StatusBadge from '../components/StatusBadge'
import { formatDateTime } from '../lib/date'

interface University {
  id: string
  name: string
}

export default function VenuesPage() {
  const [venues, setVenues] = useState<Venue[]>([])
  const [cities, setCities] = useState<City[]>([])
  const [universities, setUniversities] = useState<University[]>([])
  const [loading, setLoading] = useState(true)

  // Filters
  const [cityFilter, setCityFilter] = useState('')
  const [categoryFilter, setCategoryFilter] = useState<EventCategory | ''>('')
  const [activeFilter, setActiveFilter] = useState<'' | 'true' | 'false'>('')

  // Create form
  const [showCreateForm, setShowCreateForm] = useState(false)
  const [creating, setCreating] = useState(false)
  const [newName, setNewName] = useState('')
  const [newAddress, setNewAddress] = useState('')
  const [newGoogleMapUrl, setNewGoogleMapUrl] = useState('')
  const [newCityId, setNewCityId] = useState('')
  const [newCategory, setNewCategory] = useState<EventCategory>('focused_study')
  const [newType, setNewType] = useState<VenueType>('cafe')
  const [newUniversityId, setNewUniversityId] = useState('')
  const [newStartAt, setNewStartAt] = useState('')

  // Edit
  const [editingId, setEditingId] = useState<string | null>(null)
  const [editName, setEditName] = useState('')
  const [editAddress, setEditAddress] = useState('')
  const [editGoogleMapUrl, setEditGoogleMapUrl] = useState('')
  const [editCityId, setEditCityId] = useState('')
  const [editCategory, setEditCategory] = useState<EventCategory>('focused_study')
  const [editType, setEditType] = useState<VenueType>('cafe')
  const [editUniversityId, setEditUniversityId] = useState('')
  const [editStartAt, setEditStartAt] = useState('')
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    loadCities()
  }, [])

  useEffect(() => {
    loadVenues()
  }, [cityFilter, categoryFilter, activeFilter])

  // Load universities when a city is selected (for create/edit forms)
  useEffect(() => {
    const cityId = showCreateForm ? newCityId : editCityId
    if (cityId) {
      loadUniversities(cityId)
    } else {
      setUniversities([])
    }
  }, [newCityId, editCityId, showCreateForm, editingId])

  async function loadCities() {
    const { data } = await supabase.from('cities').select('id, name, slug').order('name')
    if (data) setCities(data)
  }

  async function loadUniversities(cityId: string) {
    const { data } = await supabase
      .from('universities')
      .select('id, name')
      .eq('city_id', cityId)
      .order('name')
    if (data) setUniversities(data)
  }

  async function loadVenues() {
    setLoading(true)
    let query = supabase
      .from('venues')
      .select('*, city:cities(name), university:universities(name)')
      .order('city_id')
      .order('category')
      .order('name')

    if (cityFilter) query = query.eq('city_id', cityFilter)
    if (categoryFilter) query = query.eq('category', categoryFilter)
    if (activeFilter) query = query.eq('is_active', activeFilter === 'true')

    const { data } = await query
    if (data) setVenues(data as unknown as Venue[])
    setLoading(false)
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault()
    if (!newName || !newAddress || !newGoogleMapUrl || !newCityId) return

    setCreating(true)
    const { error } = await supabase.from('venues').insert({
      name: newName,
      address: newAddress,
      google_map_url: newGoogleMapUrl,
      city_id: newCityId,
      category: newCategory,
      type: newType,
      university_id: newType === 'university_library' ? newUniversityId || null : null,
      start_at: newStartAt || null,
    })

    if (error) {
      alert(`建立失敗: ${error.message}`)
    } else {
      setShowCreateForm(false)
      resetCreateForm()
      loadVenues()
    }
    setCreating(false)
  }

  function resetCreateForm() {
    setNewName('')
    setNewAddress('')
    setNewGoogleMapUrl('')
    setNewCityId('')
    setNewCategory('focused_study')
    setNewType('cafe')
    setNewUniversityId('')
    setNewStartAt('')
  }

  function startEdit(venue: Venue) {
    setEditingId(venue.id)
    setEditName(venue.name)
    setEditAddress(venue.address)
    setEditGoogleMapUrl(venue.google_map_url)
    setEditCityId(venue.city_id)
    setEditCategory(venue.category)
    setEditType(venue.type)
    setEditUniversityId(venue.university_id || '')
    setEditStartAt(venue.start_at ? toLocalDatetime(venue.start_at) : '')
  }

  async function handleSaveEdit() {
    if (!editingId || !editName || !editAddress || !editGoogleMapUrl || !editCityId) return

    setSaving(true)
    const { error } = await supabase
      .from('venues')
      .update({
        name: editName,
        address: editAddress,
        google_map_url: editGoogleMapUrl,
        city_id: editCityId,
        category: editCategory,
        type: editType,
        university_id: editType === 'university_library' ? editUniversityId || null : null,
        start_at: editStartAt || null,
      })
      .eq('id', editingId)

    if (error) {
      alert(`更新失敗: ${error.message}`)
    } else {
      setEditingId(null)
      loadVenues()
    }
    setSaving(false)
  }

  async function toggleActive(venue: Venue) {
    const newActive = !venue.is_active
    if (!confirm(`確定要${newActive ? '啟用' : '停用'}此場地嗎？`)) return

    const { error } = await supabase
      .from('venues')
      .update({ is_active: newActive })
      .eq('id', venue.id)

    if (error) {
      alert(`更新失敗: ${error.message}`)
    } else {
      loadVenues()
    }
  }

  // Convert ISO string to datetime-local input value (Taipei time)
  function toLocalDatetime(iso: string): string {
    const d = new Date(iso)
    const taipeiOffset = 8 * 60
    const local = new Date(d.getTime() + (taipeiOffset - d.getTimezoneOffset()) * 60000)
    return local.toISOString().slice(0, 16)
  }

  const inputClass = 'mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary'

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-semibold">場地管理</h2>
        <button
          onClick={() => { setShowCreateForm(!showCreateForm); setEditingId(null) }}
          className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 transition-opacity"
        >
          {showCreateForm ? '取消' : '新增場地'}
        </button>
      </div>

      {/* Create form */}
      {showCreateForm && (
        <form onSubmit={handleCreate} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-5 mb-6">
          <h3 className="text-sm font-semibold mb-4">新增場地</h3>
          <div className="grid grid-cols-2 gap-4">
            <label className="block">
              <span className="text-xs text-secondary-text">場地名稱</span>
              <input type="text" value={newName} onChange={(e) => setNewName(e.target.value)} required className={inputClass} />
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">地址</span>
              <input type="text" value={newAddress} onChange={(e) => setNewAddress(e.target.value)} required className={inputClass} />
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">Google Maps 連結</span>
              <input type="text" value={newGoogleMapUrl} onChange={(e) => setNewGoogleMapUrl(e.target.value)} placeholder="https://..." required className={inputClass} />
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">城市</span>
              <select value={newCityId} onChange={(e) => setNewCityId(e.target.value)} required className={inputClass}>
                <option value="">選擇城市</option>
                {cities.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">活動類別</span>
              <select value={newCategory} onChange={(e) => setNewCategory(e.target.value as EventCategory)} className={inputClass}>
                {Object.entries(CATEGORY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </select>
            </label>
            <label className="block">
              <span className="text-xs text-secondary-text">場地類型</span>
              <select value={newType} onChange={(e) => setNewType(e.target.value as VenueType)} className={inputClass}>
                {Object.entries(VENUE_TYPE_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
              </select>
            </label>
            {newType === 'university_library' && (
              <label className="block">
                <span className="text-xs text-secondary-text">大學</span>
                <select value={newUniversityId} onChange={(e) => setNewUniversityId(e.target.value)} required className={inputClass}>
                  <option value="">選擇大學</option>
                  {universities.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
                </select>
              </label>
            )}
            <label className="block">
              <span className="text-xs text-secondary-text">開始時間（可選）</span>
              <input type="datetime-local" value={newStartAt} onChange={(e) => setNewStartAt(e.target.value)} className={inputClass} />
            </label>
          </div>
          <div className="mt-4 flex justify-end">
            <button type="submit" disabled={creating} className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity">
              {creating ? '建立中...' : '確認建立'}
            </button>
          </div>
        </form>
      )}

      {/* Filters */}
      <div className="flex gap-3 mb-4">
        <select value={cityFilter} onChange={(e) => setCityFilter(e.target.value)} className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary">
          <option value="">全部城市</option>
          {cities.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
        </select>
        <select value={categoryFilter} onChange={(e) => setCategoryFilter(e.target.value as EventCategory | '')} className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary">
          <option value="">全部類別</option>
          {Object.entries(CATEGORY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
        </select>
        <select value={activeFilter} onChange={(e) => setActiveFilter(e.target.value as '' | 'true' | 'false')} className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary">
          <option value="">全部狀態</option>
          <option value="true">啟用中</option>
          <option value="false">已停用</option>
        </select>
      </div>

      {/* Venues table */}
      <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-tertiary bg-alternate/50">
              <th className="text-left px-4 py-3 font-medium text-secondary-text">名稱</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">城市</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">類別</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">類型</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">開始時間</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">狀態</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-tertiary-text">載入中...</td></tr>
            ) : venues.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-tertiary-text">暫無場地</td></tr>
            ) : (
              venues.map((venue) => (
                <>
                  <tr
                    key={venue.id}
                    className={`border-b border-tertiary hover:bg-alternate/30 transition-colors cursor-pointer ${editingId === venue.id ? 'bg-alternate/20' : ''}`}
                    onClick={() => editingId === venue.id ? setEditingId(null) : startEdit(venue)}
                  >
                    <td className="px-4 py-3">
                      <p className="font-medium">{venue.name}</p>
                      <p className="text-xs text-tertiary-text">{venue.address}</p>
                    </td>
                    <td className="px-4 py-3 text-secondary-text">{venue.city?.name ?? '-'}</td>
                    <td className="px-4 py-3 text-secondary-text">{CATEGORY_LABELS[venue.category]}</td>
                    <td className="px-4 py-3 text-secondary-text">
                      {VENUE_TYPE_LABELS[venue.type]}
                      {venue.university?.name && (
                        <span className="text-xs text-tertiary-text block">{venue.university.name}</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-tertiary-text text-xs">
                      {venue.start_at ? formatDateTime(venue.start_at) : '-'}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge
                        label={venue.is_active ? '啟用' : '停用'}
                        color={venue.is_active ? 'green' : 'gray'}
                      />
                    </td>
                  </tr>

                  {/* Inline edit form */}
                  {editingId === venue.id && (
                    <tr key={`${venue.id}-edit`}>
                      <td colSpan={6} className="bg-alternate/20 px-4 py-4 border-b border-tertiary">
                        <div className="grid grid-cols-2 gap-4">
                          <label className="block">
                            <span className="text-xs text-secondary-text">場地名稱</span>
                            <input type="text" value={editName} onChange={(e) => setEditName(e.target.value)} className={inputClass} />
                          </label>
                          <label className="block">
                            <span className="text-xs text-secondary-text">地址</span>
                            <input type="text" value={editAddress} onChange={(e) => setEditAddress(e.target.value)} className={inputClass} />
                          </label>
                          <label className="block">
                            <span className="text-xs text-secondary-text">Google Maps 連結</span>
                            <input type="text" value={editGoogleMapUrl} onChange={(e) => setEditGoogleMapUrl(e.target.value)} className={inputClass} />
                          </label>
                          <label className="block">
                            <span className="text-xs text-secondary-text">城市</span>
                            <select value={editCityId} onChange={(e) => setEditCityId(e.target.value)} className={inputClass}>
                              <option value="">選擇城市</option>
                              {cities.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                            </select>
                          </label>
                          <label className="block">
                            <span className="text-xs text-secondary-text">活動類別</span>
                            <select value={editCategory} onChange={(e) => setEditCategory(e.target.value as EventCategory)} className={inputClass}>
                              {Object.entries(CATEGORY_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                            </select>
                          </label>
                          <label className="block">
                            <span className="text-xs text-secondary-text">場地類型</span>
                            <select value={editType} onChange={(e) => setEditType(e.target.value as VenueType)} className={inputClass}>
                              {Object.entries(VENUE_TYPE_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                            </select>
                          </label>
                          {editType === 'university_library' && (
                            <label className="block">
                              <span className="text-xs text-secondary-text">大學</span>
                              <select value={editUniversityId} onChange={(e) => setEditUniversityId(e.target.value)} className={inputClass}>
                                <option value="">選擇大學</option>
                                {universities.map((u) => <option key={u.id} value={u.id}>{u.name}</option>)}
                              </select>
                            </label>
                          )}
                          <label className="block">
                            <span className="text-xs text-secondary-text">開始時間</span>
                            <input type="datetime-local" value={editStartAt} onChange={(e) => setEditStartAt(e.target.value)} className={inputClass} />
                          </label>
                        </div>
                        <div className="mt-4 flex items-center gap-3">
                          <button
                            onClick={handleSaveEdit}
                            disabled={saving}
                            className="px-4 py-2 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                          >
                            {saving ? '儲存中...' : '儲存'}
                          </button>
                          <button
                            onClick={() => setEditingId(null)}
                            className="px-4 py-2 bg-secondary border-2 border-tertiary text-secondary-text rounded-[var(--radius-app)] text-sm hover:opacity-80 transition-opacity"
                          >
                            取消
                          </button>
                          <button
                            onClick={() => toggleActive(venue)}
                            className="ml-auto px-4 py-2 bg-secondary border-2 border-tertiary text-secondary-text rounded-[var(--radius-app)] text-sm hover:opacity-80 transition-opacity"
                          >
                            {venue.is_active ? '停用場地' : '啟用場地'}
                          </button>
                        </div>
                      </td>
                    </tr>
                  )}
                </>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
