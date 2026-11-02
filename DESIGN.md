---
name: Cut & Move
description: Incumbent web design tokens and native macOS interface conventions
colors:
  bg: "#07070a"
  bg-elev: "#0f0f14"
  panel: "#13131a"
  border: "rgba(255, 255, 255, 0.08)"
  border-strong: "rgba(255, 255, 255, 0.14)"
  text: "#f5f5f7"
  text-dim: "#a1a1aa"
  text-faint: "#90909c"
  accent: "#3b82f6"
  accent-2: "#60a5fa"
  violet: "#8b5cf6"
  action-blue: "#1d4ed8"
  action-violet: "#6d28d9"
  status-green: "#22c55e"
typography:
  display:
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif'
    fontSize: "clamp(40px, 6vw, 76px)"
    fontWeight: 700
    lineHeight: 1.03
    letterSpacing: "-0.035em"
  body:
    fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Inter", system-ui, sans-serif'
    fontSize: "17px"
    lineHeight: 1.6
  label:
    fontFamily: 'ui-monospace, "SF Mono", Menlo, Consolas, monospace'
  navigation:
    fontSize: "14.5px"
    fontWeight: 500
  action:
    fontSize: "15.5px"
    fontWeight: 600
  caption:
    fontSize: "13px"
  keycap:
    fontSize: "14px"
  feature-body:
    fontSize: "15px"
  download-headline:
    fontSize: "clamp(32px, 4.5vw, 58px)"
  section-headline:
    fontSize: "clamp(30px, 4vw, 50px)"
  hero-lead:
    fontSize: "clamp(18px, 2.1vw, 22px)"
  step-title:
    fontSize: "22px"
  faq-heading:
    fontSize: "26px"
  faq-body:
    fontSize: "16px"
  creator-mark:
    fontSize: "52px"
  creator-name:
    fontSize: "32px"
  share-message:
    fontSize: "19px"
rounded:
  nav: "8px"
  button: "12px"
  comparison: "16px"
  footer-icon: "5px"
  logo-icon: "6px"
  keycap: "7px"
  creator-link: "9px"
  feature: "18px"
  step: "20px"
  creator: "24px"
  app-icon: "28px"
  pill: "999px"
spacing:
  compact: "10px"
  controls: "14px"
  group: "20px"
  gutter: "24px"
components:
  button-secondary:
    backgroundColor: "rgba(255, 255, 255, 0.04)"
    textColor: "{colors.text}"
    rounded: "{rounded.button}"
    padding: "14px 26px"
  comparison-panel:
    backgroundColor: "{colors.panel}"
    rounded: "{rounded.comparison}"
    padding: "24px"
---

## Overview

This records the incumbent system extracted from index.html, PermissionsView.swift,
AboutView.swift, and CutAndMoveApp.swift on November 2, 2026. Web token frontmatter
applies only to the website. Native macOS controls use SwiftUI/AppKit system
semantics, not literal web colors or browser layout recipes. The identity is a
familiar Mac shortcut utility with the existing scissors icon; no new visual
metaphor or creative direction has been invented.

## Colors

The website uses near-black backgrounds, pale text, muted secondary copy, and
blue/violet accents. Preserve source CSS values as the authority. Separate action
background contrast from decorative accent use when correcting accessibility.
Faint text is #90909c. Action controls use the separate #1d4ed8→#6d28d9
gradient so white labels meet measured contrast without darkening display accents.

Native windows use primary/secondary system text, orange permission guidance,
green readiness, red diagnostics, and system accent buttons. Symbols and words
communicate state together; color alone is insufficient.

## Typography

The website uses its system sans stack for text and monospace for shortcut keys.
The hero is clamp(40px,6vw,76px), weight 700, line height 1.03, tracking -0.035em.
Body is 17px at 1.6. Navigation is 14.5px and CTA labels 15.5px/600.
Native UI uses title2/body/caption/subheadline roles; About title is 24pt bold.
Use system text sizing and content-aware layout for diagnostics.

## Layout

Website container is 1120px maximum with 24px side gutters. Hero is centered;
actions wrap. Feature cards change at 900/600px; navigation hides secondary
links at 720px; creator layout changes at 760px. Comparison panels stack at 600px.
Native menu uses platform density and grouped dividers. About is 350×420pt;
permission content is 400pt wide with a content-sized vertical stack. Avoid
clipping recovery text with a fixed height and do not make the website's card grid the native app's structure.

## Elevation & Depth

Website uses tonal panels, subtle translucent borders, ambient backdrop accents,
a blurred sticky nav, and neutral soft shadows. Decorative chromatic halos were removed after hook
review; nothing was suppressed. Exact shadows/gradients live in the
sidecar. Native depth is supplied by macOS windows/menus; About icon has radius-10
shadow. No new decorative elevation system is required.

## Shapes

Website nav CTA is 8px radius, primary controls 12px, comparison panels 16px;
frontmatter records the other existing icon, keycap, feature, step, and creator radii.
Shortcut keys use the incumbent beveled key-cap treatment. Native controls retain
system shapes; preserve the existing full-bleed app-icon artwork.

## Components

- Web download controls use release-generated labels/URLs. Primary and secondary
  actions remain visually distinct; source focus-visible outline is 3px accent
  with 5px offset. Native details/summary provide FAQ interaction.
- Web share controls have progressive enhancement, copy status, external share
  links, and a readable message when Clipboard API is absent or denied.
- Native menu separates keyboard readiness, extension readiness, cut count/move
  status, login status, recovery, About, and Quit. Disable destructive actions
  while a move is busy; never equate pending cut with a completed move.
- Permission UI must distinguish absent access, unavailable monitoring, and ready.
  Success stays readable until dismissed. Diagnostics name a recovery action.
- Native About links to the product homepage and Support; Finder labels use
  singular/plural counts. Native windows and menu labels are the application interface; do not import
  website gradients, social copy, or browser-specific controls into them.

## Do's and Don'ts

- Do preserve Finder shortcuts, semantic controls, and the existing icon assets.
- Do record measured contrast and actual states, with native/web scope explicit.
- Do keep version/download claims generated from the existing source records.
- Don't invent testimonials, a new release, or runtime acceptance evidence.
- Don't treat old screenshots or a compiled app as current UI/VoiceOver proof.
- Don't redesign the existing identity as a side effect of accessibility fixes.
