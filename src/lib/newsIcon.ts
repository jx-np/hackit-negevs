/**
 * Map API icon names (snake_case, e.g. "message_square_warning") onto Lucide
 * components. The API only sends names, so unknown icons fall back to a
 * generic warning glyph.
 */
import {
  BadgeAlert,
  Banknote,
  Bitcoin,
  Briefcase,
  Building2,
  CircleAlert,
  CreditCard,
  Gift,
  Globe,
  GraduationCap,
  HeartHandshake,
  Landmark,
  Mail,
  Megaphone,
  MessageSquareWarning,
  Package,
  Phone,
  ShieldAlert,
  Smartphone,
  TriangleAlert,
  UserRoundX,
  Wallet,
  type LucideIcon,
} from 'lucide-react';

const NEWS_ICONS: Record<string, LucideIcon> = {
  badge_alert: BadgeAlert,
  banknote: Banknote,
  bitcoin: Bitcoin,
  briefcase: Briefcase,
  building_2: Building2,
  circle_alert: CircleAlert,
  credit_card: CreditCard,
  gift: Gift,
  globe: Globe,
  graduation_cap: GraduationCap,
  heart_handshake: HeartHandshake,
  landmark: Landmark,
  mail: Mail,
  megaphone: Megaphone,
  message_square_warning: MessageSquareWarning,
  package: Package,
  phone: Phone,
  shield_alert: ShieldAlert,
  smartphone: Smartphone,
  triangle_alert: TriangleAlert,
  user_round_x: UserRoundX,
  wallet: Wallet,
};

/** Normalise "Message-Square Warning" / "messageSquareWarning" → snake_case. */
function normalizeIconName(name: string): string {
  return name
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, '$1_$2')
    .toLowerCase()
    .replace(/[\s-]+/g, '_');
}

export function iconForNews(name: string): LucideIcon {
  return NEWS_ICONS[normalizeIconName(name)] ?? TriangleAlert;
}
