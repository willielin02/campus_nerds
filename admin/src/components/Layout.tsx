import { NavLink, Outlet } from 'react-router-dom'
import { getAdminEnv, switchAdminEnv } from '../lib/supabase'

// Low-saturation SVG icons matching Flutter app style
const CalendarIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <rect x="3" y="4" width="18" height="18" rx="2" />
    <line x1="16" y1="2" x2="16" y2="6" />
    <line x1="8" y1="2" x2="8" y2="6" />
    <line x1="3" y1="10" x2="21" y2="10" />
  </svg>
)

const TicketIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M2 9a3 3 0 0 1 0 6v2a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-2a3 3 0 0 1 0-6V7a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2Z" />
    <path d="M13 5v2" />
    <path d="M13 17v2" />
    <path d="M13 11v2" />
  </svg>
)

const CreditCardIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <rect x="1" y="4" width="22" height="16" rx="2" />
    <line x1="1" y1="10" x2="23" y2="10" />
  </svg>
)

const MapPinIcon = () => (
  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
    <circle cx="12" cy="10" r="3" />
  </svg>
)

const navItems = [
  { to: '/events', label: '活動管理', icon: CalendarIcon },
  { to: '/venues', label: '場地管理', icon: MapPinIcon },
  { to: '/tickets', label: '票券調整', icon: TicketIcon },
  { to: '/orders', label: '訂單查看', icon: CreditCardIcon },
]

const currentEnv = getAdminEnv()
const isProd = currentEnv === 'prod'

export default function Layout() {
  const handleEnvSwitch = () => {
    const targetEnv = isProd ? 'dev' : 'prod'
    const label = targetEnv === 'prod' ? 'PROD（正式環境）' : 'DEV（開發環境）'
    if (window.confirm(`確定要切換到 ${label} 嗎？`)) {
      switchAdminEnv(targetEnv)
    }
  }

  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <aside className="w-56 bg-secondary border-r-2 border-tertiary flex flex-col shrink-0">
        <div className="px-5 py-5 border-b-2 border-tertiary">
          <div className="flex items-center gap-2">
            <h1 className="text-base font-semibold text-primary-text">Campus Nerds</h1>
            <button
              onClick={handleEnvSwitch}
              title={`點擊切換到 ${isProd ? 'DEV' : 'PROD'} 環境`}
              className={`text-[11px] font-bold px-2 py-0.5 rounded cursor-pointer transition-opacity hover:opacity-80 ${
                isProd
                  ? 'bg-tertiary-text text-white'
                  : 'bg-emerald-600 text-white'
              }`}
            >
              {isProd ? 'PROD' : 'DEV'}
            </button>
          </div>
          <p className="text-xs text-tertiary-text mt-0.5">Admin Dashboard</p>
        </div>
        <nav className="flex-1 py-3">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              className={({ isActive }) =>
                `flex items-center gap-3 px-5 py-2.5 text-sm transition-colors ${
                  isActive
                    ? 'bg-alternate text-primary-text font-medium'
                    : 'text-secondary-text hover:bg-alternate/50'
                }`
              }
            >
              <item.icon />
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="px-5 py-4 border-t-2 border-tertiary">
          <a
            href="https://campusnerds.app"
            target="_blank"
            rel="noopener noreferrer"
            className="text-xs text-tertiary-text hover:text-secondary-text transition-colors"
          >
            campusnerds.app ↗
          </a>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto p-6">
        <Outlet />
      </main>
    </div>
  )
}