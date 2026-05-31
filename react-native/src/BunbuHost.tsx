import React, {useEffect, useState} from 'react';
import {Appearance, StatusBar, StyleSheet, View} from 'react-native';
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
  const [ready, setReady] = useState(false);

  useEffect(() => {
    Appearance.setColorScheme('dark');

    if (!isNativeAvailable) {
      // No native module (e.g. running without the pod) — just show the files.
      projectStore.setFiles(sources);
      setReady(true);
      return;
    }

    initBridge();
    if (apiKey) {
      configureAgent({apiKey, model});
    }
    configureGitHub(resolveGitHubClientId(githubClientId));

    const unsubscribe = projectStore.subscribe(() => {
      if (projectStore.list().length > 0) {
        setReady(true);
      }
    });

    bootstrap(sources);
    return unsubscribe;
  }, [sources, apiKey, model, githubClientId]);

  if (!ready) {
    return Fallback && Object.keys(sources).length === 0 ? <Fallback /> : null;
  }

  return (
    <View style={styles.root}>
      <StatusBar barStyle="light-content" backgroundColor="#1a1a2e" />
      <LiveRuntime entryFile={entry} onError={reportRuntimeError} />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#1a1a2e',
  },
});
