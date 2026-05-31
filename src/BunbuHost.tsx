import React, {useEffect, useLayoutEffect, useSyncExternalStore} from 'react';
import {Appearance, StatusBar, StyleSheet, View} from 'react-native';
import {SafeAreaProvider} from 'react-native-safe-area-context';
import {projectStore} from './store/ProjectStore';
import LiveRuntime from './runtime/LiveRuntime';
import {
  initBridge,
  bootstrap,
  configureAgent,
  configureGitHub,
  reportRuntimeError,
  isNativeAvailable,
} from './BunbuBridge';
import {resolveGitHubClientId} from './github';
import type {AiModel} from './ai/models';

interface BunbuHostProps {
  /// Build-time snapshot of the app's source (path -> contents).
  sources: Record<string, string>;
  /// Entry module, resolved by the runtime (defaults to `index`).
  entry?: string;
  apiKey?: string;
  model?: AiModel;
  /// Override the default Bunbu GitHub OAuth client id (optional).
  githubClientId?: string;
  /// Rendered when there is no interpretable project (e.g. empty snapshot).
  fallback?: React.ComponentType<any>;
}

/// Thin host: wires the native bridge, hands native the bundled snapshot, then
/// renders whatever native pushes back. All file/agent/git state lives natively.
export default function BunbuHost({
  sources,
  entry = 'index',
  apiKey,
  model,
  githubClientId,
  fallback: Fallback,
}: BunbuHostProps) {
  // Without native, seed the bundled snapshot for the interpreter immediately.
  useLayoutEffect(() => {
    if (!isNativeAvailable && Object.keys(sources).length > 0) {
      projectStore.setFiles(sources);
    }
  }, [sources]);

  useEffect(() => {
    Appearance.setColorScheme('dark');

    if (!isNativeAvailable) {
      projectStore.setFiles(sources);
      return;
    }

    initBridge();
    if (apiKey) {
      configureAgent({apiKey, model});
    }
    configureGitHub(resolveGitHubClientId(githubClientId));
    bootstrap(sources);
  }, [sources, apiKey, model, githubClientId]);

  const fileCount = useSyncExternalStore(
    projectStore.subscribe.bind(projectStore),
    () => projectStore.list().length,
  );
  const nativeGeneration = useSyncExternalStore(
    projectStore.subscribe.bind(projectStore),
    projectStore.getNativeGeneration,
  );

  // With native: show the compiled app until the on-device store syncs, then
  // switch to the interpreted live preview (updates on every save).
  const showLivePreview = isNativeAvailable
    ? nativeGeneration > 0 && fileCount > 0
    : fileCount > 0;

  return (
    <SafeAreaProvider style={styles.root}>
      <View style={styles.root}>
        <StatusBar barStyle="light-content" backgroundColor="#1a1a2e" />
        {showLivePreview ? (
          <LiveRuntime entryFile={entry} onError={reportRuntimeError} />
        ) : Fallback ? (
          <Fallback />
        ) : null}
      </View>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#1a1a2e',
  },
});
