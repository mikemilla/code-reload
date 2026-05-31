import React, {useCallback, useMemo, useSyncExternalStore} from 'react';
import {View, Text, StyleSheet, TouchableOpacity, ScrollView} from 'react-native';
import {projectStore} from '../store/ProjectStore';
import {evaluateEntry} from './moduleRegistry';

interface LiveRuntimeProps {
  entryFile?: string;
  /// Report render/eval errors up to native so the editor/agent can react.
  onError?: (message: string) => void;
}

interface ErrorDisplayProps {
  error: Error;
  onRetry: () => void;
}

function ErrorDisplay({error, onRetry}: ErrorDisplayProps) {
  return (
    <View style={styles.errorContainer}>
      <View style={styles.errorHeader}>
        <Text style={styles.errorTitle}>Preview Error</Text>
        <Text style={styles.errorSubtitle}>
          The editor and agent are still usable — fix the code and save.
        </Text>
      </View>
      <ScrollView style={styles.errorBody}>
        <Text style={styles.errorText}>{error.message}</Text>
        {error.stack && (
          <Text style={styles.stackText}>
            {error.stack.split('\n').slice(0, 10).join('\n')}
          </Text>
        )}
      </ScrollView>
      <TouchableOpacity style={styles.resetButton} onPress={onRetry}>
        <Text style={styles.resetButtonText}>Retry</Text>
      </TouchableOpacity>
    </View>
  );
}

export default function LiveRuntime({
  entryFile = 'index',
  onError,
}: LiveRuntimeProps) {
  const version = useSyncExternalStore(
    projectStore.subscribe.bind(projectStore),
    projectStore.getSnapshot,
  );

  const handleRetry = useCallback(() => {
    projectStore.reload();
  }, []);

  const result = useMemo(() => {
    try {
      const Component = evaluateEntry(entryFile);
      return {Component, error: null};
    } catch (e: any) {
      const error = e as Error;
      onError?.(error.message);
      return {Component: null, error};
    }
  }, [version, entryFile, onError]);

  if (result.error) {
    return <ErrorDisplay error={result.error} onRetry={handleRetry} />;
  }

  if (!result.Component) {
    return (
      <View style={styles.loading}>
        <Text style={styles.loadingText}>Loading...</Text>
      </View>
    );
  }

  return (
    <ErrorBoundary onRetry={handleRetry} onError={onError}>
      <result.Component />
    </ErrorBoundary>
  );
}

interface EBProps {
  onRetry: () => void;
  onError?: (message: string) => void;
  children: React.ReactNode;
}

interface EBState {
  error: Error | null;
}

class ErrorBoundary extends React.Component<EBProps, EBState> {
  state: EBState = {error: null};

  static getDerivedStateFromError(error: Error) {
    return {error};
  }

  componentDidCatch(error: Error) {
    this.props.onError?.(error.message);
  }

  componentDidUpdate(prevProps: EBProps) {
    if (prevProps.children !== this.props.children && this.state.error) {
      this.setState({error: null});
    }
  }

  render() {
    if (this.state.error) {
      return (
        <ErrorDisplay error={this.state.error} onRetry={this.props.onRetry} />
      );
    }
    return this.props.children;
  }
}

const styles = StyleSheet.create({
  errorContainer: {
    flex: 1,
    backgroundColor: '#1a1a2e',
  },
  errorHeader: {
    paddingTop: 60,
    paddingBottom: 16,
    paddingHorizontal: 20,
    backgroundColor: '#e74c3c',
  },
  errorTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#fff',
  },
  errorSubtitle: {
    fontSize: 13,
    color: '#ffe3e0',
    marginTop: 4,
  },
  errorBody: {
    flex: 1,
    padding: 16,
  },
  errorText: {
    fontFamily: 'Menlo',
    fontSize: 13,
    color: '#ff6b6b',
    lineHeight: 20,
  },
  stackText: {
    fontFamily: 'Menlo',
    fontSize: 11,
    color: '#888',
    marginTop: 12,
    lineHeight: 18,
  },
  resetButton: {
    margin: 16,
    marginBottom: 40,
    backgroundColor: '#e74c3c',
    paddingVertical: 14,
    borderRadius: 10,
    alignItems: 'center',
  },
  resetButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#1a1a2e',
  },
  loadingText: {
    color: '#888888',
    fontSize: 16,
  },
});
