import { UserX } from 'lucide-react';
import { PlaceholderPage } from './PlaceholderPage';

export function ReportUserPage() {
  return (
    <PlaceholderPage
      icon={UserX}
      eyebrow="Community"
      title="Report a User"
      description="Flag an account for abuse, spam, or impersonation."
    />
  );
}
