export type EventCategory = 'focused_study' | 'english_games'
export type EventStatus = 'draft' | 'scheduled' | 'notified' | 'cancelled' | 'completed'
export type EventTimeSlot = 'morning' | 'afternoon' | 'evening'
export type GroupStatus = 'draft' | 'scheduled' | 'cancelled'
export type BookingStatus = 'active' | 'cancelled' | 'unmatched' | 'event_cancelled'
export type OrderStatus = 'pending' | 'paid' | 'cancelled' | 'refunded'
export type Gender = 'male' | 'female'
export type TicketType = 'study' | 'games'
export type EventLocationDetail =
  | 'ntu_main_library_reading_area'
  | 'nycu_haoran_library_reading_area'
  | 'nycu_yangming_campus_library_reading_area'
  | 'nthu_main_library_reading_area'
  | 'ncku_main_library_reading_area'
  | 'nccu_daxian_library_reading_area'
  | 'ncu_main_library_reading_area'
  | 'nsysu_library_reading_area'
  | 'nchu_main_library_reading_area'
  | 'ccu_library_reading_area'
  | 'ntnu_main_library_reading_area'
  | 'ntpu_library_reading_area'
  | 'ntust_library_reading_area'
  | 'ntut_library_reading_area'
  | 'library_or_cafe'
  | 'boardgame_or_escape_room'
  | 'boardgame'
export type VenueType = 'university_library' | 'public_library' | 'cafe' | 'boardgame' | 'escape'
export type TicketLedgerReason = 'purchase_credit' | 'booking_debit' | 'booking_refund' | 'admin_adjust'

export interface Event {
  id: string
  category: EventCategory
  event_date: string
  time_slot: EventTimeSlot
  status: EventStatus
  city_id: string
  university_id: string | null
  location_detail: EventLocationDetail
  default_group_size: number
  signup_open_at: string
  signup_deadline_at: string
  notify_deadline_at: string | null
  created_at: string
  city?: { name: string }
}

export interface Group {
  id: string
  event_id: string
  venue_id: string | null
  max_size: number
  status: GroupStatus
  chat_open_at: string | null
  created_at: string
  venue?: Venue | null
}

export interface GroupMemberRow {
  id: string
  group_id: string
  booking_id: string
  bookings: {
    user_id: string
    users: {
      id: string
      nickname: string | null
      gender: Gender | null
    }
  }
}

export interface Venue {
  id: string
  name: string
  address: string
  google_map_url: string
  city_id: string
  category: EventCategory
  type: VenueType
  university_id: string | null
  start_at: string | null
  is_active: boolean
  created_at: string
  city?: { name: string }
  university?: { name: string } | null
}

export interface Order {
  id: string
  user_id: string
  merchant_trade_no: string
  title_snapshot: string
  ticket_type_snapshot: TicketType
  pack_size_snapshot: number
  price_snapshot_twd: number
  total_amount: number
  status: OrderStatus
  created_at: string
  paid_at: string | null
  users?: { nickname: string | null }
}

export interface EcpayPayment {
  id: string
  order_id: string
  trade_no: string | null
  rtn_code: number | null
  rtn_msg: string | null
  trade_amt: number | null
  paid_at: string | null
  created_at: string
}

export interface UserProfile {
  id: string
  nickname: string | null
  gender: Gender | null
  age: number | null
  school_email: string | null
  university_name: string | null
  university_code: string | null
  created_at: string
}

export interface UserWithBooking extends UserProfile {
  lastBookingAt: string | null
}

export interface TicketBalance {
  user_id: string
  study_balance: number
  games_balance: number
}

export interface TicketLedgerEntry {
  id: string
  user_id: string
  delta_study: number
  delta_games: number
  reason: TicketLedgerReason
  created_at: string
  order_id: string | null
  booking_id: string | null
}

export interface City {
  id: string
  name: string
  slug: string
}

export const TIME_SLOT_LABELS: Record<EventTimeSlot, string> = {
  morning: '上午',
  afternoon: '下午',
  evening: '晚上',
}

export const CATEGORY_LABELS: Record<EventCategory, string> = {
  focused_study: '專注讀書',
  english_games: '英文遊戲',
}

export const EVENT_STATUS_LABELS: Record<EventStatus, string> = {
  draft: '草稿',
  scheduled: '已排程',
  notified: '已通知',
  cancelled: '已取消',
  completed: '已完成',
}

export const GROUP_STATUS_LABELS: Record<GroupStatus, string> = {
  draft: '草稿',
  scheduled: '已鎖定',
  cancelled: '已取消',
}

export const ORDER_STATUS_LABELS: Record<OrderStatus, string> = {
  pending: '待付款',
  paid: '已付款',
  cancelled: '已取消',
  refunded: '已退款',
}

export const LOCATION_DETAIL_LABELS: Record<EventLocationDetail, string> = {
  ntu_main_library_reading_area: '臺大總圖書館 閱覽區',
  nycu_haoran_library_reading_area: '陽明交大浩然圖書館 閱覽區',
  nycu_yangming_campus_library_reading_area: '陽明交大陽明校區圖書館 閱覽區',
  nthu_main_library_reading_area: '清華大學總圖書館 閱覽區',
  ncku_main_library_reading_area: '成功大學總圖書館 閱覽區',
  nccu_daxian_library_reading_area: '政治大學達賢圖書館 閱覽區',
  ncu_main_library_reading_area: '中央大學總圖書館 閱覽區',
  nsysu_library_reading_area: '中山大學圖書館 閱覽區',
  nchu_main_library_reading_area: '中興大學總圖書館 閱覽區',
  ccu_library_reading_area: '中正大學圖書館 閱覽區',
  ntnu_main_library_reading_area: '臺灣師範大學總圖書館 閱覽區',
  ntpu_library_reading_area: '臺北大學圖書館 閱覽區',
  ntust_library_reading_area: '臺灣科技大學圖書館 閱覽區',
  ntut_library_reading_area: '臺北科技大學圖書館 閱覽區',
  library_or_cafe: '圖書館/ 咖啡廳',
  boardgame_or_escape_room: '桌遊店/ 密室逃脫',
  boardgame: '桌遊店',
}

export const STUDY_LOCATION_DETAILS: EventLocationDetail[] = [
  'library_or_cafe',
  'ntu_main_library_reading_area',
  'nycu_haoran_library_reading_area',
  'nycu_yangming_campus_library_reading_area',
  'nthu_main_library_reading_area',
  'ncku_main_library_reading_area',
  'nccu_daxian_library_reading_area',
  'ncu_main_library_reading_area',
  'nsysu_library_reading_area',
  'nchu_main_library_reading_area',
  'ccu_library_reading_area',
  'ntnu_main_library_reading_area',
  'ntpu_library_reading_area',
  'ntust_library_reading_area',
  'ntut_library_reading_area',
]

export const GAMES_LOCATION_DETAILS: EventLocationDetail[] = [
  'boardgame_or_escape_room',
  'boardgame',
]

export const VENUE_TYPE_LABELS: Record<VenueType, string> = {
  university_library: '大學圖書館',
  public_library: '公共圖書館',
  cafe: '咖啡廳',
  boardgame: '桌遊店',
  escape: '密室逃脫',
}

export const REASON_LABELS: Record<TicketLedgerReason, string> = {
  purchase_credit: '購買',
  booking_debit: '報名扣除',
  booking_refund: '取消退還',
  admin_adjust: '管理員調整',
}
