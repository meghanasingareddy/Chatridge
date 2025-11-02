# File Opening Debug Guide

## Current Issue

Files uploaded from desktop can't be opened - getting 404 errors.

## How File Paths Work

### Upload Process:
1. **File uploaded**: "Sequence Diagrams, collaboration Diagrams (1).pptx"
2. **ESP32 sanitizes**: "/Sequence Diagrams_ collaboration Diagrams _1_.pptx" (commas/parentheses → underscores)
3. **ESP32 stores**: File saved to SPIFFS with sanitized name
4. **ESP32 returns**: `{"url": "/Sequence Diagrams_ collaboration Diagrams _1_.pptx"}`

### Download Process:
1. **Flutter receives**: attachmentUrl = "/Sequence Diagrams_ collaboration Diagrams _1_.pptx"
2. **Flutter URL-encodes**: "/Sequence%20Diagrams_%20collaboration%20Diagrams%20_1_.pptx"
3. **ESP32 receives**: URL-decodes back to "/Sequence Diagrams_ collaboration Diagrams _1_.pptx"
4. **ESP32 sanitizes**: Same (already sanitized)
5. **ESP32 finds file**: Should match ✓

## Debugging Steps

### 1. Check What's Actually Stored

**In Flutter App (Debug Console):**
When you try to open a file, look for these log messages:
```
Opening document: original URL=/Sequence Diagrams_ collaboration Diagrams _1_.pptx, resolved=/Sequence Diagrams_ collaboration Diagrams _1_.pptx
Downloading file to open: http://192.168.4.1/Sequence%20Diagrams_%20collaboration%20Diagrams%20_1_.pptx -> ...
Original path: /Sequence Diagrams_ collaboration Diagrams _1_.pptx, Encoded path: /Sequence%20Diagrams_%20collaboration%20Diagrams%20_1_.pptx
```

**In ESP32 Serial Monitor:**
```
File request (raw): /Sequence%20Diagrams_%20collaboration%20Diagrams%20_1_.pptx
File request (decoded): /Sequence Diagrams_ collaboration Diagrams _1_.pptx
File request (sanitized): /Sequence Diagrams_ collaboration Diagrams _1_.pptx
Available files in SPIFFS:
  - /Sequence Diagrams_ collaboration Diagrams _1_.pptx
```

### 2. Verify File Upload

Check ESP32 Serial Monitor when file is uploaded:
```
Upload START: Original=Sequence Diagrams, collaboration Diagrams (1).pptx, Sanitized=/Sequence Diagrams_ collaboration Diagrams _1_.pptx
File opened successfully: /Sequence Diagrams_ collaboration Diagrams _1_.pptx
Upload END: /Sequence Diagrams_ collaboration Diagrams _1_.pptx (12345 bytes)
File verified: 12345 bytes
```

### 3. Check Message JSON

When you fetch messages, check what attachmentUrl contains:
```json
{
  "attachment_url": "/Sequence Diagrams_ collaboration Diagrams _1_.pptx",
  "attachment_name": "Sequence Diagrams_ collaboration Diagrams _1_.pptx"
}
```

## Common Issues

### Issue 1: Path Mismatch
**Symptom**: ESP32 shows file exists but can't find it
**Cause**: Filename in message doesn't match actual file on SPIFFS
**Fix**: Check Serial Monitor to see both requested path and available files

### Issue 2: URL Encoding
**Symptom**: 404 with encoded characters
**Cause**: URL encoding/decoding mismatch
**Fix**: Ensure ESP32 URL-decodes before sanitizing

### Issue 3: Spaces in Filename
**Symptom**: 404 when filename has spaces
**Cause**: Spaces not handled correctly
**Fix**: Both Flutter and ESP32 should handle URL encoding/decoding

## Testing

1. **Upload a test file**: "test file (1).pdf"
2. **Check Serial Monitor**: Verify upload success and filename
3. **Try to open file**: Check Flutter debug console
4. **Check ESP32 Serial**: See what path is requested
5. **Compare**: Requested path vs available files

## Expected Behavior

- ✅ Files with spaces work
- ✅ Files with commas/parentheses are sanitized
- ✅ URL encoding/decoding works correctly
- ✅ Path matching finds the file

If still not working, share the Serial Monitor output and Flutter debug logs!


