/**
 * Static Singapore-focused fallback for the "Get help now" page.
 *
 * The live backend currently returns empty `/guidance` and
 * `/guidance/resources` catalogs. These official steps and resources are
 * shown when the API has nothing so the Help page is always actionable.
 */
import type { GuidanceItem, Resource } from '../types';

export const FALLBACK_GUIDANCE: GuidanceItem[] = [
  {
    id: 'fallback-guidance-stop',
    scenario: 'general',
    urgency: 'emergency',
    title: 'Stop all contact and payments immediately',
    body: 'Do not send any more money or share further details. Hang up on the caller or stop replying. Scammers rely on urgency and pressure, so breaking contact is the single most important first step.',
    resources: ['scamshield-helpline'],
  },
  {
    id: 'fallback-guidance-bank',
    scenario: 'bank_transfer',
    urgency: 'urgent',
    title: 'Call your bank to freeze accounts and cards',
    body: 'If you shared banking details or transferred money, contact your bank right away to freeze the account, block cards, and attempt to recall transfers. Most Singapore banks have 24/7 anti-scam hotlines.',
    resources: ['bank-hotlines'],
  },
  {
    id: 'fallback-guidance-report',
    scenario: 'general',
    urgency: 'urgent',
    title: 'Report to the Police and the Anti-Scam Centre',
    body: 'File a report so the authorities can trace funds and warn others. Call the Police Hotline at 1800 255 0000, dial 999 if it is an emergency, or report online at the Singapore Police e-services portal.',
    resources: ['spf-iwitness', 'anti-scam-helpline'],
  },
  {
    id: 'fallback-guidance-secure',
    scenario: 'account_takeover',
    urgency: 'normal',
    title: 'Secure your accounts and devices',
    body: 'Change passwords for any affected accounts and enable two-factor authentication. Review Singpass activity, remove unknown devices, and run a scan if you installed any app the scammer asked for.',
    resources: ['scamshield'],
  },
  {
    id: 'fallback-guidance-share',
    scenario: 'general',
    urgency: 'normal',
    title: 'Warn others by sharing what happened',
    body: 'Report the number, message, or listing to ScamShield and tell friends and family. Posting a redacted report here helps the community spot the same scam faster.',
    resources: ['scamshield'],
  },
];

export const FALLBACK_RESOURCES: Resource[] = [
  {
    id: 'fallback-resource-anti-scam-helpline',
    slug: 'anti-scam-helpline',
    countryCode: 'SG',
    url: 'https://www.police.gov.sg/advisories/crime/scams',
    contactInstructions: 'Call 1800 722 6688 (Anti-Scam Helpline), daily 9am–5pm.',
    name: 'Anti-Scam Helpline (1800 722 6688)',
    description:
      'Speak to the Anti-Scam Centre for advice on what to do if you think you have been scammed or want to verify a suspicious request.',
    verifiedAt: '2024-01-01T00:00:00Z',
    ownerName: 'Singapore Police Force',
  },
  {
    id: 'fallback-resource-police-hotline',
    slug: 'spf-iwitness',
    countryCode: 'SG',
    url: 'https://eservices.police.gov.sg/content/policehubhome/homepage/police-report.html',
    contactInstructions:
      'Call 999 for emergencies or the Police Hotline at 1800 255 0000. File reports online via the SPF e-services portal.',
    name: 'Singapore Police Force — Report a scam',
    description:
      'Make an official police report so funds can be traced and the scam can be investigated.',
    verifiedAt: '2024-01-01T00:00:00Z',
    ownerName: 'Singapore Police Force',
  },
  {
    id: 'fallback-resource-scamshield',
    slug: 'scamshield',
    countryCode: 'SG',
    url: 'https://www.scamshield.gov.sg/',
    contactInstructions:
      'Download the ScamShield app to block scam calls and messages, and report suspicious contacts.',
    name: 'ScamShield',
    description:
      'A national app that filters scam calls and SMSes and lets you report scam numbers and messages to the authorities.',
    verifiedAt: '2024-01-01T00:00:00Z',
    ownerName: 'Open Government Products & NCPC',
  },
  {
    id: 'fallback-resource-scamshield-helpline',
    slug: 'scamshield-helpline',
    countryCode: 'SG',
    url: 'https://www.scamshield.gov.sg/',
    contactInstructions: 'ScamShield Helpline: 1799. Checks whether something is likely a scam.',
    name: 'ScamShield Helpline (1799)',
    description:
      'Not sure if it is a scam? Call 1799 to check a message, call, or offer before you act on it.',
    verifiedAt: '2024-01-01T00:00:00Z',
    ownerName: 'National Crime Prevention Council',
  },
  {
    id: 'fallback-resource-bank-hotlines',
    slug: 'bank-hotlines',
    countryCode: 'SG',
    url: 'https://www.abs.org.sg/consumer-banking/anti-scam-measures',
    contactInstructions:
      'DBS/POSB 1800 339 6963 · OCBC 1800 363 3333 · UOB 1800 222 2121. Report fraud and freeze accounts 24/7.',
    name: 'Bank anti-scam hotlines',
    description:
      'Contact your bank immediately to freeze accounts, block cards, and attempt to recall fraudulent transfers.',
    verifiedAt: '2024-01-01T00:00:00Z',
    ownerName: 'Association of Banks in Singapore',
  },
  {
    id: 'fallback-resource-scamalert',
    slug: 'scamalert',
    countryCode: 'SG',
    url: 'https://www.scamalert.sg/',
    contactInstructions: 'Browse scam stories and advisories, or use the "I can help" resources.',
    name: 'ScamAlert (NCPC)',
    description:
      'The National Crime Prevention Council portal with the latest scam types, prevention tips, and recovery guidance.',
    verifiedAt: '2024-01-01T00:00:00Z',
    ownerName: 'National Crime Prevention Council',
  },
];
