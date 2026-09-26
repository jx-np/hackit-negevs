import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { renderWithProviders } from '../../test/utils';
import { SettingsPanel } from './SettingsPanel';

async function openPanel() {
  const user = userEvent.setup();
  renderWithProviders(<SettingsPanel />);
  await user.click(
    screen.getByRole('button', { name: /open appearance settings/i }),
  );
  return user;
}

describe('SettingsPanel', () => {
  beforeEach(() => {
    localStorage.clear();
    document.documentElement.className = '';
    document.documentElement.removeAttribute('style');
  });

  it('opens the drawer with theme, size and font controls', async () => {
    await openPanel();
    expect(screen.getByText('Appearance')).toBeInTheDocument();
    expect(screen.getByLabelText(/decrease text size/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/increase text size/i)).toBeInTheDocument();
  });

  it('increases and decreases text size with the +/- buttons', async () => {
    const user = await openPanel();
    const dec = screen.getByLabelText(/decrease text size/i);
    const inc = screen.getByLabelText(/increase text size/i);

    // Default is medium: minus enabled, plus enabled.
    expect(dec).toBeEnabled();
    expect(inc).toBeEnabled();

    // Increase to large -> plus disabled, scale variable = 1.15
    await user.click(inc);
    expect(inc).toBeDisabled();
    expect(
      document.documentElement.style.getPropertyValue('--app-font-scale'),
    ).toBe('1.15');

    // Decrease twice to small -> minus disabled, scale = 0.9
    await user.click(dec);
    await user.click(dec);
    expect(dec).toBeDisabled();
    expect(
      document.documentElement.style.getPropertyValue('--app-font-scale'),
    ).toBe('0.9');
  });

  it('offers readability fonts and applies one when chosen', async () => {
    const user = await openPanel();
    const atkinson = screen.getByRole('button', {
      name: /Atkinson Hyperlegible/i,
    });
    expect(atkinson).toBeInTheDocument();

    await user.click(atkinson);
    expect(atkinson).toHaveAttribute('aria-pressed', 'true');
    expect(
      document.documentElement.style.getPropertyValue('--app-font-family'),
    ).toMatch(/atkinson/i);
  });
});
