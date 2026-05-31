type Listener = () => void;

/// Transient in-memory mirror of the native file store. Native (Swift) owns the
/// real files on disk; it pushes the authoritative set here via `setFiles` and
/// asks for a re-evaluation via `reload`. The JS side never persists anything.
export class ProjectStore {
  private files: Record<string, string> = {};
  private _version = 0;
  private listeners: Set<Listener> = new Set();

  get version() {
    return this._version;
  }

  /// Replace the in-memory file set with the authoritative set from native.
  setFiles(files: Record<string, string>) {
    this.files = {...files};
    this.bump();
  }

  /// Force a re-evaluation of the preview (native asked for a reload).
  reload() {
    this.bump();
  }

  list(): string[] {
    return Object.keys(this.files).sort();
  }

  read(path: string): string | undefined {
    return this.files[path];
  }

  subscribe(listener: Listener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  getSnapshot = () => this._version;

  private bump() {
    this._version++;
    this.listeners.forEach(fn => fn());
  }
}

export const projectStore = new ProjectStore();
