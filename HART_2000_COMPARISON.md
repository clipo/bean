# Analysis: Hart (2000) vs. Our Bayesian Analysis
## Does Our Analysis Falsify Hart's Claims?

---

## Hart (2000) Key Findings

### The Roundtop Revelation

**Original claim (Ritchie 1973):**
- Feature 35 contained maize, beans, and squash together
- Dated to AD 1070±60 based on pottery association
- Considered "earliest evidence for agriculture in the Northeast"

**Hart's NEW AMS dates from Roundtop Feature 35:**
- Bean: cal AD 1300
- Maize kernel 1: cal AD 1300
- Maize kernel 2: "a few centuries younger"
- Twig: cal AD 1300

**Critical discovery:**
- Ritchie's AD 1070 date was from **Feature 30** (different pit!)
- Feature 35 pottery was actually **Late Owasco** (Owasco Corded Collar), not Early Owasco
- Ritchie's own lab notes identified it correctly as late Owasco
- **Published interpretation did not match the actual collections**

### Regional Bean Dating Program

Hart (2000) then dated beans from other sites with purported early contexts:

**Sites dated:**
1. **Skitchewaug** (Vermont): 3 bean samples → cal AD 1275-1368
2. **Thomas Luckey** (NY): 1 bean sample → within same range
3. **Gnagey** (Pennsylvania): 2 bean samples → cal AD 1275-1368
4. **Bald Eagle** (Pennsylvania): Samples reidentified - NO BEANS present!

### Hart's (2000) Conclusions

> "beans do not become archaeologically visible in the Northeast until right around A.D. 1300"

> "maize-beans-squash intercropping did not become established in the Northeast until about that same time, some 250 to 300 years later than has been generally accepted"

**Implication:** The maize-beans-squash agricultural triad is a **late arrival** (~AD 1300), not early (~AD 1000-1100)

---

## Our Dataset vs. Hart (2000)

### Do We Have Hart's Dates?

Checking our `radiocarbon_dates.csv`:

**Roundtop ✓**
- Roundtop_F35, bean, AA-23106, 658±48 BP
- Roundtop_F35, maize, AA-21979, 675±55 BP
- Roundtop_post_mold, bean, AA-26540, 315±45 BP

**Skitchewaug ✓**
- Skitchewaug_F32, bean, AA-29119, 670±45 BP
- Skitchewaug_F5ab, bean, AA-29120, 765±50 BP
- Skitchewaug_F46, bean, AA-29121, 600±50 BP

**Thomas Luckey ✓**
- Thomas_Luckey_F78, bean, AA-29122, 695±45 BP

**Gnagey ✓**
- Gnagey_F30, bean, AA-29117, 610±55 BP
- Gnagey_F13D, bean, AA-29118, 635±45 BP

**Answer: YES** - All of Hart's (2000) dates are in our dataset!

Hart (2000) was the preliminary study that became Hart et al. (2002), which added MORE sites and dates (Table 2 with 31 additional dates).

---

## Hart's Claim About Beans vs. Squash

### What Does Hart Actually Claim?

**Careful reading reveals:**

Hart (2000) does **NOT specifically claim beans are later than squash**. His argument is:

1. **Beans arrive later than previously thought** (~AD 1300, not ~AD 1000-1100)
2. **The maize-beans-squash TRIAD** doesn't co-occur before AD 1300
3. This revises the timeline of **agricultural intensification**

### Evidence for Squash Timing

Hart (2000, page 13) cites:
> "Hart and Asch Sidell (1997) Additional Evidence for Early Cucurbit Use in the Northern Eastern Woodlands..."

This suggests **cucurbits (squash) may indeed be earlier** than beans, but Hart (2000) doesn't make this comparison explicitly. His focus is on correcting the **bean chronology** specifically.

**The claim "beans are later than squash"** appears to be an **inference** rather than Hart's explicit argument in this paper.

---

## Does Our Analysis Falsify Hart's Claim?

### Our Bayesian Results

**BEANS:**
- Overall 95% HDR: 542-901 cal BP (1049-1408 cal AD)
- **Main probability mass: 557-790 cal BP (1160-1393 cal AD)**
- SPD peak: 653 cal BP (**1297 cal AD**)

**MAIZE:**
- Overall 95% HDR: 508-899 cal BP (1051-1442 cal AD)
- **Main probability mass: 581-795 cal BP (1155-1369 cal AD)**
- SPD peak: 667 cal BP (**1283 cal AD**)

### Comparison to Hart (2000)

| Aspect | Hart (2000) | Our Analysis | Agreement? |
|--------|-------------|--------------|------------|
| **Bean arrival** | ~AD 1300 | **1160-1393 AD** (peak 1297 AD) | ✓ **YES** |
| **Method** | Direct AMS dating | Bayesian boundary estimation | More rigorous |
| **Sample size** | ~10 bean dates | **36 bean dates** | Much larger |
| **Conclusion** | Late arrival | Late arrival | **SAME** |

### Answer: **NO, We Do NOT Falsify Hart's Claim**

Our analysis **SUPPORTS and REFINES** Hart's findings:

✓ **Confirms** beans arrive around AD 1200-1400 (not AD 1000-1100)
✓ **Confirms** peak activity in late 13th century (AD 1297)
✓ **Adds precision** with Bayesian boundary estimates
✓ **Expands evidence** with 36 beans vs. his initial ~10

### New Finding From Our Analysis

**Beans and maize arrive SIMULTANEOUSLY:**
- Bean earliest: 1160-1393 AD
- Maize earliest: 1155-1369 AD
- **95% credible intervals almost identical**
- **No statistical evidence for sequential arrival**

This is **complementary** to Hart, not contradictory. Hart showed beans are later than thought; we show beans and maize arrive together.

---

## The Squash Question

### What About Squash?

**Critical limitation:** Our analysis does **NOT include squash dates**!

We analyzed:
- ✓ 36 bean dates
- ✓ 14 maize dates
- ❌ 0 squash dates

**Cannot test** whether beans are later than squash without squash data!

### What We'd Need to Test This

To properly evaluate "beans later than squash":

1. **Collect squash dates** from the same region/time period
2. **Create squash boundary model** (same methodology)
3. **Compare posteriors:**
   - P(bean_arrival > squash_arrival)
   - Calculate Bayes factor
   - Test sequential vs. simultaneous models

**Hypothesis to test:**
- H1: Squash → Maize → Beans (sequential)
- H2: Squash → (Maize + Beans) (squash first, then both together)
- H3: All simultaneous

### Literature Context

Hart & Asch Sidell (1997) dated **Cucurbita** from:
- Sites in Northern Eastern Woodlands
- Some contexts dated to **pre-AD 1300**

If cucurbits ARE earlier (e.g., AD 800-1000), then:
- Squash: AD 800-1000
- Beans + Maize: AD 1200-1400
- **Sequential adoption pattern**

This would support **NOT falsify** a "squash first" model.

---

## Implications for Agricultural Evolution

### Hart's Model (Implicit)

```
Early Owasco           Late Owasco          Iroquoian
AD 1000-1100    →    AD 1200-1300    →    AD 1300-1600
   Squash?           Beans + Maize         Full triad
```

### Our Bayesian Model

```
                    Late Owasco          Iroquoian
                  AD 1150-1400      →   AD 1300-1600
              Beans + Maize (together)   Intensification
                   Squash ???
```

### Key Insights

1. **Confirmed:** Late arrival of beans (~AD 1300)
2. **New:** Beans and maize arrive simultaneously
3. **Unknown:** Squash timing relative to beans/maize
4. **Implication:** Agricultural "package" may not be a package - crops adopted at different times

---

## Recommendations for Future Analysis

### To Fully Address the Squash Question

1. **Compile squash radiocarbon dates**
   - Search Hart & Asch Sidell (1997)
   - Search other cucurbit literature
   - Focus on **direct AMS dates** only

2. **Add squash to Bayesian model**
   - Create three-way boundary comparison
   - Test sequential vs. simultaneous hypotheses
   - Calculate Bayes factors for model comparison

3. **Spatial analysis**
   - Map spread patterns
   - Test for directional dispersal
   - Identify potential source regions

4. **Test alternative models**
   ```
   Model 1: Squash → Maize → Beans (fully sequential)
   Model 2: Squash → (Maize + Beans) (squash first)
   Model 3: (Squash + Maize) → Beans (beans last)
   Model 4: All simultaneous
   ```

---

## Conclusions

### Summary of Findings

**Question 1: Does Hart (2000) add new dates we need?**
- ✓ **No** - all Hart (2000) dates already in our dataset
- Hart (2000) was preliminary study leading to Hart et al. (2002)
- We have the complete dataset (50 crop dates)

**Question 2: Does Hart argue beans are later than squash?**
- **Not explicitly** in the 2000 paper
- He argues beans are later than **previously thought**
- He cites evidence for early cucurbits but doesn't make formal comparison
- This may be an **inference** from multiple papers

**Question 3: Do our analyses falsify his claim?**
- ✓ **NO** - we **SUPPORT** Hart's findings
- Both show bean arrival ~AD 1200-1400 (not AD 1000-1100)
- Our analysis adds precision and larger sample
- Our **new contribution**: beans and maize arrive together

**Question 4: What about squash?**
- ❌ **Cannot test** - no squash dates in our dataset
- Need to compile squash dates for proper comparison
- Recommended as **future analysis**

### Final Assessment

Hart (2000) fundamentally **changed our understanding** of Northeast agricultural chronology by showing:
1. Direct dating reveals later bean arrival
2. Published interpretations can be wrong (Roundtop case study)
3. Collections are essential for re-evaluation

Our Bayesian analysis **validates and extends** Hart's work by:
1. Using larger sample (36 beans vs. ~10)
2. Applying rigorous Bayesian methods
3. Demonstrating simultaneous bean and maize arrival
4. Quantifying uncertainty properly

**Neither analysis falsifies the other - they are complementary!**

---

**Files referenced:**
- Hart, J.P. 2000. North American Archaeologist 21(1):7-17
- Hart, J.P. et al. 2002. Antiquity 76:377-385
- Our analysis: `radiocarbon_dates.csv`, `bayesian_model_comparison.R`
X`