import { useMutation } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { lookupNumber } from '../api/numbers';
import type { NumberCheckResult } from '../types';

/**
 * Manages a single phone-number trust-score lookup.
 *
 * The backend exposes lookup only (GET trust-score); there is no
 * phone-number report/submit endpoint, so reporting has been removed.
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
