import { useState } from 'react'
import { supabase } from '../lib/supabase'
import type { UserProfile, TicketBalance, TicketLedgerEntry, TicketType } from '../types/database'
import { REASON_LABELS } from '../types/database'
import { formatDateTime } from '../lib/date'

export default function TicketsPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [searchResults, setSearchResults] = useState<UserProfile[]>([])
  const [searching, setSearching] = useState(false)
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null)
  const [balance, setBalance] = useState<TicketBalance | null>(null)
  const [ledger, setLedger] = useState<TicketLedgerEntry[]>([])
  const [adjustType, setAdjustType] = useState<TicketType>('study')
  const [adjustAmount, setAdjustAmount] = useState<number>(0)
  const [submitting, setSubmitting] = useState(false)

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault()
    if (!searchQuery.trim()) return

    setSearching(true)
    // Search by nickname or email in user_profile_v
    const { data } = await supabase
      .from('user_profile_v')
      .select('id, nickname, gender, age, school_email, university_name, university_code, created_at')
      .or(`nickname.ilike.%${searchQuery}%,school_email.ilike.%${searchQuery}%`)
      .limit(20)

    setSearchResults((data as unknown as UserProfile[]) || [])
    setSearching(false)
  }

  async function selectUser(user: UserProfile) {
    setSelectedUser(user)
    // Load balance
    const { data: balanceData } = await supabase
      .from('user_ticket_balances_v')
      .select('*')
      .eq('user_id', user.id)
      .single()
    setBalance(balanceData as unknown as TicketBalance | null)

    // Load recent ledger entries
    const { data: ledgerData } = await supabase
      .from('ticket_ledger')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
      .limit(10)
    setLedger((ledgerData as unknown as TicketLedgerEntry[]) || [])
  }

  async function handleAdjust(e: React.FormEvent) {
    e.preventDefault()
    if (!selectedUser || adjustAmount === 0) return

    if (!confirm(`確定要${adjustAmount > 0 ? '增加' : '扣除'} ${Math.abs(adjustAmount)} 張${adjustType === 'study' ? '讀書' : '遊戲'}票嗎？`)) return

    setSubmitting(true)
    const { error } = await supabase.from('ticket_ledger').insert({
      user_id: selectedUser.id,
      delta_study: adjustType === 'study' ? adjustAmount : 0,
      delta_games: adjustType === 'games' ? adjustAmount : 0,
      reason: 'admin_adjust',
    })

    if (error) {
      alert(`調整失敗: ${error.message}`)
    } else {
      alert('票券調整成功！')
      setAdjustAmount(0)
      selectUser(selectedUser) // Reload balance & ledger
    }
    setSubmitting(false)
  }

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-6">票券調整</h2>

      {/* Search */}
      <form onSubmit={handleSearch} className="flex gap-3 mb-6">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="輸入暱稱或 Email 搜尋用戶..."
          className="flex-1 border-2 border-tertiary rounded-[var(--radius-app)] px-4 py-2 text-sm bg-secondary"
        />
        <button
          type="submit"
          disabled={searching}
          className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
        >
          {searching ? '搜尋中...' : '搜尋'}
        </button>
      </form>

      <div className="grid grid-cols-2 gap-6">
        {/* Search results */}
        <div>
          {searchResults.length > 0 && (
            <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
              <div className="px-4 py-2 bg-alternate/50 text-xs font-medium text-secondary-text">
                搜尋結果 ({searchResults.length})
              </div>
              {searchResults.map((user) => (
                <div
                  key={user.id}
                  onClick={() => selectUser(user)}
                  className={`px-4 py-3 border-b border-tertiary last:border-0 cursor-pointer hover:bg-alternate/30 transition-colors ${
                    selectedUser?.id === user.id ? 'bg-alternate' : ''
                  }`}
                >
                  <p className="text-sm font-medium">{user.nickname || '(未設定暱稱)'}</p>
                  <p className="text-xs text-tertiary-text">
                    {user.gender === 'male' ? '男' : user.gender === 'female' ? '女' : '-'} ·{' '}
                    {user.age || '-'} · {user.school_email || '-'}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* User detail + adjustment */}
        <div>
          {selectedUser && (
            <div className="space-y-4">
              {/* User info */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-2">用戶資訊</h3>
                <p className="text-sm">{selectedUser.nickname || '(未設定暱稱)'}</p>
                <p className="text-xs text-secondary-text">
                  {selectedUser.gender === 'male' ? '男' : '女'} · {selectedUser.age}歲 ·{' '}
                  {selectedUser.university_name || '-'}
                </p>
                <p className="text-xs text-tertiary-text mt-1">{selectedUser.school_email}</p>
              </div>

              {/* Balance */}
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4 text-center">
                  <p className="text-2xl font-semibold">{balance?.study_balance ?? 0}</p>
                  <p className="text-xs text-secondary-text">讀書票</p>
                </div>
                <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4 text-center">
                  <p className="text-2xl font-semibold">{balance?.games_balance ?? 0}</p>
                  <p className="text-xs text-secondary-text">遊戲票</p>
                </div>
              </div>

              {/* Adjust form */}
              <form onSubmit={handleAdjust} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-3">調整票券</h3>
                <div className="flex items-end gap-3">
                  <label className="block">
                    <span className="text-xs text-secondary-text">類型</span>
                    <select
                      value={adjustType}
                      onChange={(e) => setAdjustType(e.target.value as TicketType)}
                      className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                    >
                      <option value="study">讀書票</option>
                      <option value="games">遊戲票</option>
                    </select>
                  </label>
                  <label className="block flex-1">
                    <span className="text-xs text-secondary-text">數量（正=增加，負=扣除）</span>
                    <input
                      type="number"
                      value={adjustAmount}
                      onChange={(e) => setAdjustAmount(Number(e.target.value))}
                      className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                    />
                  </label>
                  <button
                    type="submit"
                    disabled={submitting || adjustAmount === 0}
                    className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                  >
                    {submitting ? '處理中...' : '提交'}
                  </button>
                </div>
              </form>

              {/* Recent ledger */}
              {ledger.length > 0 && (
                <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
                  <div className="px-4 py-2 bg-alternate/50 text-xs font-medium text-secondary-text">
                    最近異動紀錄
                  </div>
                  {ledger.map((entry) => {
                    const delta = entry.delta_study !== 0 ? entry.delta_study : entry.delta_games
                    const type = entry.delta_study !== 0 ? '讀書' : '遊戲'
                    return (
                      <div key={entry.id} className="flex items-center justify-between px-4 py-2 border-b border-tertiary last:border-0 text-sm">
                        <div>
                          <span className="text-secondary-text">{REASON_LABELS[entry.reason]}</span>
                          <span className="text-tertiary-text text-xs ml-2">{type}票</span>
                        </div>
                        <div className="flex items-center gap-3">
                          <span className={delta > 0 ? 'text-secondary-text font-medium' : 'text-tertiary-text font-medium'}>
                            {delta > 0 ? '+' : ''}{delta}
                          </span>
                          <span className="text-xs text-tertiary-text">
                            {formatDateTime(entry.created_at)}
                          </span>
                        </div>
                      </div>
                    )
                  })}
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
