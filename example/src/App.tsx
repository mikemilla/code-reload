/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 */

import { StatusBar, StyleSheet, Text, useColorScheme, View } from 'react-native';
import {
  SafeAreaProvider,
  useSafeAreaInsets,
} from 'react-native-safe-area-context';

function App() {
  const isDarkMode = useColorScheme() === 'dark';

  return (
    <SafeAreaProvider>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <AppContent />
    </SafeAreaProvider>
  );
}

function AppContent() {
  const safeAreaInsets = useSafeAreaInsets();

  return (
    <View
      style={[
        styles.container,
        {
          paddingTop: safeAreaInsets.top + 24,
          paddingBottom: safeAreaInsets.bottom + 24,
        },
      ]}>
      <View style={styles.editHint}>
        <Text style={styles.editHintLabel}>Live preview</Text>
        <Text style={styles.editHintTitle}>Edit me in App.tsx</Text>
        <Text style={styles.editHintBody}>
          Open example/src/App.tsx in your editor and change this text.
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
    backgroundColor: '#1a1a2e',
  },
  editHint: {
    maxWidth: 320,
    alignItems: 'center',
    paddingVertical: 28,
    paddingHorizontal: 24,
    borderRadius: 16,
    backgroundColor: '#2a2a3e',
    borderWidth: 1,
    borderColor: '#6c63ff',
  },
  editHintLabel: {
    fontSize: 13,
    fontWeight: '600',
    letterSpacing: 0.6,
    textTransform: 'uppercase',
    color: '#6c63ff',
    marginBottom: 12,
  },
  editHintTitle: {
    fontSize: 28,
    fontWeight: '700',
    color: '#ffffff',
    textAlign: 'center',
    marginBottom: 16,
  },
  editHintBody: {
    fontSize: 16,
    lineHeight: 24,
    color: '#b8b8c8',
    textAlign: 'center',
  },
});

export default App;
