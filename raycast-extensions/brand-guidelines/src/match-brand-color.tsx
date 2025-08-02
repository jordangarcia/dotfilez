import { Action, ActionPanel, Clipboard, List, showToast, Toast, Color, Icon } from "@raycast/api";
import { useEffect, useState } from "react";
import { colors } from "../colors/colors";

type BrandColor = {
  name: string;
  value: string;
};

type ColorMatch = {
  color: BrandColor;
  distance: number;
  similarity: number;
};

function hexToRgb(hex: string): { r: number; g: number; b: number } | null {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;
}

function calculateColorDistance(color1: string, color2: string): number {
  const rgb1 = hexToRgb(color1);
  const rgb2 = hexToRgb(color2);

  if (!rgb1 || !rgb2) return Infinity;

  // Calculate Euclidean distance in RGB space
  const rDiff = rgb1.r - rgb2.r;
  const gDiff = rgb1.g - rgb2.g;
  const bDiff = rgb1.b - rgb2.b;

  return Math.sqrt(rDiff * rDiff + gDiff * gDiff + bDiff * bDiff);
}

function findColorMatches(targetColor: string, brandColors: BrandColor[]): ColorMatch[] {
  const matches = brandColors.map((color) => {
    const distance = calculateColorDistance(targetColor, color.value);
    const maxDistance = Math.sqrt(255 * 255 * 3); // Maximum possible RGB distance
    const similarity = Math.max(0, Math.round((1 - distance / maxDistance) * 100));

    return {
      color,
      distance,
      similarity,
    };
  });

  // Sort by distance (closest first)
  const sortedMatches = matches.sort((a, b) => a.distance - b.distance);

  // Check if there are any 100% matches
  const perfectMatches = sortedMatches.filter((match) => match.similarity === 100);

  // If there are 100% matches, only show those
  if (perfectMatches.length > 0) {
    return perfectMatches;
  }

  // Otherwise, return top 5 matches
  return sortedMatches.slice(0, 5);
}

function isValidHex(hex: string): boolean {
  return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(hex);
}

type LaunchContext = {
  hex?: string;
  formattedColor?: string;
  [key: string]: any; // Allow for other properties we might receive
};

type CommandProps = {
  launchContext?: LaunchContext;
};

export default function Command(props: CommandProps) {
  const [searchText, setSearchText] = useState<string>("");
  const [colorMatches, setColorMatches] = useState<ColorMatch[]>([]);

  useEffect(() => {
    const initialize = async () => {
      console.log("MATCH-BRAND-COLOR INITIALIZING WITH PROPS:", props);
      
      // First check if we have a hex value from color picker launch context
      if (props.launchContext) {
        console.log("RECEIVED LAUNCH CONTEXT:", props.launchContext);
        
        // Try hex first, then formattedColor
        const hexValue = props.launchContext.hex || props.launchContext.formattedColor;
        
        if (hexValue && isValidHex(hexValue)) {
          console.log("USING HEX VALUE:", hexValue);
          setSearchText(hexValue);
          const matches = findColorMatches(hexValue, colors);
          setColorMatches(matches);
          return;
        } else {
          console.log("INVALID OR NO HEX VALUE FOUND:", hexValue);
        }
      }

      // Otherwise, try to get from clipboard
      try {
        const clipboardText = await Clipboard.readText();

        if (clipboardText) {
          // Clean up the hex value (remove whitespace, ensure # prefix)
          let cleanHex = clipboardText.trim();
          if (!cleanHex.startsWith("#") && /^[A-Fa-f0-9]{3,6}$/.test(cleanHex)) {
            cleanHex = "#" + cleanHex;
          }

          if (isValidHex(cleanHex)) {
            setSearchText(cleanHex);
            const matches = findColorMatches(cleanHex, colors);
            setColorMatches(matches);
          }
        }
      } catch (error) {
        // Silently fail if clipboard reading fails
      }
    };

    // Small delay to ensure component is mounted
    setTimeout(initialize, 100);
  }, [props.launchContext]);

  const handleSearchChange = (text: string) => {
    setSearchText(text);

    if (!text.trim()) {
      setColorMatches([]);
      return;
    }

    // Clean up the hex value
    let cleanHex = text.trim();
    if (!cleanHex.startsWith("#") && /^[A-Fa-f0-9]{3,6}$/.test(cleanHex)) {
      cleanHex = "#" + cleanHex;
    }

    if (isValidHex(cleanHex)) {
      const matches = findColorMatches(cleanHex, colors);
      setColorMatches(matches);
    } else {
      setColorMatches([]);
    }
  };

  const currentColor = searchText && isValidHex(searchText) ? searchText : null;

  return (
    <List
      // searchText={searchText}
      onSearchTextChange={handleSearchChange}
      searchBarPlaceholder={searchText ? searchText : "Enter hex color (e.g., #FF5733)"}
      // throttle={true}
    >
      {colorMatches.length > 0 && (
        <List.Section title="Brand Color Matches">
          {colorMatches.map((match, index) => (
            <List.Item
              key={match.color.name}
              title={match.color.name}
              subtitle={`${match.color.value} • ${match.similarity}% match`}
              icon={{ source: Icon.Circle, tintColor: match.color.value }}
              accessories={[{ text: `#${index + 1}` }, { text: `${match.similarity}%` }]}
              actions={
                <ActionPanel>
                  <Action.CopyToClipboard title="Copy Color Name" content={match.color.name} icon={Icon.Text} />
                  <Action.CopyToClipboard title="Copy Hex Value" content={match.color.value} icon={Icon.Clipboard} />
                </ActionPanel>
              }
            />
          ))}
        </List.Section>
      )}

      {searchText && !isValidHex(searchText) && (
        <List.Section title="Invalid Input">
          <List.Item
            title="Invalid Hex Color"
            subtitle={`"${searchText}" is not a valid hex color format`}
            icon={{ source: Icon.XMarkCircle, tintColor: Color.Red }}
          />
        </List.Section>
      )}

      {!searchText && (
        <List.Section title="Instructions">
          <List.Item
            title="Enter a hex color to find matches"
            subtitle="You can enter colors like #FF5733, FF5733, #F73, or F73"
            icon={{ source: Icon.Info, tintColor: Color.SecondaryText }}
          />
        </List.Section>
      )}
    </List>
  );
}
