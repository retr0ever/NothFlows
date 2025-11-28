# Flow DSL Reference

## Schema Overview

The NothFlows DSL (Domain-Specific Language) is a simple JSON format for defining automation flows.

```json
{
  "trigger": "mode.on:<mode_name>",
  "actions": [
    { "type": "<action_type>", "<param>": <value> }
  ]
}
```

## Triggers

### Format

```
mode.<event>:<mode_name>
```

### Events

- `on` - When mode is activated
- `off` - When mode is deactivated

### Mode Names

- `sleep` - Sleep mode
- `focus` - Focus mode
- `custom` - Custom mode

### Examples

```json
"trigger": "mode.on:sleep"
"trigger": "mode.off:focus"
"trigger": "mode.on:custom"
```

## Actions

### File Cleanup Actions

#### clean_screenshots

Delete screenshots older than specified days.

**Parameters:**
- `older_than_days` (number): Days threshold

**Example:**
```json
{ "type": "clean_screenshots", "older_than_days": 30 }
```

**Natural Language:**
- "Clean screenshots older than 30 days"
- "Delete old screenshots"
- "Remove screenshots from last month"

#### clean_downloads

Delete downloads older than specified days.

**Parameters:**
- `older_than_days` (number): Days threshold

**Example:**
```json
{ "type": "clean_downloads", "older_than_days": 7 }
```

**Natural Language:**
- "Clean downloads older than 7 days"
- "Delete old downloads"
- "Clear download folder"

---

### Notification Actions

#### mute_apps

Mute notifications for specified apps.

**Parameters:**
- `apps` (array of strings): App names to mute

**Example:**
```json
{ "type": "mute_apps", "apps": ["Instagram", "TikTok", "Twitter"] }
```

**Natural Language:**
- "Mute Instagram, TikTok, and Twitter"
- "Silence notifications from social media"
- "Mute all messaging apps"

#### enable_dnd

Enable Do Not Disturb mode.

**Parameters:** None

**Example:**
```json
{ "type": "enable_dnd" }
```

**Natural Language:**
- "Enable Do Not Disturb"
- "Turn on DND"
- "Activate Do Not Disturb mode"

---

### Display Actions

#### lower_brightness

Set screen brightness level.

**Parameters:**
- `to` (number 0-100): Target brightness percentage

**Example:**
```json
{ "type": "lower_brightness", "to": 20 }
```

**Natural Language:**
- "Lower brightness to 20%"
- "Set brightness to 50"
- "Dim screen to 10 percent"

---

### Audio Actions

#### set_volume

Set system volume level.

**Parameters:**
- `level` (number 0-100): Target volume percentage

**Example:**
```json
{ "type": "set_volume", "level": 10 }
```

**Natural Language:**
- "Set volume to 10%"
- "Lower volume to 25"
- "Mute volume"

---

### Connectivity Actions

#### disable_wifi

Disable Wi-Fi.

**Parameters:** None

**Example:**
```json
{ "type": "disable_wifi" }
```

**Natural Language:**
- "Disable Wi-Fi"
- "Turn off Wi-Fi"
- "Disconnect from Wi-Fi"

**Note:** On Android 10+, this may require user interaction.

#### disable_bluetooth

Disable Bluetooth.

**Parameters:** None

**Example:**
```json
{ "type": "disable_bluetooth" }
```

**Natural Language:**
- "Disable Bluetooth"
- "Turn off Bluetooth"
- "Disconnect Bluetooth"

**Note:** On Android 13+, this may require user interaction.

---

### Personalisation Actions

#### set_wallpaper

Change device wallpaper.

**Parameters:**
- `path` (string): Path to wallpaper image

**Example:**
```json
{ "type": "set_wallpaper", "path": "/storage/emulated/0/Pictures/night.jpg" }
```

**Natural Language:**
- "Set wallpaper to night mode image"
- "Change wallpaper"

---

### App Launch Actions

#### launch_app

Launch a specific application.

**Parameters:**
- `app` (string): App name to launch

**Example:**
```json
{ "type": "launch_app", "app": "Notion" }
```

**Natural Language:**
- "Launch Notion"
- "Open Spotify"
- "Start YouTube Music"

---

## Complete Examples

### Example 1: Sleep Mode Flow

**Natural Language:**
```
"When sleep mode is on, clean screenshots older than 30 days and lower brightness to 20%"
```

**Generated DSL:**
```json
{
  "trigger": "mode.on:sleep",
  "actions": [
    { "type": "clean_screenshots", "older_than_days": 30 },
    { "type": "lower_brightness", "to": 20 }
  ]
}
```

### Example 2: Focus Mode Flow

**Natural Language:**
```
"Mute Instagram, TikTok, and Twitter, enable Do Not Disturb, and launch Notion"
```

**Generated DSL:**
```json
{
  "trigger": "mode.on:focus",
  "actions": [
    { "type": "mute_apps", "apps": ["Instagram", "TikTok", "Twitter"] },
    { "type": "enable_dnd" },
    { "type": "launch_app", "app": "Notion" }
  ]
}
```

### Example 3: Custom Mode Flow

**Natural Language:**
```
"Clean downloads older than 7 days, disable Wi-Fi and Bluetooth, and set volume to 0"
```

**Generated DSL:**
```json
{
  "trigger": "mode.on:custom",
  "actions": [
    { "type": "clean_downloads", "older_than_days": 7 },
    { "type": "disable_wifi" },
    { "type": "disable_bluetooth" },
    { "type": "set_volume", "level": 0 }
  ]
}
```

## Validation Rules

### Trigger Validation

✅ Valid:
```json
"trigger": "mode.on:sleep"
"trigger": "mode.off:focus"
```

❌ Invalid:
```json
"trigger": "sleep"              // Missing mode.on/off
"trigger": "mode.on:invalid"    // Invalid mode name
"trigger": "on:sleep"           // Missing mode prefix
```

### Action Validation

✅ Valid:
```json
{ "type": "clean_screenshots", "older_than_days": 30 }
{ "type": "enable_dnd" }
```

❌ Invalid:
```json
{ "type": "invalid_action" }                    // Unknown action type
{ "type": "clean_screenshots" }                 // Missing required parameter
{ "type": "lower_brightness", "to": 150 }       // Out of range (0-100)
```

### Complete Flow Validation

A flow is valid if:
1. `trigger` matches format: `mode.(on|off):(sleep|focus|custom)`
2. `actions` is non-empty array
3. Each action has valid `type` from allowed set
4. Each action has required parameters
5. Parameter values are within valid ranges

## Programmatic Usage

### Creating a Flow

```dart
import 'package:nothflows/models/flow_dsl.dart';

final flow = FlowDSL(
  trigger: 'mode.on:sleep',
  actions: [
    FlowAction(
      type: 'clean_screenshots',
      parameters: {'older_than_days': 30},
    ),
    FlowAction(
      type: 'lower_brightness',
      parameters: {'to': 20},
    ),
  ],
);

// Validate
if (flow.isValid()) {
  print('Valid flow!');
}
```

### Parsing from JSON

```dart
final jsonString = '''
{
  "trigger": "mode.on:sleep",
  "actions": [
    { "type": "clean_screenshots", "older_than_days": 30 }
  ]
}
''';

final flow = FlowDSL.fromJsonString(jsonString);
```

### Generating Description

```dart
print(flow.getDescription());
// Output:
// When sleep mode is activated:
//   • Clean screenshots older than 30 days
//   • Set brightness to 20%
```

## Natural Language Tips

### Be Specific

✅ Good:
- "Clean screenshots older than 30 days"
- "Set brightness to 20%"
- "Mute Instagram and TikTok"

❌ Vague:
- "Clean stuff"
- "Make screen dark"
- "Stop notifications"

### Use Numbers

✅ Good:
- "Older than 30 days"
- "Brightness to 20%"
- "Volume to 10"

❌ Unclear:
- "Old screenshots"
- "Low brightness"
- "Quiet volume"

### List Apps Clearly

✅ Good:
- "Mute Instagram, TikTok, and Twitter"
- "Mute Instagram, TikTok, Twitter"

❌ Unclear:
- "Mute social media"
- "Mute some apps"

### Compound Actions

You can describe multiple actions in one sentence:

✅ Good:
```
"Clean screenshots older than 30 days, lower brightness to 20%, and enable Do Not Disturb"
```

This generates:
```json
{
  "trigger": "mode.on:sleep",
  "actions": [
    { "type": "clean_screenshots", "older_than_days": 30 },
    { "type": "lower_brightness", "to": 20 },
    { "type": "enable_dnd" }
  ]
}
```

## Extending the DSL

To add a new action type:

### 1. Define the Action

```dart
// Add to validActionTypes in lib/models/flow_dsl.dart
final validActionTypes = {
  // ... existing types
  'your_new_action',
};
```

### 2. Implement Execution

```dart
// Add to _executeAction in lib/services/automation_executor.dart
case 'your_new_action':
  return await _yourNewAction(action.parameters);
```

### 3. Update System Prompt

```dart
// Add to systemPrompt in lib/services/cactus_llm_service.dart
- your_new_action: param_name (type)
```

### 4. Add Description Logic

```dart
// Add to getDescription in lib/models/flow_dsl.dart
case 'your_new_action':
  buffer.writeln('Your action description');
```

---

**Version:** 1.0.0
**Last Updated:** 2025-01-XX
