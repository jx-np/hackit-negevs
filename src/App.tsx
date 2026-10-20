import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AnimatePresence, motion } from 'framer-motion';
import {
  BrowserRouter,
  Route,
  Routes,
  useLocation,
} from 'react-router-dom';
import { Footer } from './components/layout/Footer';
import { Navbar } from './components/layout/Navbar';
import { AppearanceProvider } from './context/AppearanceContext';
import { AuthProvider } from './context/AuthContext';
import { SavedFeedsProvider } from './context/SavedFeedsContext';
import { AuthPage } from './routes/AuthPage';
import { CreditsPage } from './routes/CreditsPage';
import { ForumPage } from './routes/ForumPage';
import { HelpPage } from './routes/HelpPage';
import { LandingPage } from './routes/LandingPage';
import { MyPostsPage } from './routes/MyPostsPage';
import { NotFoundPage } from './routes/NotFoundPage';
import { NumberCheckPage } from './routes/NumberCheckPage';
import { PostDetailPage } from './routes/PostDetailPage';
import { ReportPage } from './routes/ReportPage';
import { ReportUserPage } from './routes/ReportUserPage';
import { RulesPage } from './routes/RulesPage';
import { StaySafePage } from './routes/StaySafePage';
import { VerifiedDatabasePage } from './routes/VerifiedDatabasePage';
import { AdminCommentsPage } from './routes/admin/AdminCommentsPage';
import { AdminOverviewPage } from './routes/admin/AdminOverviewPage';
import { AdminPage } from './routes/admin/AdminPage';
import { AdminPostsPage } from './routes/admin/AdminPostsPage';
import { AdminReportsPage } from './routes/admin/AdminReportsPage';
import { AdminUsersPage } from './routes/admin/AdminUsersPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

function AnimatedRoutes() {
  const location = useLocation();
  return (
    <AnimatePresence mode="wait">
      <motion.main
        key={location.pathname}
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -8 }}
        transition={{ duration: 0.3, ease: 'easeOut' }}
      >
        <Routes location={location}>
          <Route path="/" element={<LandingPage />} />
          <Route path="/forum" element={<ForumPage />} />
          <Route path="/forum/:id" element={<PostDetailPage />} />
          <Route path="/report" element={<ReportPage />} />
          <Route path="/check" element={<NumberCheckPage />} />
          <Route path="/help" element={<HelpPage />} />
          <Route path="/stay-safe" element={<StaySafePage />} />
          <Route path="/rules" element={<RulesPage />} />
          <Route path="/verified" element={<VerifiedDatabasePage />} />
          <Route path="/report-user" element={<ReportUserPage />} />
          <Route path="/me/posts" element={<MyPostsPage />} />
          <Route path="/admin" element={<AdminPage />}>
            <Route index element={<AdminOverviewPage />} />
            <Route path="reports" element={<AdminReportsPage />} />
            <Route path="posts" element={<AdminPostsPage />} />
            <Route path="comments" element={<AdminCommentsPage />} />
            <Route path="users" element={<AdminUsersPage />} />
          </Route>
          <Route path="/auth" element={<AuthPage />} />
          <Route path="/credits" element={<CreditsPage />} />
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </motion.main>
    </AnimatePresence>
  );
}

export default function App() {
  return (
    <AppearanceProvider>
      <AuthProvider>
        <SavedFeedsProvider>
          <QueryClientProvider client={queryClient}>
            <BrowserRouter>
              <div className="flex min-h-screen flex-col">
                <Navbar />
                <div className="flex-1">
                  <AnimatedRoutes />
                </div>
                <Footer />
              </div>
            </BrowserRouter>
          </QueryClientProvider>
        </SavedFeedsProvider>
      </AuthProvider>
    </AppearanceProvider>
  );
}
