import { useEffect, useState } from 'react'
import { supabase, invokeSendUserPush } from '../lib/supabase'
import { formatDateTime } from '../lib/date'
import type { University } from '../types/database'

type VerificationStatus = 'pending' | 'auto_verified' | 'manual_review' | 'admin_verified' | 'rejected'

interface Verification {
  id: string
  user_id: string
  storage_path: string
  status: VerificationStatus
  ai_university_name: string | null
  ai_student_name: string | null
  ai_student_id_number: string | null
  ai_confidence: number | null
  ai_issues: string[] | null
  matched_university_id: string | null
  review_notes: string | null
  reviewed_by: string | null
  reviewed_at: string | null
  created_at: string
  // joined
  nickname: string | null
}

interface UserInfo {
  id: string
  nickname: string | null
  gender: string | null
  age: number | null
  school_email_status: string | null
  university_name: string | null
}

const STATUS_LABELS: Record<VerificationStatus, string> = {
  pending: '處理中',
  auto_verified: 'AI 自動通過',
  manual_review: '待人工審核',
  admin_verified: '已人工驗證',
  rejected: '已拒絕',
}

const STATUS_COLORS: Record<VerificationStatus, string> = {
  pending: 'bg-gray-100 text-gray-600',
  auto_verified: 'bg-emerald-100 text-emerald-800',
  manual_review: 'bg-amber-100 text-amber-800',
  admin_verified: 'bg-emerald-100 text-emerald-800',
  rejected: 'bg-red-50 text-red-700',
}

const REJECT_REASONS = [
  '照片模糊或不清晰，請重新拍攝',
  '照片非學生證，請提供有效學生證',
  '學生證上的資訊不完整',
]

const REVOKE_REASONS = [
  '學生證資訊與本人不符',
  '提供的學生證為偽造',
  '學生證已過期',
]

export default function StudentIdReviewPage() {
  const [verifications, setVerifications] = useState<Verification[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<VerificationStatus | ''>('')
  const [selected, setSelected] = useState<Verification | null>(null)
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null)
  const [photoUrl, setPhotoUrl] = useState<string | null>(null)

  // Approve form
  const [universities, setUniversities] = useState<University[]>([])
  const [selectedUniversityId, setSelectedUniversityId] = useState('')
  const [submitting, setSubmitting] = useState(false)

  // Reject/Revoke form
  const [rejectReason, setRejectReason] = useState('')
  const [customReason, setCustomReason] = useState('')

  useEffect(() => {
    loadVerifications()
    loadUniversities()
  }, [])

  async function loadVerifications() {
    setLoading(true)
    // Query verifications with user nickname via RPC or join
    const { data } = await supabase
      .from('student_id_verifications')
      .select('id, user_id, storage_path, status, ai_university_name, ai_student_name, ai_student_id_number, ai_confidence, ai_issues, matched_university_id, review_notes, reviewed_by, reviewed_at, created_at')
      .order('created_at', { ascending: false })

    if (data) {
      // Fetch nicknames for all user_ids
      const userIds = [...new Set(data.map((v: { user_id: string }) => v.user_id))]
      const { data: profiles } = await supabase
        .from('user_profile_v')
        .select('id, nickname')
        .in('id', userIds)

      const nicknameMap = new Map((profiles || []).map((p: { id: string; nickname: string | null }) => [p.id, p.nickname]))

      setVerifications(
        data.map((v: Record<string, unknown>) => ({
          ...v,
          nickname: nicknameMap.get(v.user_id as string) || null,
        })) as Verification[]
      )
    }
    setLoading(false)
  }

  async function loadUniversities() {
    const { data } = await supabase
      .from('universities')
      .select('id, name, code')
      .order('code', { ascending: true })
    setUniversities((data as unknown as University[]) || [])
  }

  async function selectVerification(v: Verification) {
    setSelected(v)
    setSelectedUniversityId(v.matched_university_id || '')
    setRejectReason('')
    setCustomReason('')
    setPhotoUrl(null)

    // Load user info
    const { data: userData } = await supabase
      .from('user_profile_v')
      .select('id, nickname, gender, age, school_email_status, university_name')
      .eq('id', v.user_id)
      .single()
    setUserInfo(userData as unknown as UserInfo | null)

    // Load photo
    if (v.storage_path) {
      const { data: urlData } = await supabase.storage
        .from('student-id-uploads')
        .createSignedUrl(v.storage_path, 3600)
      if (urlData?.signedUrl) {
        setPhotoUrl(urlData.signedUrl)
      }
    }
  }

  // ─── 通過驗證 ───
  async function handleApprove(e: React.FormEvent) {
    e.preventDefault()
    if (!selected || !userInfo || !selectedUniversityId) return

    const uniName = universities.find((u) => u.id === selectedUniversityId)?.name || ''
    if (!confirm(`確定要驗證此用戶為「${uniName}」的學生嗎？`)) return

    setSubmitting(true)

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

    // Deactivate existing active emails
    await supabase
      .from('user_school_emails')
      .update({
        is_active: false,
        released_at: new Date().toISOString(),
        released_reason: 'admin_verification_replacement',
      })
      .eq('user_id', userInfo.id)
      .eq('is_active', true)

    // Create verified email
    const prefix = userInfo.id.replace(/-/g, '').substring(0, 8)
    const adminEmail = `admin.${prefix}@${domainRow.domain}`

    const { data: emailRecord, error: emailError } = await supabase
      .from('user_school_emails')
      .insert({
        user_id: userInfo.id,
        school_email: adminEmail,
        status: 'verified',
        verified_at: new Date().toISOString(),
        is_active: true,
        verification_method: 'manual',
      })
      .select('id')
      .single()

    if (emailError) {
      alert(`驗證失敗: ${emailError.message}`)
      setSubmitting(false)
      return
    }

    // Update verification record
    await supabase
      .from('student_id_verifications')
      .update({
        status: 'admin_verified',
        reviewed_by: 'admin',
        reviewed_at: new Date().toISOString(),
        review_notes: `通過驗證：${uniName}`,
        school_email_id: emailRecord?.id,
      })
      .eq('id', selected.id)

    // Push notification
    try {
      await invokeSendUserPush({
        user_id: userInfo.id,
        title: '學校驗證完成',
        body: '您的學校身分已驗證成功！現在可以開始報名活動了。',
        data: { type: 'school_verified' },
      })
    } catch (e) {
      console.warn('推播通知發送失敗:', e)
    }

    alert('驗證成功！')
    setSubmitting(false)
    await loadVerifications()
    // Refresh selected
    const { data: updated } = await supabase
      .from('student_id_verifications')
      .select('id, user_id, storage_path, status, ai_university_name, ai_student_name, ai_student_id_number, ai_confidence, ai_issues, matched_university_id, review_notes, reviewed_by, reviewed_at, created_at')
      .eq('id', selected.id)
      .single()
    if (updated) {
      selectVerification({ ...(updated as unknown as Verification), nickname: selected.nickname })
    }
  }

  // ─── 拒絕 ───
  async function handleReject() {
    if (!selected || !userInfo) return

    const reason = rejectReason === '__custom' ? customReason.trim() : rejectReason
    if (!reason) {
      alert('請選擇或輸入拒絕原因')
      return
    }
    if (!confirm(`確定要拒絕此驗證申請嗎？\n原因：${reason}`)) return

    setSubmitting(true)

    await supabase
      .from('student_id_verifications')
      .update({
        status: 'rejected',
        reviewed_by: 'admin',
        reviewed_at: new Date().toISOString(),
        review_notes: reason,
      })
      .eq('id', selected.id)

    // Push notification
    try {
      await invokeSendUserPush({
        user_id: userInfo.id,
        title: '學校驗證未通過',
        body: `${reason}，請重新提交。`,
        data: { type: 'school_verification_rejected' },
      })
    } catch (e) {
      console.warn('推播通知發送失敗:', e)
    }

    alert('已拒絕此驗證申請')
    setSubmitting(false)
    await loadVerifications()
    const { data: updated } = await supabase
      .from('student_id_verifications')
      .select('id, user_id, storage_path, status, ai_university_name, ai_student_name, ai_student_id_number, ai_confidence, ai_issues, matched_university_id, review_notes, reviewed_by, reviewed_at, created_at')
      .eq('id', selected.id)
      .single()
    if (updated) {
      selectVerification({ ...(updated as unknown as Verification), nickname: selected.nickname })
    }
  }

  // ─── 撤回驗證 ───
  async function handleRevoke() {
    if (!selected || !userInfo) return

    const reason = rejectReason === '__custom' ? customReason.trim() : rejectReason
    if (!reason) {
      alert('請選擇或輸入撤回原因')
      return
    }
    if (!confirm(`確定要撤回此用戶的學校驗證嗎？\n原因：${reason}`)) return

    setSubmitting(true)

    // Deactivate user_school_emails
    await supabase
      .from('user_school_emails')
      .update({
        is_active: false,
        released_at: new Date().toISOString(),
        released_reason: 'admin_revoked',
      })
      .eq('user_id', userInfo.id)
      .eq('is_active', true)

    // Update verification record
    await supabase
      .from('student_id_verifications')
      .update({
        status: 'rejected',
        reviewed_by: 'admin',
        reviewed_at: new Date().toISOString(),
        review_notes: `撤回驗證：${reason}`,
      })
      .eq('id', selected.id)

    // Push notification
    try {
      await invokeSendUserPush({
        user_id: userInfo.id,
        title: '學校驗證已被撤回',
        body: `${reason}，請重新驗證。`,
        data: { type: 'school_verification_revoked' },
      })
    } catch (e) {
      console.warn('推播通知發送失敗:', e)
    }

    alert('已撤回驗證')
    setSubmitting(false)
    await loadVerifications()
    const { data: updated } = await supabase
      .from('student_id_verifications')
      .select('id, user_id, storage_path, status, ai_university_name, ai_student_name, ai_student_id_number, ai_confidence, ai_issues, matched_university_id, review_notes, reviewed_by, reviewed_at, created_at')
      .eq('id', selected.id)
      .single()
    if (updated) {
      selectVerification({ ...(updated as unknown as Verification), nickname: selected.nickname })
    }
  }

  const displayVerifications = statusFilter
    ? verifications.filter((v) => v.status === statusFilter)
    : verifications

  const isApproved = selected?.status === 'auto_verified' || selected?.status === 'admin_verified'
  const isManualReview = selected?.status === 'manual_review'
  const reasonOptions = isApproved ? REVOKE_REASONS : REJECT_REASONS

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-6">學生證審查</h2>

      {/* Status filter */}
      <div className="mb-6">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as VerificationStatus | '')}
          className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
        >
          <option value="">全部狀態</option>
          {(Object.entries(STATUS_LABELS) as [VerificationStatus, string][]).map(([k, v]) => (
            <option key={k} value={k}>{v}</option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-2 gap-6">
        {/* Left: verification list */}
        <div>
          {loading ? (
            <div className="text-center py-8 text-secondary-text text-sm">載入中...</div>
          ) : displayVerifications.length > 0 ? (
            <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
              <div className="px-4 py-2 bg-alternate/50 text-xs font-medium text-secondary-text">
                驗證記錄 ({displayVerifications.length})
              </div>
              <div className="max-h-[calc(100vh-240px)] overflow-y-auto">
                {displayVerifications.map((v) => (
                  <div
                    key={v.id}
                    onClick={() => selectVerification(v)}
                    className={`px-4 py-3 border-b border-tertiary last:border-0 cursor-pointer hover:bg-alternate/30 transition-colors ${
                      selected?.id === v.id ? 'bg-alternate' : ''
                    }`}
                  >
                    <div className="flex items-center gap-2">
                      <p className="text-sm font-medium flex-1 truncate">
                        {v.nickname || '(未設定暱稱)'}
                      </p>
                      <span className={`text-[11px] px-1.5 py-0.5 rounded shrink-0 ${STATUS_COLORS[v.status]}`}>
                        {STATUS_LABELS[v.status]}
                      </span>
                    </div>
                    <p className="text-xs text-tertiary-text mt-0.5">
                      信心度：{v.ai_confidence ?? '-'}% · {v.ai_university_name || '未辨識'} · {formatDateTime(v.created_at)}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div className="text-center py-8 text-secondary-text text-sm">
              尚無驗證記錄
            </div>
          )}
        </div>

        {/* Right: detail + actions */}
        <div>
          {selected && (
            <div className="space-y-4">
              {/* User info card */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <h3 className="text-sm font-semibold mb-2">用戶資訊</h3>
                <p className="text-sm">{userInfo?.nickname || '(未設定暱稱)'}</p>
                <p className="text-xs text-secondary-text">
                  {userInfo?.age ? `${userInfo.age}歲` : '-'} ·{' '}
                  {userInfo?.gender === 'male' ? '男性' : userInfo?.gender === 'female' ? '女性' : '-'} ·{' '}
                  {userInfo?.university_name || '未驗證學校'}
                </p>
                <p className="text-xs text-tertiary-text mt-1">ID: {selected.user_id}</p>
              </div>

              {/* AI analysis card */}
              <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-semibold">AI 分析結果</h3>
                  <span className={`text-[11px] px-1.5 py-0.5 rounded ${STATUS_COLORS[selected.status]}`}>
                    {STATUS_LABELS[selected.status]}
                  </span>
                </div>
                <div className="space-y-2">
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-secondary-text w-16">信心度</span>
                    <span className={`text-sm font-medium ${
                      (selected.ai_confidence ?? 0) >= 80 ? 'text-emerald-700' : 'text-amber-700'
                    }`}>
                      {selected.ai_confidence ?? '-'}%
                    </span>
                  </div>
                  {selected.ai_university_name && (
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-secondary-text w-16">大學</span>
                      <span className="text-sm">{selected.ai_university_name}</span>
                    </div>
                  )}
                  {selected.ai_student_name && (
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-secondary-text w-16">姓名</span>
                      <span className="text-sm">{selected.ai_student_name}</span>
                    </div>
                  )}
                  {selected.ai_student_id_number && (
                    <div className="flex items-center gap-2">
                      <span className="text-xs text-secondary-text w-16">學號</span>
                      <span className="text-sm">{selected.ai_student_id_number}</span>
                    </div>
                  )}
                  {selected.ai_issues && selected.ai_issues.length > 0 && (
                    <div className="flex gap-2">
                      <span className="text-xs text-secondary-text w-16 shrink-0">問題</span>
                      <div className="flex flex-wrap gap-1">
                        {selected.ai_issues.map((issue, i) => (
                          <span key={i} className="text-[11px] px-1.5 py-0.5 rounded bg-red-50 text-red-700">
                            {issue}
                          </span>
                        ))}
                      </div>
                    </div>
                  )}
                  {selected.review_notes && (
                    <div className="flex gap-2">
                      <span className="text-xs text-secondary-text w-16 shrink-0">備註</span>
                      <span className="text-xs text-tertiary-text">{selected.review_notes}</span>
                    </div>
                  )}
                  {selected.reviewed_at && (
                    <div className="flex gap-2">
                      <span className="text-xs text-secondary-text w-16 shrink-0">審核時間</span>
                      <span className="text-xs text-tertiary-text">{formatDateTime(selected.reviewed_at)}</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Photo card */}
              {photoUrl && (
                <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                  <h3 className="text-sm font-semibold mb-2">學生證照片</h3>
                  <img
                    src={photoUrl}
                    alt="學生證"
                    className="max-h-64 rounded border border-tertiary cursor-pointer"
                    onClick={() => window.open(photoUrl, '_blank')}
                  />
                </div>
              )}

              {/* Action: Approve (manual_review only) */}
              {isManualReview && (
                <form onSubmit={handleApprove} className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                  <h3 className="text-sm font-semibold mb-3">通過驗證</h3>
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
                      className="px-4 py-3 bg-emerald-100 text-emerald-800 rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                    >
                      {submitting ? '處理中...' : '確認通過'}
                    </button>
                  </div>
                </form>
              )}

              {/* Action: Reject (manual_review) or Revoke (auto_verified / admin_verified) */}
              {(isManualReview || isApproved) && (
                <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] p-4">
                  <h3 className="text-sm font-semibold mb-3">
                    {isApproved ? '撤回驗證' : '拒絕驗證'}
                  </h3>
                  <div className="space-y-3">
                    <label className="block">
                      <span className="text-xs text-secondary-text">
                        {isApproved ? '撤回原因' : '拒絕原因'}
                      </span>
                      <select
                        value={rejectReason}
                        onChange={(e) => {
                          setRejectReason(e.target.value)
                          if (e.target.value !== '__custom') setCustomReason('')
                        }}
                        className="mt-1 block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                      >
                        <option value="">選擇原因...</option>
                        {reasonOptions.map((r) => (
                          <option key={r} value={r}>{r}</option>
                        ))}
                        <option value="__custom">自訂原因...</option>
                      </select>
                    </label>
                    {rejectReason === '__custom' && (
                      <input
                        type="text"
                        value={customReason}
                        onChange={(e) => setCustomReason(e.target.value)}
                        placeholder="請輸入原因..."
                        className="block w-full border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
                      />
                    )}
                    <button
                      onClick={isApproved ? handleRevoke : handleReject}
                      disabled={submitting || (!rejectReason || (rejectReason === '__custom' && !customReason.trim()))}
                      className="px-4 py-2.5 bg-red-50 text-red-700 rounded-[var(--radius-app)] text-sm font-semibold hover:opacity-80 disabled:opacity-50 transition-opacity"
                    >
                      {submitting ? '處理中...' : isApproved ? '確認撤回' : '確認拒絕'}
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
