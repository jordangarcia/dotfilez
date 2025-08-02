import { closeMainWindow, LaunchType, showToast, Toast, showHUD } from "@raycast/api";
import { crossLaunchCommand } from "raycast-cross-extension";

export default async function Command() {
  await closeMainWindow();

  try {
    console.log("L#8FBC61AUNCHING COLOR PICKER TO COPY COLOR TO CLIPBOARD");

    // Launch color picker with copyToClipboard enabled
    await crossLaunchCommand({
      name: "pick-color",
      type: LaunchType.UserInitiated,
      extensionName: "color-picker",
      ownerOrAuthorName: "thomas",
      context: {
        copyToClipboard: true,
      },
    });

    // Show instruction to user
    await showHUD("Color copied! Now run 'Match Brand Color' command to find matches.");
  } catch (error) {
    console.error("ERROR LAUNCHING COLOR PICKER:", error);
    await showToast({
      style: Toast.Style.Failure,
      title: "Color Picker Error",
      message: String((error as Error)?.message || error),
    });
  }
}
