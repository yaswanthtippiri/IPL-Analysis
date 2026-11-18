USE [IPL DB];
GO

SELECT COUNT(*) AS TotalBallByBall
FROM dbo.ball_by_ball_data;

SELECT COUNT(*) AS TotalMatches
FROM dbo.ipl_matches_data;

SELECT COUNT(*) AS TotalPlayers
FROM dbo.[players-data-updated];

SELECT COUNT(*) AS TotalTeams
FROM dbo.teams_data;

--How many IPL matches were played across all seasons?
SELECT
    COUNT(DISTINCT match_id) AS Total_Matches
FROM dbo.ipl_matches_data;

--How many IPL seasons are available in the dataset?
SELECT
    COUNT(DISTINCT season) AS Total_Seasons
FROM dbo.ipl_matches_data;

--How many matches were played in each IPL season?
SELECT
    season,
    COUNT(DISTINCT match_id) AS Total_Matches
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
GROUP BY season
ORDER BY season;

--Renaming the column Names
EXEC sp_rename 'dbo.teams_data.team_id2', 'team_name', 'COLUMN';
EXEC sp_rename 'dbo.teams_data.team_id3', 'team_name_short', 'COLUMN';
EXEC sp_rename 'dbo.teams_data.team_id4', 'image_url', 'COLUMN';

--How many distinct teams participated in IPL?
SELECT
    COUNT(DISTINCT team_name) AS Total_Teams
FROM dbo.teams_data;

--How many different venues hosted IPL matches?
SELECT
    COUNT(DISTINCT venue) AS Total_Venues
FROM dbo.ipl_matches_data
WHERE venue IS NOT NULL;


--Which IPL teams have won the most matches across all seasons?
SELECT TOP 10
    match_winner AS Team_Name,
    COUNT(*) AS Matches_Won
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
  AND match_winner IS NOT NULL
GROUP BY match_winner
ORDER BY Matches_Won DESC;

--How many matches has each team played?
SELECT
    t.team_name,
    COUNT(*) AS Matches_Played
FROM dbo.teams_data t
JOIN dbo.ipl_matches_data m
    ON t.team_name = m.team1
    OR t.team_name = m.team2
WHERE m.match_type = 'T20'
GROUP BY t.team_name
ORDER BY Matches_Played DESC;

--Which teams have won the highest number of IPL matches across all seasons?
USE [IPL DB];
GO

SELECT TOP 10
    match_winner AS Team_Name,
    COUNT(*) AS Matches_Won
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
    AND match_winner IS NOT NULL
GROUP BY match_winner
ORDER BY Matches_Won DESC;

--Who are the top 10 batsmen with the highest total runs across all seasons?
SELECT TOP 10
    batter AS Player_Name,
    SUM(batter_runs) AS Total_Runs
FROM dbo.ball_by_ball_data
GROUP BY batter
ORDER BY Total_Runs DESC;

--Which players have hit the most sixes?
SELECT TOP 10
    batter AS Player_Name,
    COUNT(*) AS Total_Sixes
FROM dbo.ball_by_ball_data
WHERE batter_runs = 6
GROUP BY batter
ORDER BY Total_Sixes DESC;

--Which players have hit the most fours?
SELECT TOP 10
    batter AS Player_Name,
    COUNT(*) AS Total_Fours
FROM dbo.ball_by_ball_data
WHERE batter_runs = 4
GROUP BY batter
ORDER BY Total_Fours DESC;


--Who has taken the most wickets in IPL history?
SELECT TOP 10
    bowler AS Player_Name,
    COUNT(*) AS Total_Wickets
FROM dbo.ball_by_ball_data
WHERE is_wicket = 1
  AND wicket_kind NOT IN (
      'run out',
      'retired hurt',
      'retired out',
      'obstructing the field'
  )
GROUP BY bowler
ORDER BY Total_Wickets DESC;

--Who scored the most runs in each IPL season?
WITH PlayerRuns AS (
    SELECT
        m.season,
        b.batter,
        SUM(b.batter_runs) AS Total_Runs
    FROM dbo.ball_by_ball_data b
    JOIN dbo.ipl_matches_data m
        ON b.match_id = m.match_id
    GROUP BY m.season, b.batter
),
RankedPlayers AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY season
            ORDER BY Total_Runs DESC
        ) AS Player_Rank
    FROM PlayerRuns
)
SELECT
    season,
    batter AS Orange_Cap_Winner,
    Total_Runs
FROM RankedPlayers
WHERE Player_Rank = 1
ORDER BY season;

--Who took the most wickets in each IPL season?
WITH PlayerWickets AS (
    SELECT
        m.season,
        b.bowler,
        COUNT(*) AS Total_Wickets
    FROM dbo.ball_by_ball_data b
    JOIN dbo.ipl_matches_data m
        ON b.match_id = m.match_id
    WHERE b.is_wicket = 1
      AND b.wicket_kind NOT IN (
          'run out',
          'retired hurt',
          'retired out',
          'obstructing the field'
      )
    GROUP BY m.season, b.bowler
),
RankedBowlers AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY season
            ORDER BY Total_Wickets DESC
        ) AS Bowler_Rank
    FROM PlayerWickets
)
SELECT
    season,
    bowler AS Purple_Cap_Winner,
    Total_Wickets
FROM RankedBowlers
WHERE Bowler_Rank = 1
ORDER BY season;

--Team-wise win percentage
SELECT
    t.team_name,
    COUNT(*) AS Matches_Played,
    SUM(CASE
        WHEN m.match_winner = t.team_name THEN 1
        ELSE 0
    END) AS Matches_Won,
    CAST(
        100.0 * SUM(CASE
            WHEN m.match_winner = t.team_name THEN 1
            ELSE 0
        END) / COUNT(*) AS DECIMAL(5,2)
    ) AS Win_Percentage
FROM dbo.teams_data t
JOIN dbo.ipl_matches_data m
    ON t.team_name = m.team1
    OR t.team_name = m.team2
WHERE m.match_type = 'T20'
GROUP BY t.team_name
ORDER BY Win_Percentage DESC;

--Toss decision analysis
SELECT
    toss_decision,
    COUNT(*) AS Total_Matches,
    SUM(CASE
        WHEN toss_winner = match_winner THEN 1
        ELSE 0
    END) AS Matches_Won_By_Toss_Winner
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
  AND toss_winner IS NOT NULL
  AND match_winner IS NOT NULL
GROUP BY toss_decision;

--Most successful venues
SELECT TOP 10
    venue,
    COUNT(*) AS Total_Matches
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
  AND venue IS NOT NULL
GROUP BY venue
ORDER BY Total_Matches DESC;

--Season champions
WITH FinalMatches AS (
    SELECT
        season,
        match_winner,
        ROW_NUMBER() OVER (
            PARTITION BY season
            ORDER BY match_date DESC
        ) AS rn
    FROM dbo.ipl_matches_data
    WHERE stage = 'Final'
      AND match_winner IS NOT NULL
)
SELECT
    season,
    match_winner AS Champion
FROM FinalMatches
WHERE rn = 1
ORDER BY season;

--Most player-of-the-match awards
SELECT TOP 10
    p.player_name AS Player_Name,
    COUNT(*) AS Awards
FROM dbo.ipl_matches_data m
INNER JOIN dbo.[players-data-updated] p
    ON m.player_of_match = p.player_id
GROUP BY
    p.player_id,
    p.player_name
ORDER BY
    Awards DESC;


--Runs scored by each team
SELECT
    team_batting AS Team_Name,
    SUM(total_runs) AS Total_Runs
FROM dbo.ball_by_ball_data
GROUP BY team_batting
ORDER BY Total_Runs DESC;

--Runs scored by each team
SELECT
    team_batting AS Team_Name,
    SUM(total_runs) AS Total_Runs
FROM dbo.ball_by_ball_data
GROUP BY team_batting
ORDER BY Total_Runs DESC;

--Highest individual score
SELECT TOP 10
    batter AS Player_Name,
    match_id,
    SUM(batter_runs) AS Individual_Score
FROM dbo.ball_by_ball_data
GROUP BY
    match_id,
    batter
ORDER BY Individual_Score DESC;


--Which bowlers have taken the most wickets in a single match?

SELECT TOP 10
    bowler AS Player_Name,
    match_id,
    COUNT(*) AS Wickets_Taken
FROM dbo.ball_by_ball_data
WHERE is_wicket = 1
    AND wicket_kind NOT IN (
        'run out',
        'retired hurt',
        'retired out',
        'obstructing the field'
    )
GROUP BY
    match_id,
    bowler
ORDER BY Wickets_Taken DESC;

--Which IPL teams have the highest win percentage across all seasons?

SELECT
    t.team_name AS Team_Name,

    COUNT(*) AS Matches_Played,

    SUM(
        CASE
            WHEN m.match_winner = t.team_name THEN 1
            ELSE 0
        END
    ) AS Matches_Won,

    CAST(
        100.0 * SUM(
            CASE
                WHEN m.match_winner = t.team_name THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS DECIMAL(5,2)
    ) AS Win_Percentage

FROM dbo.teams_data t

JOIN dbo.ipl_matches_data m
    ON t.team_name = m.team1
    OR t.team_name = m.team2

WHERE m.match_type = 'T20'

GROUP BY t.team_name

ORDER BY Win_Percentage DESC;

--Toss Winner vs Match Winner Analysis.

SELECT
    COUNT(*) AS Total_Matches,

    SUM(
        CASE
            WHEN toss_winner = match_winner THEN 1
            ELSE 0
        END
    ) AS Toss_Winner_Won_Match,

    SUM(
        CASE
            WHEN toss_winner <> match_winner THEN 1
            ELSE 0
        END
    ) AS Toss_Winner_Lost_Match,

    CAST(
        100.0 * SUM(
            CASE
                WHEN toss_winner = match_winner THEN 1
                ELSE 0
            END
        ) / COUNT(*) AS DECIMAL(5,2)
    ) AS Toss_Win_Success_Percentage

FROM dbo.ipl_matches_data

WHERE match_type = 'T20'
    AND toss_winner IS NOT NULL
    AND match_winner IS NOT NULL;


--Venue-wise Match Statistics
SELECT
    venue AS Venue_Name,
    COUNT(DISTINCT match_id) AS Total_Matches
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
  AND venue IS NOT NULL
GROUP BY venue
ORDER BY Total_Matches DESC;

--Season-wise total runs
SELECT
    m.season,
    SUM(b.total_runs) AS Total_Runs
FROM dbo.ball_by_ball_data b
JOIN dbo.ipl_matches_data m
    ON b.match_id = m.match_id
GROUP BY m.season
ORDER BY m.season;

--Season-wise total wickets
SELECT
    m.season,
    COUNT(*) AS Total_Wickets
FROM dbo.ball_by_ball_data b
JOIN dbo.ipl_matches_data m
    ON b.match_id = m.match_id
WHERE b.is_wicket = 1
GROUP BY m.season
ORDER BY m.season;

--Highest team score in a match
SELECT TOP 10
    match_id,
    team_batting AS Team_Name,
    SUM(total_runs) AS Total_Score
FROM dbo.ball_by_ball_data
GROUP BY match_id, team_batting
ORDER BY Total_Score DESC;


--Most boundaries by player (fours + sixes)
SELECT TOP 10
    batter AS Player_Name,
    SUM(CASE WHEN batter_runs = 4 THEN 1 ELSE 0 END) AS Total_Fours,
    SUM(CASE WHEN batter_runs = 6 THEN 1 ELSE 0 END) AS Total_Sixes,
    SUM(CASE WHEN batter_runs IN (4, 6) THEN 1 ELSE 0 END) AS Total_Boundaries
FROM dbo.ball_by_ball_data
GROUP BY batter
ORDER BY Total_Boundaries DESC;

--Team-wise toss decisions
SELECT
    toss_winner AS Team_Name,
    toss_decision AS Toss_Decision,
    COUNT(*) AS Total_Times
FROM dbo.ipl_matches_data
WHERE toss_winner IS NOT NULL
GROUP BY toss_winner, toss_decision
ORDER BY Total_Times DESC;

--Most successful teams by season
WITH TeamWins AS (
    SELECT
        season,
        match_winner AS Team_Name,
        COUNT(*) AS Matches_Won,
        RANK() OVER (
            PARTITION BY season
            ORDER BY COUNT(*) DESC
        ) AS Team_Rank
    FROM dbo.ipl_matches_data
    WHERE match_winner IS NOT NULL
      AND match_type = 'T20'
    GROUP BY season, match_winner
)
SELECT
    season,
    Team_Name,
    Matches_Won
FROM TeamWins
WHERE Team_Rank = 1
ORDER BY season;


--Matches won by batting first vs chasing
SELECT
    CASE
        WHEN win_by_runs > 0 THEN 'Batting First'
        WHEN win_by_wickets > 0 THEN 'Chasing'
        ELSE 'Other / No Result'
    END AS Win_Type,
    COUNT(*) AS Matches
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
GROUP BY
    CASE
        WHEN win_by_runs > 0 THEN 'Batting First'
        WHEN win_by_wickets > 0 THEN 'Chasing'
        ELSE 'Other / No Result'
    END
ORDER BY Matches DESC;

--Player of the Match awards by season
SELECT
    m.season,
    p.player_name AS Player_Name,
    COUNT(*) AS Awards
FROM dbo.ipl_matches_data m
JOIN dbo.[players-data-updated] p
    ON m.player_of_match = p.player_id
WHERE m.player_of_match IS NOT NULL
GROUP BY m.season, p.player_name
ORDER BY m.season, Awards DESC;


--Average runs per match
WITH MatchRuns AS (
    SELECT
        match_id,
        SUM(total_runs) AS Total_Runs
    FROM dbo.ball_by_ball_data
    GROUP BY match_id
)
SELECT
    CAST(AVG(1.0 * Total_Runs) AS DECIMAL(10,2)) AS Average_Runs_Per_Match
FROM MatchRuns;

--Average wickets per match
WITH MatchWickets AS (
    SELECT
        match_id,
        SUM(CASE WHEN is_wicket = 1 THEN 1 ELSE 0 END) AS Total_Wickets
    FROM dbo.ball_by_ball_data
    GROUP BY match_id
)
SELECT
    CAST(AVG(1.0 * Total_Wickets) AS DECIMAL(10,2)) AS Average_Wickets_Per_Match
FROM MatchWickets;

--Player-wise batting performance
SELECT TOP 10
    batter AS Player_Name,
    COUNT(DISTINCT match_id) AS Matches_Played,
    SUM(batter_runs) AS Total_Runs,
    CAST(
        1.0 * SUM(batter_runs) / NULLIF(COUNT(DISTINCT match_id), 0)
        AS DECIMAL(10,2)
    ) AS Runs_Per_Match
FROM dbo.ball_by_ball_data
GROUP BY batter
ORDER BY Total_Runs DESC;

--Team-wise average runs per innings
SELECT
    team_batting AS Team_Name,
    COUNT(DISTINCT match_id) AS Matches_Batted,
    CAST(
        1.0 * SUM(total_runs) / NULLIF(COUNT(DISTINCT match_id), 0)
        AS DECIMAL(10,2)
    ) AS Average_Runs_Per_Match
FROM dbo.ball_by_ball_data
GROUP BY team_batting
ORDER BY Average_Runs_Per_Match DESC;

--Number of IPL trophies won by each team
SELECT
    match_winner AS Team_Name,
    COUNT(*) AS IPL_Titles_Won
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
  AND stage = 'Final'
  AND match_winner IS NOT NULL
GROUP BY match_winner
ORDER BY IPL_Titles_Won DESC;

--Team with the highest number of IPL titles
WITH TeamTitles AS (
    SELECT
        match_winner AS Team_Name,
        COUNT(*) AS IPL_Titles_Won
    FROM dbo.ipl_matches_data
    WHERE match_type = 'T20'
      AND stage = 'Final'
      AND match_winner IS NOT NULL
    GROUP BY match_winner
)
SELECT TOP 1 WITH TIES
    Team_Name,
    IPL_Titles_Won
FROM TeamTitles
ORDER BY IPL_Titles_Won DESC;

--Toss winner vs match winner
SELECT
    COUNT(*) AS Total_Matches,
    SUM(CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END) AS Toss_Winner_Won_Match,
    SUM(CASE WHEN toss_winner <> match_winner THEN 1 ELSE 0 END) AS Toss_Winner_Lost_Match,
    CAST(
        100.0 * SUM(CASE WHEN toss_winner = match_winner THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(5,2)
    ) AS Toss_Win_Success_Percentage
FROM dbo.ipl_matches_data
WHERE match_type = 'T20'
  AND toss_winner IS NOT NULL
  AND match_winner IS NOT NULL;