# Friendly Device Framework

Scaffold for device-side logic that remains hardware-agnostic by operating through clean abstractions for networking, state, simulation, and output.

## Structures
- `env/config.ts`: central configuration with environment overrides and simulated mode flag.
- `state/machine.ts`: deterministic state machine for polling and display updates with a clearly defined transition function.
- `network/index.ts`: backend polling clients including REST and simulated implementations.
- `output/index.ts`: display client interfaces ready for hardware or simulated sinks.

- ## Feature semantics
- Friendly device state labels describe what the ambient display communicates; they are not literal reports of people’s emotions nor commitments to act.
- `idle`: ambient glow fades, encouraging gentle presence without drawing focus.
- `polling`: device is checking in with backend state; visuals may pulse softly as a status indicator.
- `updating`: brief feedback that new signals were fetched; do not interpret as emergent behavior or personal shifts.
- `error`: a quiet prompt to reconnect or reload, not a judgment on the relationship.

- ## Accessibility rules
- **Touch targets** should be a minimum of 48 × 48 dp on device touch surfaces so nervous system-friendly interactions stay reliable.
- **Reduced motion** mode must honor system preferences by limiting pulsing/glow speed; it ensures folks managing vestibular or cognitive sensitivity stay comfortable.
- **Palette contrast and color pairing** should meet WCAG AA thresholds for both text and animated signals, supporting folks with visual impairments and color vision variance.
- **High/low brightness modes** respect night mode by dimming active pulses and ramping up the soft glow only when ambient light is supportive so oversensitive eyes stay calm.

- These guidelines explain why we design each gesture, signal, or glow with intention and who benefits from each rule.

## Features
- Blended state machine that transitions between idle, polling, updating, and error states while aggregating anonymized ambient signals.
- Simulation mode with mock signal generation, display logging, and TODO markers for future hardware integrations.
- Output layer that clearly separates idle, glow, and pulse behaviors for downstream renderers.

## Ethics
- Maintain privacy through anonymized, aggregated signal polling and do not retain personally identifiable information.
- Apply transparency by logging simulation inputs separately from real-world draws and exposing any assumptions in documentation.
- Avoid overreliance on ambient mood inference; pair the device layer with human oversight before acting on aggregated data.

## Future Direction
1. Wire hardware-specific display drivers into `output/display.ts` while keeping the `DisplayClient` interface stable.
2. Introduce authenticated network adapters or edge compute modules that respect `ANONYMIZED_REGION` and aggregate local metrics.
3. Expand the simulation harness with recorded signal traces for offline testing and QA.

## TODO
- [ ] Poll backend periodically respecting `config.POLL_INTERVAL_MS`.
- [x] Update display through `DisplayClient` after every successful poll.

## Next steps
1. Implement polling backend integration that invokes `NetworkClient.fetchState()` on a timer.
2. Wire display rendering so `DisplayClient.render()` runs whenever state updates arrive.
3. Add hardware-specific modules in a separate layer that implement these client interfaces.

## TODO
- [ ] Poll backend periodically respecting `config.POLL_INTERVAL_MS`.
- [ ] Update display through `DisplayClient` after every successful poll.
