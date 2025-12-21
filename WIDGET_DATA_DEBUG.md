# Widget Data Debugging Guide

## Why Widget Shows "No Data"

The widget shows "No data" when:
1. **No data has been written yet** - You need to open the app first
2. **App Groups not configured** - Both targets need App Groups capability
3. **No assets with values** - You need at least one asset with a value

## Quick Fix Steps

### Step 1: Verify App Groups Setup
1. Open Xcode
2. Select **Asseta** target (main app)
3. Go to **Signing & Capabilities**
4. Verify **App Groups** shows: `group.com.asseta.widget` ✅
5. Select **AssetaWidgetExtension** target
6. Go to **Signing & Capabilities**
7. Verify **App Groups** shows: `group.com.asseta.widget` ✅

### Step 2: Write Data to Widget
1. **Run the app** (`Cmd + R`)
2. **Add at least one asset** with a value:
   - Tap "Create Asset"
   - Enter a name
   - Tap "Set Value" on the asset
   - Enter a value (e.g., 1000)
   - Save
3. **Go back to home screen** - This triggers data write
4. **Wait a few seconds** for data to sync

### Step 3: Refresh Widget
1. **Remove the widget** from home screen (long press, tap "-")
2. **Add it back** (long press, tap "+", search "Asseta")
3. Widget should now show your net worth

## Debugging with Console Logs

The app and widget now print debug messages. Check Xcode console:

### When App Writes Data:
Look for: `✅ WidgetDataHelper: Saved net worth data - Current: X, Historical count: Y`

### When Widget Loads Data:
Look for: `✅ WidgetDataHelper: Loaded net worth data - Current: X, Historical count: Y`

### If App Groups Not Working:
Look for: `⚠️ WidgetDataHelper: App Group 'group.com.asseta.widget' not accessible`

## Common Issues

### Issue: Widget shows "Add assets in app"
**Cause**: No data has been written yet
**Fix**: 
- Open the app
- Add an asset with a value
- Go back to home screen
- Remove and re-add widget

### Issue: Widget shows "No history yet" but has current value
**Cause**: You have current net worth but no historical data points
**Fix**: This is normal! Add more values over time to see the chart

### Issue: Widget always shows "No data available"
**Cause**: App Groups not configured or data not writing
**Fix**:
1. Check App Groups in both targets
2. Check console logs for errors
3. Make sure both targets have same development team
4. Clean build folder (`Cmd + Shift + K`) and rebuild

## Testing Checklist

- [ ] App Groups configured for both targets
- [ ] App has been run at least once
- [ ] At least one asset created with a value
- [ ] App has written data (check console logs)
- [ ] Widget removed and re-added after data written
- [ ] Widget shows current net worth (even if no chart)

## Expected Behavior

### First Time (No Data):
- Widget shows: "Add assets in app" or "No data available"
- This is normal until you add assets

### With Assets but No History:
- Widget shows: Current net worth value
- Shows: "No history yet" instead of chart
- This is normal until you have multiple data points

### With Historical Data:
- Widget shows: Current net worth
- Shows: Chart with trend line
- Shows: Percentage change if available

