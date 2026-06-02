/**
 * @format
 */

import {registerCodeReloadApp, AI_MODELS} from 'code-reload';
import * as SafeAreaContext from 'react-native-safe-area-context';
import App from './src/App';
import {name as appName} from './app.json';
import {appSources} from './appSources';

registerCodeReloadApp(appName, App, {
  sources: appSources,
  entry: 'App',
  apiKey: 'your-key-here',
  model: AI_MODELS.claude4Sonnet,
  builtins: {
    'react-native-safe-area-context': SafeAreaContext,
  },
});
