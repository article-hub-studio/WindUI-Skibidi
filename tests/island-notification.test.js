// Two defects this locks down.
//
// 1. WindUI:SetNotificationLower(true) moved the holder's bottom edge. The
//    stack is top-aligned, so nothing moved: it only changed the height used
//    to decide when to trim. The documented feature was a no-op.
//
// 2. The Dynamic Island tweened its container but assigned the text stack,
//    title, drag handle and divider directly, so they snapped into place while
//    the pill was still resizing. It also sized itself from a measurement
//    taken with Enum.Font.GothamMedium while the label renders with
//    Creator.Font, and it animated regardless of the user's motion settings.

const fs = require("fs")

const notification = fs.readFileSync("src/components/Notification.lua", "utf8")
const island = fs.readFileSync("src/components/window/Openbutton.lua", "utf8")

const failures = []
const check = (label, ok) => {
	if (!ok) failures.push(label)
}

// --- Notification: SetLower actually lowers the stack ----------------------

const setLower = /function NotModule\.SetLower\(Value\)([\s\S]*?)\n\tend/.exec(notification)
check("SetLower exists", setLower !== null)

if (setLower) {
	const body = setLower[1]
	check("SetLower moves the holder's top edge", /NotModule\.Frame\.Position = UDim2\.new\(/.test(body))
	check("SetLower derives both position and size from the same top", /local Top = if NotModule\.Lower then HOLDER_LOWER_TOP else HOLDER_TOP/.test(body))
	// The old body only touched Size, using a hard-coded bottom margin.
	check("SetLower no longer only nudges the bottom margin", !/local Bottom = if NotModule\.Lower then 12/.test(body))
}

check("a lowered top offset is defined", /HOLDER_LOWER_TOP = \d+/.test(notification))

// --- Dynamic Island: the whole pill morphs together ------------------------

const applyState = /function ApplyState\(State, AnimateState\)([\s\S]*?)\n\tend/.exec(island)
check("ApplyState exists", applyState !== null)

if (applyState) {
	const body = applyState[1]
	for (const [label, pattern] of [
		["container", /Animate\(Container, Duration, \{/],
		["main action", /Animate\(MainAction, Duration, \{/],
		["drag handle", /Animate\(Drag, Duration, \{/],
		["divider", /Animate\(Divider, Duration, \{/],
		["text stack", /Animate\(TextStack, Duration, \{/],
		["title", /Animate\(Title, Duration, \{/],
	]) {
		check(`${label} animates on the shared clock`, pattern.test(body))
	}

	// The exact assignments that used to snap.
	check("text stack is not assigned directly", !/\n\t\tTextStack\.Position = /.test(body))
	check("title is not assigned directly", !/\n\t\tTitle\.Position = /.test(body))
	check("drag handle is not assigned directly", !/\n\t\tDrag\.Size = /.test(body))
	check("divider is not assigned directly", !/\n\t\tDivider\.Position = /.test(body))
}

// --- Dynamic Island: measured with the font it renders ---------------------

check("island pulls in Motion", /local Motion = require\("\.\.\/\.\.\/modules\/Motion"\)/.test(island))
check("island honours reduced motion", /if Duration <= 0 or not Motion:IsEnabled\(\) or Motion\.Reduced then/.test(island))

check("measurements carry a font weight", /local function MeasureText\(Text, Size, MaxWidth, Weight, OnResolved\)/.test(island))
check("title measured as SemiBold, matching its label", /MeasureText\(Settings\.Title, 15, MaxTextWidth, Enum\.FontWeight\.SemiBold/.test(island))
check("content measured as Regular, matching its label", /MeasureText\(Settings\.Content, 12, MaxTextWidth, Enum\.FontWeight\.Regular/.test(island))
check("exact bounds requested with the live font", /Params\.Font = Font\.new\(Creator\.Font, Weight\)/.test(island))
check("measurement is cached", /MeasureCache\[Key\]/.test(island))
check("a font swap clears the cache", /if MeasureFontId ~= Creator\.Font then/.test(island))
// Refining must not re-queue forever.
check("in-flight measurements are deduplicated", /if PendingMeasures\[Key\] then/.test(island))
check("layout only re-runs when the width actually changed", /if MeasureCache\[Key\] ~= Width then/.test(island))
check("a resolved measurement reflows the pill", /local function ReflowFromMeasurement\(\)/.test(island))

if (failures.length > 0) {
	throw new Error(`Island / notification regressions:\n  - ${failures.join("\n  - ")}`)
}

console.log("PASS island and notification")
