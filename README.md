# 🏏 IPL Player Performance & Auction Value Dashboard

An end-to-end data analytics project analyzing IPL player performance across 15 seasons (2008–2022) and benchmarking it against auction prices to identify **overpriced** and **undervalued** players.

---

## 📌 Project Objective

IPL auctions involve teams spending crores on players. This project builds a custom **Performance Score model** that combines batting and bowling stats, then compares it against actual auction prices paid to classify every auctioned player as:

- 🔴 **Overpriced** — high price, low performance
- 🟢 **Underpaid Gem** — low price, high performance
- 🟠 **Good Value** — reasonable price for output
- 🔵 **Fair Price** — market-rate purchase

---

## 🛠️ Tools & Technologies

**Microsoft Excel** | Data cleaning, null handling, column standardization |
**MySQL (Workbench)** | Database schema, SQL queries, performance aggregations |
**Python (Pandas, Seaborn, Matplotlib, Scikit-learn)** | EDA, feature engineering, normalization, visualizations |
**Tableau Public** | Interactive dashboard — 4 charts, filters, reference lines |

---

## 📁 Project Structure

```
IPL-Player-Performance-Auction-Dashboard/
│
├── data/
│   ├── raw/
│   │   ├── IPL_Matches_2008_2022.csv        # 950 matches, 20 columns
│   │   ├── IPL_Ball_by_Ball_2008_2022.csv   # 225,954 deliveries, 17 columns
│   │   └── IPLPlayerAuctionData.csv          # 970 auction records, 6 columns
│   │
│   └── clean/
│       ├── Matches_Clean.csv                 # Excel cleaned matches data
│       ├── Ball_by_Ball_Clean.csv            # Excel cleaned ball by ball data
│       ├── Auction_Clean.csv                 # Excel cleaned auction data
│       ├── ipl_master.csv                    # Final merged dataset (543 players)
│       ├── ipl_top_batters.csv               # Top 20 run scorers
│       ├── ipl_top_bowlers.csv               # Top 20 wicket takers
│       └── ipl_season_summary.csv            # Season-wise run trends
│
├── sql/
│   └── ipl_analysis.sql                      # MySQL schema + 6 analysis queries
│
├── notebooks/
│   └── ipl_eda.ipynb                         # Python EDA notebook (16 cells)
│
├── dashboard/
│   └── IPL_Analysis_Dashboard.twb            # Tableau workbook
│
├── visualizations/
│   ├── top_run_scorers.png
│   ├── top_wicket_takers.png
│   ├── price_vs_performance.png
│   └── value_distribution.png
│
└── README.md
```

---

## 📊 Dataset Overview

| Dataset | Source | Rows | Description |
|---|---|---|---|
| Ball by Ball | Kaggle | 225,954 | Every delivery bowled across 15 IPL seasons |
| Matches | Kaggle | 950 | Match-level data — teams, venue, toss, result |
| Auction | Kaggle | 970 | Player auction prices from 2013–2022 |

---

## 🔄 Project Workflow

```
Raw CSVs → Excel Cleaning → MySQL Database → Python EDA → Tableau Dashboard
```

### Phase 1 — Excel Cleaning
- Removed nulls and duplicate rows
- Standardized player names and team names
- Normalized `Season` column (handled `2020/21` format)
- Replaced `NA` string values in `Margin` and `Season` columns
- Saved clean files as UTF-8 CSV for MySQL import

### Phase 2 — SQL Database & Queries
- Created `ipl_analysis` database with 3 tables: `matches`, `ball_by_ball`, `auction`
- Imported data using `LOAD DATA INFILE` (225,954 rows in under 30 seconds)
- Wrote 6 analysis queries:
  - Top run scorers & wicket takers
  - Strike rate per batter (min 200 balls faced)
  - Economy rate per bowler (min 200 legal balls)
  - Average auction spend per team
  - Season-wise total and average runs
  - Performance Score vs Auction Value classification

### Phase 3 — Python EDA & Feature Engineering
- Loaded all 3 MySQL tables into Pandas via SQLAlchemy
- Calculated batting stats (runs, strike rate) filtering out wide deliveries
- Calculated bowling stats (wickets, economy rate) filtering out wides and no-balls
- Applied **Min-Max Normalization** to scale runs, strike rate and wickets to 0–100 range
- Engineered **Performance Score**:

```
Performance Score = (Runs_Norm × 0.4) + (Strike_Rate_Norm × 0.3) + (Wickets_Norm × 0.3)
```

- Classified 543 auctioned players into 4 value categories
- Generated 4 visualizations saved as PNG

### Phase 4 — Tableau Dashboard
- Built 4 interactive sheets connected to Python-exported CSVs
- Added average reference lines to scatter plot creating 4 value quadrants
- Published to Tableau Public

---

## 🧮 Performance Score Model

### Formula
```
Performance Score = (Runs_Normalized × 0.4) + (Strike_Rate_Normalized × 0.3) + (Wickets_Normalized × 0.3)
```

### Why these weights?
| Stat | Weight | Reasoning |
|---|---|---|
| Runs | 0.4 | Batting output is the primary match-winning factor in T20 |
| Strike Rate | 0.3 | Scoring speed is critical in IPL — a slow 50 can hurt the team |
| Wickets | 0.3 | Wickets are valuable but bowlers are generally priced lower at auctions |

### Why normalization?
Raw runs (thousands) vs raw wickets (tens) are on completely different scales. Without normalization, the formula would always favor batters. Min-Max scaling brings all 3 stats to a 0–100 range before applying weights — making the comparison fair across all player roles.

---

## 🔍 Key Insights

1. **Virat Kohli leads all-time run scorers** with 6,634 runs across 15 seasons, followed by Shikhar Dhawan (6,244) and David Warner (5,883)

2. **DJ Bravo is the all-time leading wicket taker** with 183 wickets, followed by SL Malinga (170) and YS Chahal (166)

3. **Kyle Jamieson & Benjamin Stokes were the most overpriced buys** — paid ₹15 Cr+ but had near-zero performance scores due to limited IPL appearances

4. **Shubman Gill was the biggest underpaid gem** — bought for just ₹1.8 Cr in 2018 but accumulated 1,900 runs with a 125 SR, long before becoming a superstar

5. **RCB spent the most overall** (₹270 Cr across 115 players) yet never won an IPL title — highest total spend, lowest return on investment

6. **Mumbai Indians were the smartest spenders** — lowest avg price paid (₹1.75 Cr) yet most IPL titles, proving smart retention > big auction splurges

7. **IPL scoring has trended upward** — avg runs per match rose from 309 in 2008 to 329 in 2022, reflecting the evolution of T20 batting

8. **2009 was the lowest-scoring season** (286.89 avg) — played in South Africa due to Indian elections, with slower pitches suppressing run rates

9. **2018 recorded the highest avg runs per match** (331.68) — peak of the aggressive T20 batting era

10. **39 out of 543 auctioned players (7.2%) were classified as Overpriced** — teams consistently overpay for overseas pace bowlers with limited IPL track records

---

## 📈 Tableau Dashboard

🔗 [View Live Dashboard on Tableau Public](#) ← https://public.tableau.com/views/IPLAnalysisDashboard_17815158666120/IPLDASHBOARD?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link

**Dashboard contains:**
- Top 10 IPL Run Scorers (2008–2022)
- Top 10 IPL Wicket Takers (2008–2022)
- Player Value Analysis — Price vs Performance scatter plot with quadrants
- Season-wise Scoring Trend (2008–2022)

---

## ⚠️ Limitations & Future Scope

- Auction data only covers 2013–2022; retained players (Kohli, Rohit) are excluded from value analysis since they bypass auctions
- Performance Score doesn't account for fielding, match impact, or captaincy value
- Future improvement: add phase-wise stats (powerplay vs death overs) and incorporate player age/fitness factors
- Could extend to predict fair auction value using regression models

---

## 🗃️ Data Sources

- [IPL Complete Dataset 2008–2022 — Kaggle](https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020)
- [IPL Player Auction Dataset — Kaggle](https://www.kaggle.com/datasets/kalilurrahman/ipl-player-auction-dataset-from-start-to-now)

---

## 👤 Author

Atharva Shinde
Data Analytics Portfolio Project #3
https://www.linkedin.com/in/atharvashinde797/ | https://github.com/atharva796-git
