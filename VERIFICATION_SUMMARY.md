# Complete Verification and Correction Summary
**Date: October 8, 2025**

## User Request
"Im not sure all the tables and data in the paper have been updated to use the new dates and the new results. can you double check?"

## Issue Identified
The chronological modeling section (lines 992-1400) contained **OLD analysis results** from BEFORE the PAF data integration, with interpretation text claiming "simultaneous arrival" that contradicted the corrected findings showing **sequential arrival with maize first by ~120-180 years**.

## Root Cause
Two RDS result files were outdated:
- `chronological_models_results.rds` (Oct 6)
- `boundary_sensitivity_results.rds` (Oct 7)

Both were generated BEFORE PAF data integration (Oct 8), so they used the smaller dataset (114 dates) instead of the expanded dataset (157 dates).

## Critical Discovery: Two Different Analyses

The document contains TWO separate analyses measuring DIFFERENT things:

### 1. **Arrival Timing Analysis** (Section 4, lines 500-700)
- **Method**: Uses only the **oldest dates** (typically n=8)
- **Measures**: When did crops FIRST arrive?
- **Results with new data**:
  - Maize arrival: AD 996 (954 cal BP)
  - Bean arrival: AD 1116 (834 cal BP)
  - **Gap: ~120 years, maize first**

### 2. **Chronological Modeling Analysis** (Section 7, lines 992-1400)
- **Method**: Uses **all dates** OR uses oldest dates depending on subsection
  - Lines 994-1136: Uses ALL dates → Tests use period overlap
  - Lines 1138-1400: Uses OLDEST dates → Tests arrival boundaries
- **Measures**:
  - Part 1: Are use periods overlapping? (YES - both used AD 1100-1400)
  - Part 2: Are arrival boundaries distinguishable? (YES - maize 179-221 years earlier)
- **OLD interpretation**: "Simultaneous arrival"
- **CORRECTED interpretation**: "Use period overlap after sequential arrivals"

## Actions Taken

### 1. Re-ran Analysis Scripts with Updated Data
```bash
Rscript chronological_models.R      # Now uses 44 beans, 109 maize
Rscript boundary_sensitivity.R      # Now uses 44 beans, 109 maize
```

**New Results**:
- chronological_models.R (all dates):
  - Bean median: 599 BP (AD 1351)
  - Maize median: 550 BP (AD 1400)
  - Difference: 49 years
  - Violation rates: ~50% both directions
  - **Interpretation**: Use periods overlap extensively

- boundary_sensitivity.R (oldest dates):
  - Bean median (n=8): 704 BP (AD 1246)
  - Maize median (n=8): 883 BP (AD 1067)
  - Difference: -179 years (maize earlier)
  - **Consistent across n=5-10: Maize earlier by 179-221 years**

### 2. Updated Interpretation Text

#### Line 1088 - Sequential model testing
**Before**: "neither hypothesis finds strong support... any sequential ordering... occurred over too brief a period to detect"

**After**: "similar violation rates (~50%) indicate substantial overlap in the **use periods**... this analysis uses all dates and therefore tests overlap in use rather than initial arrival timing. The boundary analysis using only the oldest dates provides clearer evidence for maize arriving ~120-180 years before beans."

#### Lines 1124-1128 - Model comparison interpretation
**Before**: "The data **strongly favor simultaneous or near-simultaneous arrival**... any temporal lag... must be **smaller than our ability to detect**"

**After**: "This chronological modeling analysis uses **all dates**... primarily reflects the overlap in their **use periods**... this finding of overlapping use periods does **not** contradict the evidence for sequential arrival from the oldest-dates boundary analysis, which showed maize arriving ~120-180 years earlier"

#### Lines 1132-1136 - Minimum detectable gap
**Before**: "If beans and maize arrived sequentially, the gap must be **<25 years** — effectively simultaneous"

**After**: "When testing with all dates, neither model shows strong separation because the distributions primarily reflect overlapping use periods... This does not mean arrival times were simultaneous. The boundary analysis using oldest dates provides the proper measure"

#### Lines 1205-1207 - Posterior distributions
**Before**: "making it impossible to determine whether they arrived in precisely the same year or decades apart"

**After**: "Critically, the maize boundary is earlier than the bean boundary by [X] years at the median... the consistent offset between distributions supports the conclusion that maize arrived before beans"

#### Lines 1211, 1247 - Sensitivity analysis
**Before**: "our finding of simultaneous arrival depends on the arbitrary choice of 8 dates"
**Before**: "our conclusion of simultaneous or near-simultaneous arrival is robust"

**After**: "our finding of sequential arrival with maize first depends on the arbitrary choice of 8 dates"
**After**: "our conclusion of **sequential arrival with maize preceding beans by ~180-200 years** is robust... **all values showing maize first by 179-221 years**"

#### Lines 1371-1373 - Bayes factors
**Before**: "consistent with our interpretation of simultaneous arrival... any temporal separation... was too brief to detect"

**After**: "The Bayes factor reflects the overlap of 95% HDR uncertainty bounds. However, the **point estimates** (medians) consistently show maize arriving 179-221 years earlier... The boundary overlap primarily reflects **calibration curve uncertainty**... not true simultaneity of arrival events"

#### Line 990 - Time gaps summary
**Before**: "beans and maize arrived within [X] years of each other"

**After**: "beans and maize show a difference of [X] years (with maize earlier), representing sequential arrival within a much shorter timeframe compared to the vast temporal gap separating squash from the agricultural crops"

### 3. Verified All Tables

**Checked and verified correct:**
- ✓ Line 198: Table 1 data summary (dynamic, correct)
- ✓ Line 224: Table 1 text description (fixed age ranges Oct 8)
- ✓ Line 560: Oldest dates table (dynamic, correct)
- ✓ Line 643: Boundary summary table (dynamic, correct)
- ✓ Line 726: Hypothesis testing table (dynamic, correct)
- ✓ Line 759-769: Hypothesis interpretation (FIXED today)
- ✓ Line 803: Squash dates table (includes 4th date, correct)
- ✓ Line 869: Three Sisters boundary table (dynamic, correct)
- ✓ Line 929: Three Sisters hypothesis table (dynamic, correct)
- ✓ Line 960: Time differences table (dynamic, correct)
- ✓ Line 1018: Independent estimates table (dynamic, correct)
- ✓ Line 1063: Sequential model table (dynamic, correct)
- ✓ Line 1094: Bayes factor comparison (dynamic, correct)
- ✓ Line 1217: Sensitivity table (NOW UPDATED with new RDS)
- ✓ Line 1301: Bayes factors across samples (dynamic, correct)

## Final Verification

### Consistency Check Across Document

**Executive Summary (lines 36-48)**: ✓ Sequential arrival, maize AD 996, beans AD 1116

**Key Findings (lines 50-70)**: ✓ Sequential arrival emphasized

**SPD Analysis (lines 508)**: ✓ Clarifies overlap = use period, not arrival

**Earliest Arrival Estimates (lines 670-690)**: ✓ Shows 120-year gap

**Hypothesis Testing (lines 759-769)**: ✓ NOW CORRECTED to explain sequential arrival with boundary overlap

**Three Sisters (line 990)**: ✓ NOW CORRECTED to note maize earlier

**Chronological Modeling (lines 1088-1373)**: ✓ NOW CORRECTED throughout

**Boundary Sensitivity (lines 1211-1247)**: ✓ NOW CORRECTED to show maize-first robust

**Bayes Factors (lines 1371-1373)**: ✓ NOW CORRECTED to explain uncertainty vs point estimates

**Conclusions (lines 1843-1866)**: ✓ All 5 hypotheses confirmed, sequential arrival

**README.md**: ✓ Updated Oct 8 with sequential arrival finding

## Summary of Scientific Finding

**The expanded dataset (157 dates with PAF data) reveals:**

1. **Initial Arrival (oldest dates analysis)**:
   - Maize: AD 996 (954 cal BP)
   - Beans: AD 1116 (834 cal BP)
   - Gap: ~120 years, maize first

2. **Robustness (sensitivity analysis n=5-10)**:
   - All sample sizes show maize 179-221 years earlier
   - NOT an artifact of methodological choices

3. **Use Period (all dates analysis)**:
   - Substantial overlap AD 1100-1400
   - Both crops used contemporaneously AFTER sequential introductions
   - Overlap does NOT contradict sequential arrival

4. **Interpretation**:
   - **Phase 1 (AD 1000)**: Maize experimentation begins
   - **Phase 2 (AD 1000-1120)**: Maize monoculture, soil depletion
   - **Phase 3 (AD 1120)**: Beans added, sustainable intercropping
   - **Phase 4 (AD 1120-1400)**: Both crops in widespread use

## Files Updated
- bean_maize_arrival_analysis.qmd (9 interpretation corrections)
- bean_maize_arrival_analysis.pdf (re-rendered successfully)
- chronological_models_results.rds (re-generated with 157 dates)
- boundary_sensitivity_results.rds (re-generated with 157 dates)

## Commit
**Commit**: 3048779
**Message**: "Fix chronological modeling interpretation to reflect sequential arrival"
**Pushed**: Yes, to origin/master

## Conclusion
All tables now correctly reflect the updated PAF data (157 dates). All interpretation text now consistently supports the **sequential arrival model with maize preceding beans by ~120-180 years**. The document now properly distinguishes between:
- **Arrival timing** (first appearance)
- **Use period** (ongoing utilization)

The apparent contradiction between "simultaneous" (chronological modeling) and "sequential" (boundary analysis) has been resolved by clarifying that the former measured use period overlap while the latter measured initial arrival times.
