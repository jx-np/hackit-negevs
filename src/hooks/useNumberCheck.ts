import { useMutation } from '@tanstack/react-query';
import { useCallback, useState } from 'react';
import { hasReported, lookupNumber, reportNumber } from '../api/numbers';
import { useAuth } from '../context/AuthContext';
import type { NumberCheckResult, NumberReportKind } from '../types';

/**
 * Manages a single number lookup and (login-gated) reporting.
 * Keeps the most recent result so the UI can render it and update it after a
 * report without a second fetch. Enforces "one report per number per account".
 */
export function useNumberCheck() {
  const { user } = useAuth();
  const [result, setResult] = useState<NumberCheckResult | null>(null);
  const [queried, setQueried] = useState<string | null>(null);
  // Tracks whether the current account has reported the current number,
  // so the UI can flip to an "already reported" state immediately.
  const [reported, setReported] = useState(false);

  const lookup = useMutation({
    mutationFn: (input: string) => lookupNumber(input),
    onSuccess: (data, input) => {
      setResult(data);
      setQueried(input);
      setReported(user ? hasReported(user.id, input) : false);
    },
  });

  const report = useMutation({
    mutationFn: ({ input, kind }: { input: string; kind: NumberReportKind }) =>
      reportNumber(input, kind, user?.id),
    onSuccess: (data) => {
      setResult(data);
      setReported(true);
    },
  });

  const reset = useCallback(() => {
    setResult(null);
    setQueried(null);
    setReported(false);
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
    reportError: report.error as Error | null,
    /** True once the current account has reported the current number. */
    alreadyReported: reported,
    reset,
  };
}
