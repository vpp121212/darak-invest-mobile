import { StatusBar } from 'expo-status-bar';
import { StyleSheet, View, BackHandler, Platform } from 'react-native';
import { WebView } from 'react-native-webview';
import { useEffect, useRef } from 'react';

const WEB_URL = 'https://darak-invest-backend.vercel.app';

export default function App() {
  const webViewRef = useRef(null);

  useEffect(() => {
    const backHandler = BackHandler.addEventListener('hardwareBackPress', () => {
      if (webViewRef.current) {
        webViewRef.current.goBack();
        return true;
      }
      return false;
    });
    return () => backHandler.remove();
  }, []);

  return (
    <View style={styles.container}>
      <StatusBar style="light" backgroundColor="#020617" />
      <WebView
        ref={webViewRef}
        source={{ uri: WEB_URL }}
        style={styles.webview}
        javaScriptEnabled
        domStorageEnabled
        startInLoadingState
        allowsBackForwardNavigationGestures
        allowsInlineMediaPlayback
        mediaPlaybackRequiresUserAction={false}
        overScrollMode="never"
        renderLoading={() => (
          <View style={styles.loading}>
            <StatusBar style="light" backgroundColor="#020617" />
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#020617',
  },
  webview: {
    flex: 1,
    backgroundColor: '#020617',
  },
  loading: {
    flex: 1,
    backgroundColor: '#020617',
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
