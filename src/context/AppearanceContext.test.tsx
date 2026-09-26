import { act, renderHook } from '@testing-library/react';
import type { ReactNode } from 'react';
import { beforeEach, describe, expect, it } from 'vitest';
import { AppearanceProvider, useAppearance } from './AppearanceContext';

function wrapper({ children }: { children: ReactNode }) {
  return <AppearanceProvider>{children}</AppearanceProvider>;
}

describe('AppearanceContext', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.className = '';
    document.documentElement.removeAttribute('style');
  });

  it('provides default appearance values', () => {
    const { result } = renderHook(() => useAppearance(), { wrapper });
    expect(result.current.font).toBe('sans');
    expect(result.current.fontSize).toBe('md');
    expect(['light', 'dark']).toContain(result.current.theme);
  });

  it('toggles the theme and applies the dark class to <html>', () => {
    const { result } = renderHook(() => useAppearance(), { wrapper });
    const initial = result.current.theme;

    act(() => result.current.toggleTheme());
    expect(result.current.theme).not.toBe(initial);

    const hasDark = document.documentElement.classList.contains('dark');
    expect(hasDark).toBe(result.current.theme === 'dark');
  });

  it('updates the font and sets the CSS variable', () => {
    const { result } = renderHook(() => useAppearance(), { wrapper });
    act(() => result.current.setFont('mono'));
    expect(result.current.font).toBe('mono');
    expect(
      document.documentElement.style.getPropertyValue('--app-font-family'),
    ).toMatch(/mono/i);
  });

  it('supports readability fonts (Atkinson Hyperlegible / Lexend)', () => {
    const { result } = renderHook(() => useAppearance(), { wrapper });

    act(() => result.current.setFont('atkinson'));
    expect(result.current.font).toBe('atkinson');
    expect(
      document.documentElement.style.getPropertyValue('--app-font-family'),
    ).toMatch(/atkinson/i);

    act(() => result.current.setFont('lexend'));
    expect(result.current.font).toBe('lexend');
    expect(
      document.documentElement.style.getPropertyValue('--app-font-family'),
    ).toMatch(/lexend/i);
  });

  it('updates the font size and sets the scale variable', () => {
    const { result } = renderHook(() => useAppearance(), { wrapper });
    act(() => result.current.setFontSize('lg'));
    expect(result.current.fontSize).toBe('lg');
    expect(
      document.documentElement.style.getPropertyValue('--app-font-scale'),
    ).toBe('1.15');
  });

  it('persists preferences to localStorage', () => {
    const { result } = renderHook(() => useAppearance(), { wrapper });
    act(() => result.current.setFont('serif'));

    const stored = JSON.parse(localStorage.getItem('forum-appearance') ?? '{}');
    expect(stored.font).toBe('serif');
  });

  it('restores persisted preferences on mount', () => {
    localStorage.setItem(
      'forum-appearance',
      JSON.stringify({ theme: 'dark', font: 'serif', fontSize: 'lg' }),
    );
    const { result } = renderHook(() => useAppearance(), { wrapper });
    expect(result.current.theme).toBe('dark');
    expect(result.current.font).toBe('serif');
    expect(result.current.fontSize).toBe('lg');
  });
});
