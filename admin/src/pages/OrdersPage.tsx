import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import type { Order, EcpayPayment, OrderStatus } from '../types/database'
import { ORDER_STATUS_LABELS } from '../types/database'
import StatusBadge, { orderStatusColor } from '../components/StatusBadge'
import { formatDateTime } from '../lib/date'

export default function OrdersPage() {
  const [orders, setOrders] = useState<(Order & { users: { nickname: string | null } | null })[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState<OrderStatus | ''>('')
  const [expandedOrder, setExpandedOrder] = useState<string | null>(null)
  const [payments, setPayments] = useState<Record<string, EcpayPayment[]>>({})

  useEffect(() => {
    loadOrders()
  }, [statusFilter])

  async function loadOrders() {
    setLoading(true)
    let query = supabase
      .from('orders')
      .select('*, users(nickname)')
      .order('created_at', { ascending: false })
      .limit(100)

    if (statusFilter) {
      query = query.eq('status', statusFilter)
    }

    const { data } = await query
    if (data) {
      setOrders(data as unknown as (Order & { users: { nickname: string | null } | null })[])
    }
    setLoading(false)
  }

  async function toggleExpand(orderId: string) {
    if (expandedOrder === orderId) {
      setExpandedOrder(null)
      return
    }

    setExpandedOrder(orderId)

    if (!payments[orderId]) {
      const { data } = await supabase
        .from('ecpay_payments')
        .select('*')
        .eq('order_id', orderId)
        .order('created_at', { ascending: false })
      if (data) {
        setPayments((prev) => ({ ...prev, [orderId]: data as unknown as EcpayPayment[] }))
      }
    }
  }

  return (
    <div>
      <h2 className="text-2xl font-semibold mb-6">訂單查看</h2>

      {/* Filters */}
      <div className="mb-4">
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value as OrderStatus | '')}
          className="border-2 border-tertiary rounded-[var(--radius-app)] px-3 py-2 text-sm bg-secondary"
        >
          <option value="">全部狀態</option>
          {Object.entries(ORDER_STATUS_LABELS).map(([key, label]) => (
            <option key={key} value={key}>{label}</option>
          ))}
        </select>
      </div>

      {/* Orders table */}
      <div className="bg-secondary border-2 border-tertiary rounded-[var(--radius-app)] overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-tertiary bg-alternate/50">
              <th className="text-left px-4 py-3 font-medium text-secondary-text">訂單編號</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">用戶</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">商品</th>
              <th className="text-right px-4 py-3 font-medium text-secondary-text">金額</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">狀態</th>
              <th className="text-left px-4 py-3 font-medium text-secondary-text">建立時間</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-tertiary-text">載入中...</td></tr>
            ) : orders.length === 0 ? (
              <tr><td colSpan={6} className="px-4 py-8 text-center text-tertiary-text">暫無訂單</td></tr>
            ) : (
              orders.map((order) => (
                <>
                  <tr
                    key={order.id}
                    className="border-b border-tertiary hover:bg-alternate/30 transition-colors cursor-pointer"
                    onClick={() => toggleExpand(order.id)}
                  >
                    <td className="px-4 py-3 font-mono text-xs">{order.merchant_trade_no}</td>
                    <td className="px-4 py-3">{order.users?.nickname || '(未設定)'}</td>
                    <td className="px-4 py-3 text-secondary-text">{order.title_snapshot}</td>
                    <td className="px-4 py-3 text-right">NT$ {order.total_amount}</td>
                    <td className="px-4 py-3">
                      <StatusBadge label={ORDER_STATUS_LABELS[order.status]} color={orderStatusColor(order.status)} />
                    </td>
                    <td className="px-4 py-3 text-tertiary-text text-xs">
                      {formatDateTime(order.created_at)}
                    </td>
                  </tr>
                  {expandedOrder === order.id && (
                    <tr key={`${order.id}-detail`}>
                      <td colSpan={6} className="bg-alternate/20 px-4 py-3 border-b border-tertiary">
                        <div className="text-xs">
                          <p className="font-medium text-secondary-text mb-2">ECPay 交易紀錄</p>
                          {!payments[order.id] ? (
                            <p className="text-tertiary-text">載入中...</p>
                          ) : payments[order.id].length === 0 ? (
                            <p className="text-tertiary-text">尚無交易紀錄</p>
                          ) : (
                            <div className="space-y-2">
                              {payments[order.id].map((p) => (
                                <div key={p.id} className="flex items-center gap-4 bg-secondary rounded-lg px-3 py-2">
                                  <span className="text-tertiary-text">TradeNo: {p.trade_no || '-'}</span>
                                  <span className={p.rtn_code === 1 ? 'text-secondary-text' : 'text-tertiary-text'}>
                                    Code: {p.rtn_code ?? '-'}
                                  </span>
                                  <span className="text-secondary-text">{p.rtn_msg || '-'}</span>
                                  <span className="text-tertiary-text">NT$ {p.trade_amt ?? '-'}</span>
                                  <span className="text-tertiary-text ml-auto">
                                    {formatDateTime(p.created_at)}
                                  </span>
                                </div>
                              ))}
                            </div>
                          )}
                          {order.paid_at && (
                            <p className="text-secondary-text mt-2">
                              付款時間：{formatDateTime(order.paid_at)}
                            </p>
                          )}
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
