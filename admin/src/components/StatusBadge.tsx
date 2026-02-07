interface StatusBadgeProps {
  label: string
  color: 'green' | 'yellow' | 'red' | 'gray' | 'blue'
}

// Solid background + contrasting text — matches Flutter's StatusBadge style
// (solid bg, white text, 8px radius)
const colorMap = {
  green: 'bg-success text-white',
  yellow: 'bg-warning text-primary-text',
  red: 'bg-error text-white',
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