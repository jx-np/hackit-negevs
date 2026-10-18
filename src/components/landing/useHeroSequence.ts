import { useEffect, useState } from 'react';
import { useReducedMotion } from 'framer-motion';

export type HeroPhase = 'lock' | 'incoming' | 'scanning' | 'flagged' | 'app';

const SEQUENCE: ReadonlyArray<readonly [HeroPhase, number]> = [
  ['lock', 1600],
  ['incoming', 1800],
  ['scanning', 1800],
  ['flagged', 2400],
  ['app', 6000],
];

/**
 * Drives the hero story: lock screen, scam SMS arrives, ScamWatch scans and
 * flags it, then the app view returns. Loops forever. With reduced motion it
 * stays on the final app view.
 */
export function useHeroSequence(): HeroPhase {
  const reduceMotion = useReducedMotion();
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (reduceMotion) return;
    const timer = setTimeout(
      () => setIndex((i) => (i + 1) % SEQUENCE.length),
      SEQUENCE[index][1],
    );
    return () => clearTimeout(timer);
  }, [index, reduceMotion]);

  return reduceMotion ? 'app' : SEQUENCE[index][0];
}
