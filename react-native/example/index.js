/**
 * @format
 */

import {registerBunbuApp, AI_MODELS} from 'bunbu';
import {NewAppScreen} from '@react-native/new-app-screen';
import * as SafeAreaContext from 'react-native-safe-area-context';
import App from './App';
import {name as appName} from './app.json';
import {appSources} from './src/appSources';

// 1:1 swap for AppRegistry.registerComponent: dev mounts the on-device live
// editor over the interpreted snapshot; release registers App directly.
registerBunbuApp(appName, App, {
  sources: appSources,
  entry: 'App',
  apiKey: 'your-key-here',
  model: AI_MODELS.claude4Sonnet,
  builtins: {
    '@react-native/new-app-screen': {NewAppScreen},
    'react-native-safe-area-context': SafeAreaContext,
  },
});
