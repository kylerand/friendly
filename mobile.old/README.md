# Friendly Mobile

Welcome! This scaffold keeps the Friendly mobile experience organized so you can focus on delivering joy.

## Flow overview
1. `App.tsx` warms up the root `SafeAreaView`, `StatusBar`, and delegates to `AppNavigator`.
2. `AppNavigator` wires `Home` and `Profile` screens via `AppStackParamList`, keeping navigation typed.
3. `HomeScreen` hydrates mock connections through `useAppState` and `fetchMockProfiles`, then highlights a kind placeholder card.
4. `ProfileScreen` reads `profileId` from params and renders a gentle placeholder while awaiting real data wiring.
5. `services/mockService` exposes API-like interfaces and mock data, while `utils/formatMessage` centralizes friendly status copy.

## iOS quickstart (no bundled ios/ folder)
1. Ensure Xcode + CLT and CocoaPods (`sudo gem install cocoapods`).
2. Generate the native iOS folder matching RN 0.72 (see `IOS_SETUP.md` for exact commands).
3. Install pods via `yarn ios:pods`.
4. Start Metro with `yarn start` in one terminal.
5. Run `yarn ios` in another to launch the simulator.

## TODOs
- [ ] Swap the mock service with the real backend client once contracts stabilize.
- [ ] Replace `useAppState` with shared context for community-wide state needs.
- [ ] Polish UI placeholders with finalized design assets and motion.
- [ ] Add unit and integration tests to cover navigation flows and services.

You're off to a great start—keep building with confidence!
