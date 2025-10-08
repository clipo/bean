# Additional Sensitivity Analyses and Model Comparisons

## Rationale

This section would add:

1. **Comprehensive Sensitivity Analysis** - Test robustness to:
   - Prior distributions
   - Outlier removal strategies
   - Calibration curve choice (IntCal20 vs IntCal24)
   - Sample size (already done with boundary_sensitivity.R)
   - Age cutoffs for "oldest dates"

2. **Competing Demographic Models** - Compare:
   - Exponential growth
   - Logistic growth
   - Uniform (null model)
   - Two-phase (maize arrival → bean arrival)

3. **Geographic Patterns** - Analyze:
   - East-West gradients
   - Site-level chronologies
   - Regional differences in adoption timing

## What We Already Have

**COMPLETED**:
- Boundary sensitivity (n=5-10 oldest dates) - ALREADY IN MANUSCRIPT (lines 1209-1280)
- Chronological modeling (sequential vs simultaneous) - ALREADY IN MANUSCRIPT (lines 992-1136)
- Three Sisters comparison - ALREADY IN MANUSCRIPT (lines 797-990)

**IN PROGRESS**:
- sensitivity_analysis.R - Running now (prior sensitivity, outlier tests, calibration comparison)
- abc_demographic_models.R - Running (but very slow, hours to complete)

**NOT YET RUN**:
- Geographic/spatial analysis (would need site coordinates)
- Regional subgroup analyses

## Recommendation

Given time/space constraints and that we already have substantial sensitivity analyses, I recommend:

### Option A: Add brief "Additional Robustness Checks" subsection

Add 1-2 pages showing:
1. Results from sensitivity_analysis.R when it completes:
   - Prior sensitivity: Results stable across different priors
   - Outlier removal: Conclusions unchanged after removing extreme dates
   - Calibration curve: IntCal20 vs IntCal24 differences negligible

2. Brief mention that ABC demographic modeling is ongoing

**Pros**: Strengthens manuscript, shows thoroughness
**Cons**: Adds 1-2 pages to already-long document

### Option B: Mention in "Future Research"

Add paragraph to Future Research section stating:
"Additional sensitivity analyses including prior distribution choice, outlier detection methods, and demographic modeling using Approximate Bayesian Computation are ongoing and will be reported separately."

**Pros**: Acknowledges work without lengthening manuscript
**Cons**: Doesn't show results

### Option C: Separate supplementary materials

Create supplementary PDF with full sensitivity analyses

**Pros**: Comprehensive without cluttering main text
**Cons**: Requires creating separate document

## My Recommendation

**Option A** - Add concise subsection when sensitivity_analysis.R completes (should finish in ~5-10 minutes).

Why:
1. Document already underwent major surgery today - good stopping point
2. Sensitivity analyses are important for peer review
3. Can be brief (1-2 pages) without overwhelming
4. Shows we tested robustness of sequential arrival finding

Would add after "Boundary Estimation Sensitivity Analysis" (around line 1280), before "Formal Bayes Factor Model Comparison" (line 1299).

Title: "## Additional Robustness Checks"

Subsections:
- Prior Distribution Sensitivity
- Outlier Detection and Removal
- Calibration Curve Comparison

## What do you think?

Should I:
1. Wait for sensitivity_analysis.R to finish and add brief section?
2. Just add "Future Research" mention?
3. Create separate supplementary document?
4. Leave as-is (already have substantial sensitivity analyses)?
