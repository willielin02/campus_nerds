const WEEKDAYS = ['日', '一', '二', '三', '四', '五', '六']

/** 活動日期：2 月 14 日 ( 六 ) */
export function formatEventDate(dateStr: string): string {
  const d = new Date(dateStr + 'T00:00:00+08:00')
  const month = d.getMonth() + 1
  const day = d.getDate()
  const weekday = WEEKDAYS[d.getDay()]
  return `${month} 月 ${day} 日 ( ${weekday} )`
}

/** 時間戳記：yyyy/MM/dd HH:mm */
export function formatDateTime(isoStr: string): string {
  const d = new Date(isoStr)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  const h = String(d.getHours()).padStart(2, '0')
  const min = String(d.getMinutes()).padStart(2, '0')
  return `${y}/${m}/${day} ${h}:${min}`
}

/** 純日期：yyyy/MM/dd */
export function formatDate(isoStr: string): string {
  const d = new Date(isoStr)
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}/${m}/${day}`
}
