import { ImagePlus, Loader2, X } from 'lucide-react';
import { useCallback, useRef, useState } from 'react';
import { uploadMedia, validateMediaFile } from '../../api/media';

interface MediaPickerProps {
  /** Current uploaded image URL (null when none). */
  value: string | null;
  onChange: (url: string | null) => void;
}

/**
 * Image picker: click or drag-and-drop a file, preview it, and "upload" it
 * via the scaffolded uploadMedia() (which returns a local object URL in mock
 * mode). Also accepts a pasted URL as a fallback.
 */
export function MediaPicker({ value, onChange }: MediaPickerProps) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragging, setDragging] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [fileName, setFileName] = useState<string | null>(null);

  const handleFile = useCallback(
    async (file: File) => {
      setError(null);
      const validationError = validateMediaFile(file);
      if (validationError) {
        setError(validationError);
        return;
      }
      setUploading(true);
      try {
        const media = await uploadMedia(file);
        onChange(media.url);
        setFileName(media.name);
      } catch (e) {
        setError((e as Error).message || 'Upload failed.');
      } finally {
        setUploading(false);
      }
    },
    [onChange],
  );

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragging(false);
    const file = e.dataTransfer.files?.[0];
    if (file) handleFile(file);
  };

  const clear = () => {
    onChange(null);
    setFileName(null);
    setError(null);
    if (inputRef.current) inputRef.current.value = '';
  };

  return (
    <div>
      {value ? (
        <div className="relative border border-ink-200 dark:border-ink-700">
          <img
            src={value}
            alt="Selected evidence preview"
            className="max-h-72 w-full bg-ink-100 object-contain dark:bg-ink-800"
          />
          <button
            type="button"
            onClick={clear}
            aria-label="Remove image"
            className="absolute right-2 top-2 grid h-8 w-8 place-items-center bg-ink-900/80 text-white transition hover:bg-ink-900"
          >
            <X size={16} />
          </button>
          {fileName && (
            <p className="border-t border-ink-200 px-3 py-1.5 font-mono text-xs text-ink-400 dark:border-ink-700">
              {fileName}
            </p>
          )}
        </div>
      ) : (
        <button
          type="button"
          onClick={() => inputRef.current?.click()}
          onDragOver={(e) => {
            e.preventDefault();
            setDragging(true);
          }}
          onDragLeave={() => setDragging(false)}
          onDrop={onDrop}
          className={`flex w-full flex-col items-center justify-center gap-2 border border-dashed px-6 py-10 text-center transition ${
            dragging
              ? 'border-safe-500 bg-safe-50 dark:bg-safe-500/10'
              : 'border-ink-300 hover:border-ink-400 dark:border-ink-700 dark:hover:border-ink-500'
          }`}
        >
          {uploading ? (
            <>
              <Loader2 size={26} className="animate-spin text-safe-600" />
              <span className="font-mono text-sm text-ink-500">Uploading…</span>
            </>
          ) : (
            <>
              <ImagePlus size={26} className="text-ink-400" />
              <span className="text-base font-medium text-ink-700 dark:text-ink-200">
                Click to choose an image, or drag & drop
              </span>
              <span className="font-mono text-xs text-ink-400">
                PNG or JPG, up to 5 MB
              </span>
            </>
          )}
        </button>
      )}

      <input
        ref={inputRef}
        type="file"
        accept="image/*"
        className="sr-only"
        aria-label="Upload evidence image"
        onChange={(e) => {
          const file = e.target.files?.[0];
          if (file) handleFile(file);
        }}
      />

      {error && (
        <p className="mt-1 font-mono text-xs text-risk-600 dark:text-risk-500">
          {error}
        </p>
      )}
    </div>
  );
}
