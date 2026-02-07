import { NavLink, Outlet } from 'react-router-dom'

const navItems = [
  { to: '/events', label: '活動管理', icon: '📅' },
  { to: '/tickets', label: '票券調整', icon: '🎫' },
  { to: '/orders', label: '訂單查看', icon: '💳' },
]

export default function Layout() {
  return (
    <div className="flex h-screen">
      {/* Sidebar */}
      <aside className="w-56 bg-secondary border-r border-tertiary flex flex-col shrink-0">
        <div className="px-5 py-5 border-b border-tertiary">
          <h1 className="text-base font-bold text-primary-text">Campus Nerds</h1>
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
              <span>{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="px-5 py-4 border-t border-tertiary">
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
