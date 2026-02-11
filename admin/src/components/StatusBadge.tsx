interface StatusBadgeProps {
  label: string
  color: 'green' | 'yellow' | 'red' | 'gray' | 'blue'
}

// Low-saturation badge palette matching the app's gray theme.
// Differentiation via shade: dark gray (active), light gray (pending), medium gray (inactive).
const colorMap = {
  green: 'bg-secondary-text text-white',
  yellow: 'bg-tertiary text-secondary-text',
  red: 'bg-tertiary-text text-white',
  gray: 'bg-tertiary-text text-white',
  blue: 'bg-secondary-text text-white',
}

export default function StatusBadge({ label, color }: StatusBadgeProps) {
  return (
    <span className={`inline-block px-2 py-0.5 rounded-lg text-xs font-medium ${colorMap[color]}`}>
      {label}
    </span>
  )
}

export function eventStatusColor(status: string): StatusBadgeProps['color'] {
  switch (status) {
    case 'draft': return 'gray'
    case 'scheduled': return 'blue'
    case 'notified': return 'green'
    case 'completed': return 'green'
    case 'cancelled': return 'red'
    default: return 'gray'
  }
}

export function groupStatusColor(status: string): StatusBadgeProps['color'] {
  switch (status) {
    case 'draft': return 'yellow'
    case 'scheduled': return 'green'
    case 'cancelled': return 'red'
    default: return 'gray'
  }
}

export function orderStatusColor(status: string): StatusBadgeProps['color'] {
  switch (status) {
    case 'pending': return 'yellow'
    case 'paid': return 'green'
    case 'cancelled': return 'gray'
    case 'refunded': return 'red'
    default: return 'gray'
  }
}