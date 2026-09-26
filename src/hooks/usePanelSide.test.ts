import { act, renderHook } from '@testing-library/react';
import { beforeEach, describe, expect, it } from 'vitest';
import { usePanelSide } from './usePanelSide';

describe('usePanelSide', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('defaults to the right side', () => {
    const { result } = renderHook(() => usePanelSide());
    expect(result.current.side).toBe('right');
  });

  it('updates and persists the side', () => {
    const { result } = renderHook(() => usePanelSide());
    act(() => result.current.setSide('left'));
    expect(result.current.side).toBe('left');
    expect(localStorage.getItem('forum-tag-panel-side')).toBe('left');
  });

  it('restores a persisted side on mount', () => {
    localStorage.setItem('forum-tag-panel-side', 'left');
    const { result } = renderHook(() => usePanelSide());
    expect(result.current.side).toBe('left');
  });
});
