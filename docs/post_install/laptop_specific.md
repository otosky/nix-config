# Laptop-Specific

## Fixing Blurry Apps

This is a Wayland problem on the Framework.

### Jetbrains

Opt-in to using the new Wayland support by adding this to the JVM options:

```
-Dawt.toolkit.name=WLToolkit
```

[Ref](https://blog.jetbrains.com/platform/2024/07/wayland-support-preview-in-2024-2/#how-to-opt-in)

This JVM property also needs to be added:

```
_JAVA_AWT_WM_NONPARENTING=1
```

### Brave Browser

In `brave://flags`, set "Preferred Ozone Platform" to "Wayland".


