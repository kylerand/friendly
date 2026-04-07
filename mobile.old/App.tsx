import React, { useEffect, useState } from 'react';
import { StatusBar, StyleSheet, Text, View, ScrollView, useColorScheme, ActivityIndicator } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { useFonts } from 'expo-font';
import { ThemeProvider, useTheme } from './src/design/ThemeProvider';
import AppNavigator from './src/navigation/AppNavigator';
import { colors, palette } from './src/design/theme';

/**
 * Error Boundary — catches errors in the React render tree and
 * shows a human-readable diagnostic instead of silently crashing.
 * Uses scheme-aware colors so it doesn't flash white in dark mode.
 */
class ErrorBoundary extends React.Component<
  { children: React.ReactNode; scheme: 'light' | 'dark' },
  { error: Error | null }
> {
  state = { error: null as Error | null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  render() {
    if (this.state.error) {
      const isDark = this.props.scheme === 'dark';
      const bg = isDark ? colors.dark.background : colors.light.background;
      const title = isDark ? '#FF7A5C' : '#c00';
      const msg = isDark ? colors.dark.textPrimary : '#333';
      const stack = isDark ? colors.dark.textTertiary : '#666';

      return (
        <View style={[errorStyles.container, { backgroundColor: bg }]}>
          <ScrollView contentContainerStyle={errorStyles.scroll}>
            <Text style={[errorStyles.title, { color: title }]}>⚠️  Something went wrong</Text>
            <Text style={[errorStyles.message, { color: msg }]}>{this.state.error.message}</Text>
            <Text style={[errorStyles.stack, { color: stack }]}>{this.state.error.stack}</Text>
          </ScrollView>
        </View>
      );
    }
    return this.props.children;
  }
}

const errorStyles = StyleSheet.create({
  container: { flex: 1, paddingTop: 80 },
  scroll: { padding: 24 },
  title: { fontSize: 18, fontWeight: '700', marginBottom: 12 },
  message: { fontSize: 14, marginBottom: 16 },
  stack: { fontSize: 11, fontFamily: 'monospace' },
});

const ThemedApp = () => {
  const { c, scheme } = useTheme();

  return (
    <View style={[styles.container, { backgroundColor: c.background }]}>
      <StatusBar
        barStyle={scheme === 'dark' ? 'light-content' : 'dark-content'}
        backgroundColor={c.background}
      />
      <AppNavigator />
    </View>
  );
};

const App = () => {
  const systemScheme = useColorScheme();
  const rootBg = systemScheme === 'dark' ? colors.dark.background : colors.light.background;

  const [fontsLoaded, fontError] = useFonts({
    LePetitCochon: require('./assets/fonts/LePetitCochon.ttf'),
    'Nunito-Bold': require('./assets/fonts/Nunito-Bold.ttf'),
    'Nunito-SemiBold': require('./assets/fonts/Nunito-SemiBold.ttf'),
    Nunito: require('./assets/fonts/Nunito-Regular.ttf'),
  });

  // Safety timeout — proceed without custom fonts after 5 seconds
  const [timedOut, setTimedOut] = useState(false);
  useEffect(() => {
    const timer = setTimeout(() => setTimedOut(true), 5000);
    return () => clearTimeout(timer);
  }, []);

  const ready = fontsLoaded || fontError != null || timedOut;

  if (!ready) {
    return (
      <View style={[styles.rootBackground, styles.loadingContainer, { backgroundColor: rootBg }]}>
        <ActivityIndicator size="large" color={palette.flame} />
      </View>
    );
  }

  return (
    <ErrorBoundary scheme={systemScheme === 'dark' ? 'dark' : 'light'}>
      <View style={[styles.rootBackground, { backgroundColor: rootBg }]}>
        <SafeAreaProvider>
          <ThemeProvider>
            <ThemedApp />
          </ThemeProvider>
        </SafeAreaProvider>
      </View>
    </ErrorBoundary>
  );
};

const styles = StyleSheet.create({
  rootBackground: {
    flex: 1,
  },
  loadingContainer: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  container: {
    flex: 1,
  },
});

export default App;
