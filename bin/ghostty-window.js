// Maximizes or restores the Ghostty window whose title contains a marker.
//   osascript -l JavaScript ghostty-window.js <marker> maximize
//     fills the visible area of the window's screen; prints the old bounds as "x,y,w,h"
//   osascript -l JavaScript ghostty-window.js <marker> restore <x,y,w,h>
// Needs Accessibility access for the app running it (Ghostty, when called from Neovim).
ObjC.import("AppKit");

function run(argv) {
  const [marker, action, saved] = argv;
  const ghostty = Application("System Events").processes.byName("Ghostty");
  const matches = ghostty.windows.whose({ name: { _contains: marker } });
  if (matches.length === 0) return "error: no Ghostty window titled with " + marker;
  const win = matches[0];

  if (action === "restore") {
    const [x, y, w, h] = saved.split(",").map(Number);
    win.position = [x, y];
    win.size = [w, h];
    return "ok";
  }

  const [x, y] = win.position();
  const [w, h] = win.size();
  const screen = screenContaining(x + w / 2, y + h / 2);
  // AppKit measures from the bottom of the primary screen; System Events from the top.
  const primaryHeight = $.NSScreen.screens.objectAtIndex(0).frame.size.height;
  const visible = screen.visibleFrame;
  win.position = [visible.origin.x, primaryHeight - (visible.origin.y + visible.size.height)];
  win.size = [visible.size.width, visible.size.height];
  return [x, y, w, h].join(",");
}

function screenContaining(cx, cy) {
  const screens = $.NSScreen.screens;
  const primaryHeight = screens.objectAtIndex(0).frame.size.height;
  for (let i = 0; i < screens.count; i++) {
    const frame = screens.objectAtIndex(i).frame;
    const top = primaryHeight - (frame.origin.y + frame.size.height);
    if (cx >= frame.origin.x && cx < frame.origin.x + frame.size.width && cy >= top && cy < top + frame.size.height) {
      return screens.objectAtIndex(i);
    }
  }
  return screens.objectAtIndex(0);
}
