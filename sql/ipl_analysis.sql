CREATE DATABASE ipl_analysis;
USE ipl_analysis;

CREATE TABLE matches (
    Match_ID INT, City VARCHAR(50), Date DATE, Season INT,
    MatchNumber VARCHAR(20), Team1 VARCHAR(50), Team2 VARCHAR(50),
    Venue VARCHAR(100), TossWinner VARCHAR(50), TossDecision VARCHAR(10),
    SuperOver VARCHAR(1), Winner VARCHAR(50), WonBy VARCHAR(10),
    Margin INT, POTM VARCHAR(50)
);

CREATE TABLE ball_by_ball (
    Match_ID INT, Innings INT, Overs INT, BallNumber INT,
    Batter VARCHAR(50), Bowler VARCHAR(50), Non_Striker VARCHAR(50),
    Extra_Type VARCHAR(20), Batter_Runs INT, Extra_Runs INT,
    Total_Runs INT, Is_Wicket INT, Player_Out VARCHAR(50),
    Kind VARCHAR(30), Batting_Team VARCHAR(50)
);

CREATE TABLE auction (
    Player VARCHAR(50), Role VARCHAR(20), Amount BIGINT,
    Amount_Cr DECIMAL(10,2), Team VARCHAR(50), Year INT,
    Player_Origin VARCHAR(20)
);

-- IMPORT FILES
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Matches_Clean.csv'
INTO TABLE matches FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Ball_by_Ball_Clean.csv'
INTO TABLE ball_by_ball FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Auction_Clean.csv'
INTO TABLE auction FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 ROWS;

SELECT COUNT(*) AS total_matches FROM matches;
SELECT COUNT(*) AS total_balls FROM ball_by_ball;
SELECT COUNT(*) AS total_auction FROM auction;

-- TOP RUN SCORES OF ALL TIME
SELECT Batter, SUM(Batter_runs) AS Total_Runs
FROM ball_by_ball
GROUP BY Batter
ORDER BY Total_Runs DESC
LIMIT 10;

-- TOP WICKET TAKERS OF ALL TIME
SELECT Bowler, COUNT(*) as Total_Wickets
FROM ball_by_ball
WHERE Is_Wicket = 1 AND Kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
GROUP BY Bowler
ORDER BY Total_Wickets DESC
LIMIT 10;

-- STRIKE RATE PER BATTER (MIN 200 BALLS FACED)
SELECT Batter,
       SUM(Batter_Runs) AS Total_Runs,
       SUM(CASE WHEN Extra_Type != 'wides' THEN 1 ELSE 0 END) AS Balls_Faced,
       ROUND(SUM(Batter_Runs) * 100.0 / 
             SUM(CASE WHEN Extra_Type != 'wides' THEN 1 ELSE 0 END), 2) AS Strike_Rate
FROM ball_by_ball
GROUP BY Batter
HAVING Balls_Faced >= 200
ORDER BY Strike_Rate DESC
LIMIT 10;

-- ECONOMY RATE PER BOWLER (MIN 200 BALLS BOWLED)
SELECT Bowler,
       SUM(Total_Runs) AS Runs_Conceded,
       SUM(CASE WHEN Extra_Type NOT IN ('wides','noballs') THEN 1 ELSE 0 END) AS Legal_Balls,
       ROUND(SUM(Total_Runs) * 6.0 / 
             SUM(CASE WHEN Extra_Type NOT IN ('wides','noballs') THEN 1 ELSE 0 END), 2) AS Economy_Rate
FROM ball_by_ball
GROUP BY Bowler
HAVING Legal_Balls >= 200
ORDER BY Economy_Rate ASC
LIMIT 10;

-- Player Performance Score vs Auction Value Classification
WITH batting_stats AS (
    SELECT Batter AS Player,
           SUM(Batter_Runs) AS Total_Runs,
           ROUND(SUM(Batter_Runs) * 100.0 / 
                 NULLIF(SUM(CASE WHEN Extra_Type != 'wides' THEN 1 ELSE 0 END),0), 2) AS Strike_Rate
    FROM ball_by_ball
    GROUP BY Batter
),
bowling_stats AS (
    SELECT Bowler AS Player,
           COUNT(CASE WHEN Is_Wicket = 1 
                 AND Kind NOT IN ('run out','retired hurt','obstructing the field') 
                 THEN 1 END) AS Total_Wickets
    FROM ball_by_ball
    GROUP BY Bowler
),
auction_aggregated AS (
    SELECT Player,
           MAX(Role) AS Role,
           ROUND(AVG(Amount_Cr), 2) AS Avg_Price_Cr,
           MAX(Amount_Cr) AS Max_Price_Cr,
           COUNT(*) AS Times_Auctioned
    FROM auction
    GROUP BY Player
),
performance AS (
    SELECT a.Player,
           a.Role,
           a.Avg_Price_Cr,
           a.Max_Price_Cr,
           a.Times_Auctioned,
           COALESCE(b.Total_Runs, 0) AS Total_Runs,
           COALESCE(b.Strike_Rate, 0) AS Strike_Rate,
           COALESCE(w.Total_Wickets, 0) AS Total_Wickets,
           ROUND(
               (COALESCE(b.Total_Runs,0) * 0.4) +
               (COALESCE(b.Strike_Rate,0) * 0.3) +
               (COALESCE(w.Total_Wickets,0) * 0.3), 2
           ) AS Performance_Score
    FROM auction_aggregated a
    LEFT JOIN batting_stats b ON a.Player = b.Player
    LEFT JOIN bowling_stats w ON a.Player = w.Player
)

SELECT *,
       CASE
           WHEN Avg_Price_Cr > 8  AND Performance_Score < 200  THEN 'Overpriced'
           WHEN Avg_Price_Cr > 5  AND Performance_Score < 100  THEN 'Overpriced'
           WHEN Avg_Price_Cr < 2  AND Performance_Score > 300  THEN 'Underpaid Gem'
           WHEN Avg_Price_Cr < 4  AND Performance_Score > 150  THEN 'Good Value'
           ELSE 'Fair Price'
       END AS Value_Flag
FROM performance
ORDER BY Performance_Score DESC
LIMIT 30;

/* FOR THE ABOVE QUERY, THESE ARE THE RESULTS:
Underpaid Gems
- Shubman Gill — paid only ₹1.8 Cr, but 1900 runs with 125 SR → Performance Score 797. Absolute steal.
- Mandeep Singh — avg ₹1.25 Cr, 1692 runs → Score 713. Consistently undervalued across 2 auctions.

Overpriced
- Avesh Khan — avg ₹5.35 Cr, max ₹10 Cr (LSG paid a fortune in 2022) but only 48 wickets and barely any runs → Score just 75.
- Shivam Mavi — avg ₹5.13 Cr, max ₹7.25 Cr but Score only 56. Another overpaid young pacer.

Interesting observations
- KL Rahul at ₹11 Cr max — Score 1598, flagged as "Fair Price" which actually makes sense for a top-order batter of his caliber
- Harbhajan Singh — ₹2 Cr for 150 wickets + 833 runs → "Good Value" is an understatement, he was a bargain
- Mohammad Nabi — only ₹0.77 Cr avg for an international all-rounder with 186 runs + 13 wickets → very cheap buy
*/

-- Top 10 most expensive auction buys ever
SELECT Player, Role, Amount_Cr, Team, Year
FROM auction
ORDER BY Amount_Cr DESC
LIMIT 10;
/* RESULTS:
- Christopher Morris ₹16.25 Cr is the most expensive IPL auction buy ever — an all-rounder who barely played
- Yuvraj Singh appears twice in top 10 — paid ₹16 Cr in 2015 and ₹14 Cr in 2014, total ₹30 Cr across career
- 7 out of 10 most expensive buys are all-rounders — teams clearly pay a premium for all rounders
- 2021 mega auction dominates the list — Morris, Jamieson, Maxwell all from same year
*/

-- Average auction spend per team
SELECT Team,
       ROUND(AVG(Amount_Cr), 2) AS Avg_Spend_Cr,
       ROUND(SUM(Amount_Cr), 2) AS Total_Spend_Cr,
       COUNT(*) AS Players_Bought
FROM auction
GROUP BY Team
ORDER BY Total_Spend_Cr DESC;
/* RESULTS:
- RCB spent the most overall (₹270 Cr across 115 players) yet famously never won the IPL 
- Mumbai Indians bought smartly — ₹187 Cr for 107 players, lowest avg spend (₹1.75 Cr) yet most IPL titles
- Pune Warriors India has the highest avg spend (₹4.69 Cr) but only 4 players — very small sample, likely retained players only
- Lucknow & Gujarat have high avg spend (₹3.28 Cr, ₹2.59 Cr) as newer franchises paying market rate
*/


-- Season wise total runs scored
SELECT m.Season,
       SUM(b.Total_Runs) AS Season_Runs,
       COUNT(DISTINCT b.Match_ID) AS Matches_Played,
       ROUND(SUM(b.Total_Runs) / COUNT(DISTINCT b.Match_ID), 2) AS Avg_Runs_Per_Match
FROM ball_by_ball b
JOIN matches m ON b.Match_ID = m.Match_ID
GROUP BY m.Season
ORDER BY m.Season;
/* RESULTS:
- 2022 had the highest total runs (24,395) — biggest season ever with 74 matches
- Avg runs per match has been rising — from 309 in 2008 to 329 in 2022, shows T20 batting is getting more aggressive over time
- 2009 was the lowest scoring season (286 avg) — played in South Africa, due to different weather and pitch conditions
- 2018 onwards consistently above 320 avg
*/

