import { useMutation } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { lookupNumber, reportNumber } from '../api/numbers';
import type { NumberCheckResult, NumberReportKind } from '../types';

/**
 * Manages a single number lookup and (login-gated) reporting.
 * Keeps the most recent result so the UI can render it and update it after a
 * report without a second fetch.
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

  const report = useMutation({
    mutationFn: ({ input, kind }: { input: string; kind: NumberReportKind }) =>
      reportNumber(input, kind),
    onSuccess: (data) => setResult(data),
  });

  const reset = useCallback(() => {
    setResult(null);
    setQueried(null);
    lookup.reset();
    report.reset();
  }, [lookup, report]);

  return {
    result,
    queried,
    // lookup
    check: (input: string) => lookup.mutate(input),
    isChecking: lookup.isPending,
    checkError: lookup.error as Error | null,
    // report
    submitReport: (input: string, kind: NumberReportKind) =>
      report.mutate({ input, kind }),
    isReporting: report.isPending,
    reportedKind: report.variables?.kind ?? null,
    reset,
  };
}
