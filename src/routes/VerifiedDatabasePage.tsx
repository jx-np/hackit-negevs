import { BadgeCheck } from 'lucide-react';
import { PlaceholderPage } from './PlaceholderPage';

export function VerifiedDatabasePage() {
  return (
    <PlaceholderPage
      icon={BadgeCheck}
      eyebrow="Community"
      title="Verified Scam Database"
      description="A searchable record of confirmed scams, reviewed by moderators."
    />
  );
}
