import { useMutation } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { lookupNumber } from '../api/numbers';
import type { NumberCheckResult } from '../types';

/**
 * Manages a single phone-number trust-score lookup.
 *
 * The backend exposes lookup via GET trust-score. Reporting a number is a
 * mobile-first flow (POST /detection/phone-number/report) that is not surfaced
 * on the web client, so this hook only performs lookups.
 */
export function useNumberCheck() {
  const [result, setResult] = useState<NumberCheckResult | null>(null);
  const [queried, setQueried] = useState<string | null>(null);

  const lookup = useMutation({
    mutationFn: (input: string) => lookupNumber(input),
    onSuccess: (data, input) => {
      setResult(data);
      setQueried(input);
    },
  });

  const reset = useCallback(() => {
    setResult(null);
    setQueried(null);
    lookup.reset();
  }, [lookup]);

  return {
    result,
    queried,
    check: (input: string) => lookup.mutate(input),
    isChecking: lookup.isPending,
    checkError: lookup.error as Error | null,
    reset,
  };
}
