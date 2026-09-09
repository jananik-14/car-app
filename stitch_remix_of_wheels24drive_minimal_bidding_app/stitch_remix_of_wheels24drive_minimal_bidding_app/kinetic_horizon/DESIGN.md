---
name: Kinetic Horizon
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#44474e'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#74777f'
  outline-variant: '#c4c6cf'
  surface-tint: '#485f83'
  primary: '#001128'
  on-primary: '#ffffff'
  primary-container: '#0a2647'
  on-primary-container: '#768eb4'
  inverse-primary: '#b0c8f1'
  secondary: '#994700'
  on-secondary: '#ffffff'
  secondary-container: '#fb7800'
  on-secondary-container: '#592600'
  tertiary: '#001126'
  on-tertiary: '#ffffff'
  tertiary-container: '#00264a'
  on-tertiary-container: '#688ec3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#b0c8f1'
  on-primary-fixed: '#001c3b'
  on-primary-fixed-variant: '#30476a'
  secondary-fixed: '#ffdbc8'
  secondary-fixed-dim: '#ffb68b'
  on-secondary-fixed: '#321200'
  on-secondary-fixed-variant: '#753400'
  tertiary-fixed: '#d4e3ff'
  tertiary-fixed-dim: '#a4c9ff'
  on-tertiary-fixed: '#001c39'
  on-tertiary-fixed-variant: '#1c4878'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '700'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-2xs: 0.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.25rem
  space-xl: 1.5rem
  space-2xl: 2rem
  space-3xl: 2.5rem
  space-4xl: 3rem
  margin-mobile: 1rem
  margin-tablet: 1.5rem
  gutter-mobile: 0.75rem
  gutter-tablet: 1rem
---

## Brand & Style

The platform democratizes high-stakes vehicle auctions across India, bridging tier-1 metro dealers and first-time tier-2/3 vehicle buyers. The aesthetic establishes instant institutional trust paired with high-velocity transactional excitement. 

### Design Direction
The visual language draws inspiration from modern Indian fintech pioneers (Google Pay, PhonePe, and Cred)—utilizing deliberate whitespace, immediate clarity, and hyper-legible transactional state feedback. 

- **Effortless Frictionlessness:** High visual hierarchy allows users to parse live auction statuses, vehicle health, and bidding increments within 2 seconds.
- **Atmospheric Clarity:** Screens avoid cognitive overload by limiting visible interactive priorities to 3–4 key focal anchors per view.
- **Trust-Infused Tactility:** Crisp navy foundations anchor high-value commitments, while calculated hits of energetic orange guide real-time decisive action.

## Colors

The palette balances authoritative institutional security with high-momentum transactional urgency.

### Palette Architecture
- **Primary Navy (`#0A2647`):** The institutional bedrock. Used for top-level headers, primary transactional surfaces, critical data badges, and dominant cards.
- **Secondary Kinetic Orange (`#FF7A00`):** The momentum catalyst. Strictly reserved for live auction timers, high-intent call-to-actions ("Place Bid"), bid step-counters, and winning state indicators. Never dilute its urgency with generic usage.
- **Tertiary Deep Cobalt (`#144272`):** Used for auxiliary interactive states, subtle badge containers, selected navigation states, and segmented controls.
- **Neutral Slate (`#64748B`):** System mid-tone for secondary labels, metadata strings, and structural border delimiters.

### Functional Canvas & Tonal Backgrounds
- **App Canvas:** `#F8FAFC` (Off-white slate providing high optical separation without harsh glare).
- **Surface Elevation:** `#FFFFFF` (Pure white base for cards, sheets, and dynamic bidding panels).
- **Border & Stroke:** `#E2E8F0` (Restrained outline defining interactive bounds without introducing visual clutter).
- **Success Tone:** `#10B981` (Outbid safe / verified vehicle green).
- **Critical Alert Tone:** `#EF4444` (Outbid warning / reserve price unmet).

## Typography

Plus Jakarta Sans powers the entire typographic hierarchy. Its rounded geometry, wide aperture, and modern grotesque rhythm ensure rapid legibility for numbers and rapid bidding changes under all lighting environments.

### Numerical Emphasis & Tabular Clarity
All financial counters, countdown timers, and vehicle odometer metrics must use tabular numbers (`tnum`) to eliminate micro-jittering during high-frequency price updates. 

### Typographic Restraint
Limit screens to a maximum of three typographic scales simultaneously (e.g., `headline-md` for vehicle title, `body-sm` for odometer/location metadata, and `display-lg-mobile` for current bid value).

## Layout & Spacing

The layout is built on a 4px base scale within an 8px fluid layout model designed specifically for edge-to-edge mobile app screens.

### Spatial Discipline
- **Screen Margins:** Fixed 16px (`space-md`) on standard compact mobile viewports, scaling to 24px (`space-xl`) on foldables and tablets.
- **Card Padding:** Internal card padding is consistently 16px (`space-md`) or 20px (`space-lg`) to prevent claustrophobic data packing.
- **Touch Targets:** All interactive triggers maintain an unyielding minimum tap height of 52px (exceeding standard 48px metrics) to prevent mis-taps during active real-time bidding sessions.
- **Layout Model:** A vertical stack pattern prioritizing linear eye scanning. Side-by-side components are reserved exclusively for binary choices (e.g., Quick Bid presets, "Inspect" vs "Bid Now").

## Elevation & Depth

Visual hierarchy uses ambient low-contrast shadows paired with precise 1px ghost borders (`#E2E8F0`). This replicates the high-end, clean feel of modern fintech applications without skeuomorphic heaviness.

### Elevation Levels
- **Level 0 (Base Canvas):** Background `#F8FAFC`. Zero elevation, non-interactive foundation.
- **Level 1 (Resting Cards & Listings):** Pure white `#FFFFFF` surface accompanied by a subtle ambient drop shadow:
  - `box-shadow: 0 4px 20px -2px rgba(10, 38, 71, 0.05), 0 2px 6px -1px rgba(10, 38, 71, 0.03);`
  - Border: 1px solid `#E2E8F0`.
- **Level 2 (Active Bidding Drawers & Sticky Bars):** Floating bottom sheets and elevated bid trays:
  - `box-shadow: 0 -8px 24px -4px rgba(10, 38, 71, 0.08), 0 -2px 8px -1px rgba(10, 38, 71, 0.04);`
  - Border-top: 1px solid `#E2E8F0`.
- **Level 3 (Modals & Urgent Overlays):** Action confirmation sheets:
  - `box-shadow: 0 20px 40px -8px rgba(10, 38, 71, 0.16);`
  - Backdrop filter: `blur(8px)` with background `rgba(10, 38, 71, 0.4)`.

## Shapes

The design system incorporates generous curvature to evoke approachable, modern consumer software while preserving structural discipline.

### Geometry Specifications
- **Cards & Primary Modules:** 16px (`rounded-lg`) to 24px (`rounded-xl`) corner radii. Large listing cards and bidding containers utilize 20px or 24px to look welcoming and tactile.
- **Primary Buttons & Floating Action Bars:** 16px (`rounded-lg`) or fully pill-shaped (9999px) for sticky instant-action triggers.
- **Chips, Badges & Counter Pills:** Fully pill-shaped (`rounded-full`) to immediately delineate categorical and state-driven metadata from structural cards.
- **Input Fields & Increment Pickers:** 14px to 16px (`rounded-lg`) matching primary button curvature.

## Components

### Buttons
- **Primary Kinetic Bid Button:**
  - Height: Minimum 54px.
  - Background: `#FF7A00` with white text (`#FFFFFF`, `label-lg`).
  - Shape: 16px corner radius.
  - Active Press: Scale transform `scale(0.98)` with dynamic haptic feedback.
- **Secondary / Action Auxiliary:**
  - Height: 52px.
  - Background: `#0A2647` with white text. Used for "Instant Buy", "View Inspection Report".
- **Tertiary / Outlined:**
  - Height: 52px.
  - Background: `#FFFFFF`, Border: 1.5px solid `#E2E8F0`, Text: `#0A2647`.

### Cards (Vehicle Listing & Live Auction)
- Background `#FFFFFF`, rounded 20px, bordered by 1px `#E2E8F0`.
- Structure:
  1. Image container (16:9 aspect ratio) with top-pinned dynamic badges ("Live", "Starts in 2h").
  2. Content area (16px padding): Make, Model, Year, Fuel Type, and Location tag.
  3. High-contrast price tray: Dedicated contrasting sub-card displaying "Current Bid" in `display-lg-mobile` alongside the live countdown timer pill.

### Chips & Badges
- **Live State Pill:** `#FF7A00` background or soft tint `#FFF4ED` with `#FF7A00` text, featuring a pulsing 6px indicator dot.
- **Verification Badge:** `#F0FDF4` background with `#16A34A` text and subtle check icon ("Inspected: 140 Points").
- **Specification Chip:** `#F1F5F9` background, `#475569` text, 8px vertical padding, 12px horizontal padding, pill-shaped.

### Bid Stepper & Input Fields
- Numeric input surfaces are minimum 56px height.
- Bid increments feature large `+ ₹5,000` / `+ ₹10,000` tactile pills that instantly refresh the total proposed sum without triggering keyboard overlays.
- Text inputs utilize an inset border `#E2E8F0` transitioning to a 2px `#0A2647` border upon focus, with floating labels to prevent context loss.

### Checkboxes & Radios
- Size: 24px x 24px with 6px corner radius for checkboxes; circular for radio buttons.
- Checked State: `#0A2647` fill with crisp white checkmark. Unchecked: 1.5px border `#CBD5E1`.

### Platform Specific: "2-Second Comprehension" Bid Drawer
- Sticky bottom persistent sheet resting at bottom of screen.
- Layout: Current High Bid on the left; Primary Instant Bid button on the right.
- Zero extraneous detail: only high bid, time remaining, and single-tap submission trigger.