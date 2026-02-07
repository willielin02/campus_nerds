interface StatusBadgeProps {
  label: string
  color: 'green' | 'yellow' | 'red' | 'gray' | 'blue'
}

const colorMap = {
  green: 'bg-success/15 text-success',
  yellow: 'bg-warning/25 text-amber-700',
  red: 'bg-error/15 text-error',
  gray: 'bg-alternate text-secondary-text',
  blue: 'bg-blue-50 text-blue-700',
}

export default function StatusBadge({ label, color }: StatusBadgeProps) {
  return (
    <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-medium ${colorMap[color]}`}>
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
