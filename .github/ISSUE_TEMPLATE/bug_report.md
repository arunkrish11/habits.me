name: Bug report
description: Something in habits.me is not working
labels: [bug]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for reporting! Please fill in as much as you can.
        Your habit data stays on your phone, so please don't paste private information.
  - type: dropdown
    id: area
    attributes:
      label: Where does the problem happen?
      options:
        - Home screen (habit list, date picker)
        - Habit detail (streaks, calendar)
        - New / Edit habit
        - Settings (theme, notification)
        - Backup / Restore
        - App won't open or crashes
        - Other
    validations:
      required: true
  - type: textarea
    id: what
    attributes:
      label: What happened?
      description: Describe the problem. Screenshots help.
    validations:
      required: true
  - type: textarea
    id: steps
    attributes:
      label: Steps to reproduce
      placeholder: |
        1. Open the app
        2. Tap New
        3. ...
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: What did you expect to happen?
  - type: input
    id: phone
    attributes:
      label: Phone model and Android version
      placeholder: Xiaomi Redmi 9A, Android 10
    validations:
      required: true
  - type: input
    id: version
    attributes:
      label: App version
      description: Open Settings and scroll to the bottom.
      placeholder: v1.0.1 (2)
    validations:
      required: true
  - type: dropdown
    id: source
    attributes:
      label: Installed from
      options:
        - Obtainium
        - GitHub APK
        - F-Droid
        - Built myself
    validations:
      required: true
  - type: textarea
    id: logs
    attributes:
      label: Crash log (optional)
      description: If the app crashes, connect the phone and run `adb logcat -d`, then paste the lines with FATAL or flutter.
      render: shell