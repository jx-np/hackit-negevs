/**
 * The service's AI helper, as the frontend refers to it.
 *
 * The bot's wire identity is server-driven (`is_bot`, `author_label`), so the
 * UI only needs these strings for the trigger hint and the "thinking" label.
 * The SSE event names themselves are unchanged (`grok_thinking`, …).
 */

/** Mention that asks the bot for an answer. */
export const BOT_MENTION = '@help';

/** Display name of the bot, matching the backend's `author_label`. */
export const BOT_LABEL = 'NegevAI';

/** Shown on a comment while the bot is composing its reply. */
export const BOT_THINKING_LABEL = `${BOT_LABEL} is thinking…`;
