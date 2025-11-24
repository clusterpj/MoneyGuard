# MoneyGuard - Strategic Pivot: OCR + Manual Entry

**Date**: November 24, 2025  
**Decision**: Replace notification parsing with OCR receipt scanning + quick manual entry  
**Status**: ✅ Approved - All docs updated

---

## Why We Pivoted

### Problems with Notification Parsing:
1. **Permission Hell** - NotificationListenerService requires special system permission that many users deny
2. **Fragile** - Bank app updates break parsers constantly
3. **Device Compatibility** - Different Android versions handle notifications differently
4. **Maintenance Nightmare** - Need to maintain parsers for every bank, every app version
5. **Time to Market** - Would take weeks just to test across all banks and devices
6. **User Trust** - Many users uncomfortable giving notification access

### Why OCR + Manual Is Better:
1. ✅ **No Permissions** - Just camera (users expect this)
2. ✅ **Universal** - Works for ALL banks, ALL payment methods (cash, card, transfer)
3. ✅ **Reliable** - Google ML Kit is battle-tested, works offline
4. ✅ **Fast to Build** - 2 days vs 2 weeks
5. ✅ **Better UX** - Users already take photos of receipts
6. ✅ **Fallback Included** - Quick manual entry takes 5 seconds

---

## The New User Flow

### Primary Flow: OCR (70% of expenses)
```
User makes purchase
    ↓
Takes photo of receipt
    ↓
OCR extracts amount + merchant (2 seconds)
    ↓
Confirmation screen (edit if needed)
    ↓
Saves → Intervention check
```

**Time**: 10-15 seconds total  
**Accuracy**: 80-90% (Google ML Kit benchmark)  
**User Effort**: 1 photo + 1 tap

### Secondary Flow: Quick Manual (25% of expenses)
```
User opens app
    ↓
Taps FAB → "Quick Add"
    ↓
Taps amount button (50, 100, 200...) or types
    ↓
Taps category
    ↓
Saves → Intervention check
```

**Time**: 5-8 seconds total  
**Accuracy**: 100% (user input)  
**User Effort**: 3 taps

### Future Flow: Voice (5%, post-MVP)
```
User says "Gasté 1500 en Uber"
    ↓
Speech-to-text
    ↓
Parse amount + category
    ↓
Saves → Intervention check
```

---

## What Changed in the Docs

### SRS (Technical Spec)
- ✅ Removed: NotificationListenerService (~500 lines)
- ✅ Removed: Bank app package detection
- ✅ Removed: Notification parsing patterns
- ✅ Added: OCR receipt scanning implementation
- ✅ Added: Quick manual entry UI
- ✅ Added: Confirmation screen flow
- ✅ Updated: Database schema (OCR fields)

### MVP Plan
- ✅ Week 2 now focuses on OCR + manual entry (not notification parsing)
- ✅ Removed dependency on collecting bank notification samples
- ✅ Added OCR tips and best practices for users
- ✅ Faster path to beta (no permission complexity)

### PRD (Product Requirements)
- ✅ Updated "Zero-Click Ingestion" to "Receipt Scanning"
- ✅ Kept intervention engine (unchanged)
- ✅ Kept AI personality system (unchanged)

---

## Technical Implementation

### Google ML Kit Text Recognition

**Why ML Kit:**
- Free (no API costs)
- Offline (on-device processing)
- Fast (<2 seconds per receipt)
- Accurate (80-90% for printed text)
- Well-maintained by Google

**Flutter Integration:**
```yaml
dependencies:
  google_mlkit_text_recognition: ^0.11.0
  image_picker: ^1.0.5
```

**OCR Parsing Strategy:**
```dart
// 1. Extract amount - try multiple patterns
- "TOTAL: RD$1,500.00"
- "RD$1,500.00"
- Last line with decimals

// 2. Extract merchant - usually first line
- Clean up "FACTURA", "TICKET", "RECIBO"
- Use first non-empty line

// 3. Extract date - if present
- DD/MM/YYYY format
- Default to today if not found
```

**Confidence Scoring:**
```dart
double confidence = 0.0;
if (amount > 0) confidence += 0.6;
if (merchant.length > 3) confidence += 0.3;
if (amount < 100,000) confidence += 0.1; // Reasonable
return confidence; // 0.0 to 1.0
```

---

## User Experience Improvements

### Before (Notification Parsing):
```
User makes purchase
    ↓
Notification arrives (if bank sends one)
    ↓
Parser extracts data (if pattern matches)
    ↓
Auto-logs (if everything worked)
    ↓
User sees expense (maybe)
```

**Problems:**
- No control
- No visibility
- No trust
- Fails silently

### After (OCR + Manual):
```
User makes purchase
    ↓
User CHOOSES to log (takes photo or quick add)
    ↓
User SEES extracted data
    ↓
User CONFIRMS or edits
    ↓
Expense logged with confidence
```

**Benefits:**
- Full control
- Full visibility
- Builds trust
- Never fails silently

---

## MVP Benefits

### Faster to Market
| Task | Notification | OCR | Time Saved |
|------|--------------|-----|------------|
| Collect samples | 1 week | 0 days | 7 days |
| Build parsers | 3 days | 0 days | 3 days |
| Test permissions | 2 days | 0 days | 2 days |
| Debug issues | 3 days | 1 day | 2 days |
| **Total** | **~15 days** | **~1 day** | **14 days** |

### Lower Risk
- ❌ No permission rejection risk
- ❌ No bank app update breaking things
- ❌ No device compatibility issues
- ❌ No maintenance burden

### Better Product
- ✅ Works for cash purchases (no bank notification)
- ✅ Works for all payment methods
- ✅ User has control and visibility
- ✅ Can retroactively log old expenses

---

## Success Metrics (Updated)

### Week 2 Goals:
- [ ] OCR extracts amount correctly (80%+ accuracy)
- [ ] Confirmation screen allows easy editing
- [ ] Quick manual entry takes <10 seconds
- [ ] Users prefer OCR over manual entry

### Beta Goals (Week 4):
- [ ] 70% of expenses logged via OCR
- [ ] 25% via quick manual entry
- [ ] 5% via voice (if implemented)
- [ ] <3% require major OCR corrections

### Post-MVP Improvements:
- [ ] Train custom ML model on Dominican receipts
- [ ] Add batch OCR (multiple receipts at once)
- [ ] Receipt organization/search
- [ ] Export receipts to PDF

---

## What We're NOT Losing

The core value proposition remains identical:

1. ✅ **Intervention Engine** - Still the main feature
2. ✅ **3-Gate System** - Still minimizes LLM costs
3. ✅ **AI Personality** - Still "Drill Sergeant" mode
4. ✅ **Offline-First** - Still works without internet
5. ✅ **Budget Management** - Still tracks spending vs budget

**We're only changing HOW expenses get logged, not WHY the app exists.**

---

## Next Steps

### Immediate (This Week):
1. ✅ Update all documentation (DONE)
2. ✅ Finalize MVP plan (DONE)
3. 🔨 Start backend development (Week 1)
4. 🔨 Test Google ML Kit OCR accuracy

### Week 2:
1. Integrate Google ML Kit in Flutter
2. Build OCR parsing logic
3. Create confirmation UI
4. Test with real Dominican receipts

### Week 3-4:
1. Connect intervention system
2. Polish UX
3. Beta launch

---

## Decision Rationale

**The Question:** Why did we even consider notification parsing?

**The Answer:** It seemed like the "magic" feature - zero user effort. But in reality:
- It's not magic, it's fragile
- Users don't trust it
- It doesn't work for cash
- It takes weeks to build right

**The Better Question:** What do users actually want?

**The Real Answer:** 
- Confidence that their expenses are tracked
- Control over what gets logged
- Fast way to log without typing everything
- AI that stops them from overspending

**OCR + Manual delivers all of that, plus:**
- Ships in 1/3 the time
- Works more reliably
- Covers more use cases
- Requires no special permissions

---

## Comparison Matrix

| Feature | Notification | OCR + Manual | Winner |
|---------|--------------|--------------|--------|
| Time to Build | 2 weeks | 3 days | **OCR** |
| Permissions Needed | Special | Standard | **OCR** |
| Works for Cash | ❌ | ✅ | **OCR** |
| User Control | Low | High | **OCR** |
| Reliability | 70% | 90% | **OCR** |
| Maintenance | High | Low | **OCR** |
| User Trust | Medium | High | **OCR** |
| Bank Dependency | Total | None | **OCR** |

**Result: OCR + Manual wins 8/8 categories**

---

## Lessons Learned

1. **"Magical" features often hide complexity** - What seems like zero-click is actually high-risk
2. **User control > Automation** - People want to see what's happening
3. **Boring technology wins** - OCR is proven, notification parsing is custom
4. **Scope management is critical** - We almost wasted 2 weeks on the wrong thing

---

## Conclusion

This pivot makes MoneyGuard:
- ✅ Faster to ship
- ✅ More reliable
- ✅ More flexible
- ✅ More trustworthy
- ✅ Easier to maintain

**And it still delivers the core value:** An AI that stops you from overspending.

The intervention engine is the killer feature, not the expense logging method.

---

**Status**: Ready to build 🚀

**Next Action**: Start Week 1 backend development
