# Friendly Mobile iOS Setup

This project was scaffolded without the default `ios/` native folder. To run on iOS, create the native project and install pods.

## Steps
1. Ensure prerequisites: Xcode + CLT, CocoaPods (`sudo gem install cocoapods`).
2. From the project root (`friendly/mobile`), generate the iOS native folder using the React Native template that matches RN 0.72:
   ```bash
   npx react-native init FriendlyMobileNative --version 0.72.0 --directory ios-tmp --skip-install
   ```
3. Move the generated `ios` directory into this project:
   ```bash
   mv ios-tmp/ios ./ios
   rm -rf ios-tmp
   ```
4. Install pods:
   ```bash
   yarn ios:pods
   ```
5. Start Metro in a terminal:
   ```bash
   yarn start
   ```
6. In another terminal, run the simulator:
   ```bash
   yarn ios
   ```

## Notes
- Keep the RN version aligned with `react-native` in `package.json` (0.72.0). If you upgrade RN, regenerate the native project with the same version.
- If you prefer manual CocoaPods install, run from `ios/` directly: `pod install`.
- If you hit pod repo errors, run `pod repo update` then retry.
- The `ios` folder is not committed here to keep the scaffold lightweight; generate locally per the steps above.
