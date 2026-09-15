# Fonts

Drop your `.ttf` or `.otf` font files here, then register them in `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: YourFont
      fonts:
        - asset: assets/fonts/YourFont-Regular.ttf
        - asset: assets/fonts/YourFont-Bold.ttf
          weight: 700
```

Then use it: `TextStyle(fontFamily: 'YourFont')`.
