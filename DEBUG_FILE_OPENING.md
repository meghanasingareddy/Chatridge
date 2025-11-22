# How to Debug File Opening Issues

## Step-by-Step Instructions

### Step 1: Get the Exact Error Details
When you try to open the file and it fails, **copy the EXACT error message** from the popup. The new code shows:
- Original URL from message
- Resolved path
- All attempted paths
- Error code

### Step 2: Check ESP32 Serial Monitor
1. Open Arduino IDE or your serial monitor
2. Connect to ESP32 Serial Monitor (usually 115200 baud)
3. Try to open the file in the app
4. Look at the Serial Monitor output. You should see:
   ```
   File request (raw): /path/to/file
   File request (decoded): /path/to/file  
   File request (sanitized): /sanitized/path
   Available files in SPIFFS:
     - /file1.pptx
     - /file2.pdf
   ```

### Step 3: Compare What ESP32 Has vs What App Requests
- **What files does ESP32 actually have?** (from Serial Monitor)
- **What path is the app requesting?** (from the error popup)

### Step 4: Quick Fix Options

#### Option A: Re-upload the File
The file might have been uploaded with an old version of the code. Try:
1. Delete the old message/file
2. Re-upload the same file
3. Try opening again

#### Option B: Check ESP32 Code Version
Make sure your ESP32 is running the **latest code** that has:
- `sanitizeFilename()` function
- URL decoding in `handleFileGet()`
- Proper file path matching

#### Option C: Manual Test
1. Open a web browser
2. Go to: `http://192.168.4.1/path/to/your/file.pptx`
   (Replace with the exact path from the error message)
3. Does it download? If YES → App issue. If NO → ESP32 issue.

### Step 5: Share This Information
When reporting the issue, please share:
1. **Error popup text** (all of it)
2. **ESP32 Serial Monitor output** (the file request part)
3. **List of files ESP32 has** (from Serial Monitor)
4. **The exact filename** you're trying to open

### What the Code Does Now

The app now:
1. ✅ Tries sanitized filename (what ESP32 should have)
2. ✅ Tries original unsanitized filename (for old messages)
3. ✅ Shows detailed error with all attempted paths
4. ✅ Opens files directly on Windows using `start` command

If it's still failing, the issue is likely:
- ESP32 doesn't have the file at that path
- ESP32 code version mismatch
- Filename mismatch between what's stored and what's requested


