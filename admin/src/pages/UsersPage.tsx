import { useEffect, useState } from 'react'
import { supabase, invokeSendUserPush } from '../lib/supabase'
import type { UserProfile, University } from '../types/database'
import { formatDateTime } from '../lib/date'

export default function UsersPage() {
  const [searchQuery, setSearchQuery] = useState('')
  const [allUsers, setAllUsers] = useState<UserProfile[]>([])
  const [loading, setLoading] = useState(true)
  const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null)
  const [universities, setUniversities] = useState<University[]>([])
  const [selectedUniversityId, setSelectedUniversityId] = useState('')
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    loadAllUsers()
    loadUniversities()
  }, [])

  async function loadAllUsers() {
    setLoading(true)
    const { data } = await supabase
      .from('user_profile_v')
      .select('id, nickname, gender, age, school_email, school_email_status, school_email_verification_method, university_id, university_name, university_code, created_at')
      .order('created_at', { ascending: false })
    setAllUsers((data as unknown as UserProfile[]) || [])
    setLoading(false)
  }

  async function loadUniversities() {
    const { data } = await supabase
      .from('universities')
      .select('id, name, code')
      .order('code', { ascending: true })
    setUniversities((data as unknown as University[]) || [])
  }

  const displayUsers = searchQuery.trim()
    ? allUsers.filter(
        (u) =>
          u.nickname?.toLowerCase().includes(searchQuery.toLowerCase()) ||
          u.school_email?.toLowerCase().includes(searchQuery.toLowerCase()),
      )
    : allUsers

  function selectUser(user: UserProfile) {
    setSelectedUser(user)
    setSelectedUniversityId('')
  }

  function getVerificationBadge(user: UserProfile) {
    if (user.school_email_status === 'verified') {
      if (user.school_email_verification_method === 'manual') {
        return <span className="text-[11px] px-1.5 py-0.5 rounded bg-alternate text-secondary-text">客服驗證</span>
      }
      return <span className="text-[11px] px-1.5 py-0.5 rounded bg-alternate text-secondary-text">已驗證</span>
    }
    return <span className="text-[11px] px-1.5 py-0.5 rounded bg-tertiary/30 text-tertiary-text">未驗證</span>
  }

  async function handleManualVerify(e: React.FormEvent) {
    e.preventDefault()
    if (!selectedUser || !selectedUniversityId) return

    const uniName = universities.find((u) => u.id === selectedUniversityId)?.name || ''
    if (!confirm(`確定要手動驗證此用戶為「${uniName}」的學生嗎？`)) return

    setSubmitting(true)

    // 1. 查找該大學的 email domain
    const { data: domainRow, error: domainError } = await supabase
      .from('university_email_domains')
      .select('domain')
      .eq('university_id', selectedUniversityId)
      .limit(1)
      .single()

    if (domainError || !domainRow) {
      alert('找不到該大學的 email domain')
      setSubmitting(false)
      return
    }

    // 2. 建構 manual email
    const prefix = selectedUser.id.replace(/-/g, '').substring(0, 8)
    const manualEmail = `manual.${prefix}@${domainRow.domain}`

    // 3. 將該用戶現有的 active school emails 設為 inactive
    await supabase
      .from('user_school_emails')
      .update({
        is_active: false,
        released_at: new Date().toISOString(),
        released_reason: 'manual_verification_replacement',
      })
      .eq('user_id', selectedUser.id)
      .eq('is_active', true)

    // 4. INSERT 新的 verified record
    const { error } = await supabase
      .from('user_school_emails')
      .insert({
        user_id: selectedUser.id,
        school_email: manualEmail,
        status: 'verified',
        verified_at: new Date().toISOString(),
        is_active: true,
        verification_method: 'manual',
      })

    if (error) {
      alert(`驗證失敗: ${error.message}`)
    } else {
      alert('手動驗證成功！')

      // 發送推播通知提醒用戶
      try {
        await invokeSendUserPush({
          user_id: selectedUser.id,
          title: '學校驗證完成',
          body: '您的學校身分已驗證成功！現在可以開始報名活動了。',
          data: { type: 'school_verified' },
        })
      } catch (pushError) {
        console.warn('推播通知發送失敗:', pushError)
      }

      setSelectedUniversityId('')
      await loadAllUsers()
      // 重新選取用戶以更新右側面板
      const { data: updated } = await supabase
        .from('user_profile_v')
        .select('id, nickname, gender, age, school_email, school_email_status, school_email_verification_method, university_id, university_name, university_code, created_at')
        .eq('id', selectedUser.id)
        .single()
      if (updated) setSelectedUser(updated as unknown as UserProfile)
    }
    setSubmitting(false)
  }

  const isVerified = selectedUser?.school_email_status === 'verified'

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-6">用戶管理</h2>

      {/* Search */}
      <div className="mb-6">
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="輸入暱稱或 Email 篩選用戶..."
          className="w-full border-2 border-tertiary rounded-[var(--radius-app)] px-4 py-2 text-sm bg-secondary"
        />
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* User list */}
        <div>
          {loading ? (
            <div className="text-center py-8 text-secondary-text text-sm">載入中...</div>
          ) : displayUsers.length > 0 ? (
            <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
              <div className="px-4 py-2 bg-alternate/50 text-xs font-medium text-secondary-text">
                用戶列表 ({displayUsers.length})
              </div>
              {displayUsers.map((user) => (
                <div
                  key={user.id}
                  onClick={() => selectUser(user)}
                  className={`px-4 py-3 border-b border-tertiary last:border-0 cursor-pointer hover:bg-alternate/30 transition-colors ${
                    selectedUser?.id === user.id ? 'bg-alternate' : ''
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-medium">{user.nickname || '(未設定暱稱)'}</p>
                    {getVerificationBadge(user)}
                  </div>
                  <p className="text-xs text-tertiary-text">
                    {user.age ? `${user.age}歲` : '-'} ·{' '}
                    {user.gender === 'male' ? '男性' : user.gender === 'female' ? '女性' : '-'} · {user.university_name || '未驗證學校'}
                  </p>
                  <p className="text-xs text-tertiary-text mt-0.5">
                    帳號建立：{formatDateTime(user.created_at)}
                  </p>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-8 text-secondary-text text-sm">
              {searchQuery.trim() ? '找不到符合的用戶' : '尚無用戶'}
            </div>
          )}
        </div>

        {/* User detail + manual verification */}
        <div>
          {selectedUser && (
            <div className="space-y-4">
              {/* User info */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-2">用戶資訊</h3>
                <p className="text-sm">{selectedUser.nickname || '(未設定暱稱)'}</p>
                <p className="text-xs text-secondary-text">
                  {selectedUser.age ? `${selectedUser.age}歲` : '-'} ·{' '}
                  {selectedUser.gender === 'male' ? '男性' : selectedUser.gender === 'female' ? '女性' : '-'} ·{' '}
                  {selectedUser.university_name || '未驗證學校'}
                </p>
                <p className="text-xs text-tertiary-text mt-1">ID: {selectedUser.id}</p>
              </div>

              {/* Verification status */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-2">學校驗證狀態</h3>
                {isVerified ? (
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className="text-sm text-secondary-text">✓ 已驗證</span>
                      {selectedUser.school_email_verification_method === 'manual' && (
                        <span className="text-[11px] px-1.5 py-0.5 rounded bg-alternate text-secondary-text">客服驗證</span>
                      )}
                    </div>
                    <p className="text-xs text-tertiary-text">學校：{selectedUser.university_name}</p>
                    {selectedUser.school_email_verification_method !== 'manual' && (
                      <p className="text-xs text-tertiary-text">信箱：{selectedUser.school_email}</p>
                    )}
                  </div>
                ) : (
                  <p className="text-sm text-tertiary-text">尚未驗證學校身分</p>
                )}
              </div>

              {/* Manual verification form */}
              {!isVerified && (
                <form onSubmit={handleManualVerify} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                  <h3 className="text-sm font-semibold mb-3">手動驗證學校身分</h3>
                  <p className="text-xs text-tertiary-text mb-3">
                    用戶提供學生證等證明後，選擇對應的大學完成驗證。
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
                      disabled={submitting || !selectedUniversityId}
                      className="px-4 py-3 bg-alternate text-primary-text rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                    >
                      {submitting ? '處理中...' : '確認驗證'}
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
