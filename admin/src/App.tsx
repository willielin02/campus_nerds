import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import EventsPage from './pages/EventsPage'
import EventDetailPage from './pages/EventDetailPage'
import TicketsPage from './pages/TicketsPage'
import OrdersPage from './pages/OrdersPage'
import VenuesPage from './pages/VenuesPage'
import UsersPage from './pages/UsersPage'
import SupportTicketsPage from './pages/SupportTicketsPage'
import StudentIdReviewPage from './pages/StudentIdReviewPage'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route path="/" element={<Navigate to="/events" replace />} />
          <Route path="/events" element={<EventsPage />} />
          <Route path="/events/:id" element={<EventDetailPage />} />
          <Route path="/tickets" element={<TicketsPage />} />
          <Route path="/orders" element={<OrdersPage />} />
          <Route path="/venues" element={<VenuesPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="/student-id-review" element={<StudentIdReviewPage />} />
          <Route path="/support" element={<SupportTicketsPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
