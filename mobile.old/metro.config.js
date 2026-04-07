/**
 * Metro configuration for React Native + Expo
 *
 * From RN 0.73+, metro.config.js must extend '@react-native/metro-config'.
 * We merge in Expo's defaults so both Expo modules and RN CLI work correctly.
 *
 * @see https://docs.expo.dev/guides/customizing-metro/
 * @see https://reactnative.dev/docs/metro
 */
const { getDefaultConfig: getExpoDefault } = require('@expo/metro-config');
const { getDefaultConfig: getRNDefault, mergeConfig } = require('@react-native/metro-config');

const expoConfig = getExpoDefault(__dirname);
const rnConfig = getRNDefault(__dirname);

module.exports = mergeConfig(rnConfig, expoConfig);
