-- players stats view
CREATE OR REPLACE VIEW vw_player_statistics AS
SELECT 
    dp.player_name,
    dmi_info.MATCH_TYPE AS format,
    dmi_info.GENDER,
    dmi_info.event_TYPE AS format_type,
    
    -- Total Runs
    SUM(CASE WHEN dmi.BATTER_ID = dp.player_id THEN dmi.RUNS_BATTER ELSE 0 END) AS total_runs,

    -- Total Wickets
    COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END) AS total_wickets,

    -- Batting Average (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id AND dmi.DISMISSAL_KIND IS NOT NULL THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(SUM(CASE WHEN dmi.BATTER_ID = dp.player_id THEN dmi.RUNS_BATTER ELSE 0 END) AS FLOAT) / 
            COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id AND dmi.DISMISSAL_KIND IS NOT NULL THEN 1 END), 
            2
        )
    END AS batting_average,

    -- Bowling Average (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(SUM(CASE WHEN dmi.BOWLER_ID = dp.player_id THEN dmi.RUNS_TOTAL ELSE 0 END) AS FLOAT) / 
            COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END), 
            2
        )
    END AS bowling_average,

    -- Batting Strike Rate (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(SUM(CASE WHEN dmi.BATTER_ID = dp.player_id THEN dmi.RUNS_BATTER ELSE 0 END) AS FLOAT) /
            COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id THEN 1 END) * 100, 
            2
        )
    END AS batting_strike_rate,

    -- Bowling Strike Rate (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id THEN 1 END) AS FLOAT) /
            COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END), 
            2
        )
    END AS bowling_strike_rate

FROM 
    players dp
LEFT JOIN 
    match_innings dmi 
ON 
    dp.player_id = dmi.BATTER_ID OR dp.player_id = dmi.BOWLER_ID
LEFT JOIN 
    match_info dmi_info
ON 
    dmi.MATCH_ID = dmi_info.match_id
GROUP BY 
    dp.player_name, dmi_info.MATCH_TYPE, dmi_info.event_TYPE, dmi_info.GENDER
order by total_runs desc;

CREATE OR REPLACE VIEW vw_player_statistics_overall AS
SELECT 
    dp.player_name,
    dmi_info.GENDER,
    
    -- Total Runs
    SUM(CASE WHEN dmi.BATTER_ID = dp.player_id THEN dmi.RUNS_BATTER ELSE 0 END) AS total_runs,

    -- Total Wickets
    COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END) AS total_wickets,

    -- Batting Average (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id AND dmi.DISMISSAL_KIND IS NOT NULL THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(SUM(CASE WHEN dmi.BATTER_ID = dp.player_id THEN dmi.RUNS_BATTER ELSE 0 END) AS FLOAT) / 
            COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id AND dmi.DISMISSAL_KIND IS NOT NULL THEN 1 END), 
            2
        )
    END AS batting_average,

    -- Bowling Average (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(SUM(CASE WHEN dmi.BOWLER_ID = dp.player_id THEN dmi.RUNS_TOTAL ELSE 0 END) AS FLOAT) / 
            COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END), 
            2
        )
    END AS bowling_average,

    -- Batting Strike Rate (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(SUM(CASE WHEN dmi.BATTER_ID = dp.player_id THEN dmi.RUNS_BATTER ELSE 0 END) AS FLOAT) /
            COUNT(CASE WHEN dmi.BATTER_ID = dp.player_id THEN 1 END) * 100, 
            2
        )
    END AS batting_strike_rate,

    -- Bowling Strike Rate (Rounded to 2 decimal places)
    CASE 
        WHEN COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END) = 0 
        THEN 0
        ELSE ROUND(
            CAST(COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id THEN 1 END) AS FLOAT) /
            COUNT(CASE WHEN dmi.BOWLER_ID = dp.player_id AND dmi.PLAYER_OUT_ID IS NOT NULL THEN 1 END), 
            2
        )
    END AS bowling_strike_rate

FROM 
    players dp
LEFT JOIN 
    match_innings dmi 
ON 
    dp.player_id = dmi.BATTER_ID OR dp.player_id = dmi.BOWLER_ID
LEFT JOIN 
    match_info dmi_info
ON 
    dmi.MATCH_ID = dmi_info.match_id
GROUP BY 
    dp.player_name, dmi_info.GENDER
order by total_runs desc;



-- KPIs
create or replace view vw_kpis as 
select 'Total Matches' as key, count(distinct match_id) as value, coalesce(match_type, 'ALL') match_type, coalesce(event_type, 'ALL') event_type from match_info group by cube (match_type, event_type)
union
select 'Total Male Matches' as key, count(distinct match_id) as value, coalesce(match_type, 'ALL') match_type, coalesce(event_type, 'ALL') event_type from match_info where gender='male' group by cube (match_type, event_type)
union
select 'Total Female Matches' as key, count(distinct match_id) as value, coalesce(match_type, 'ALL') match_type, coalesce(event_type, 'ALL') event_type from match_info where gender='female' group by cube (match_type, event_type)
union
select 'Total Runs' as key, sum(a.runs_total) as value, coalesce(b.match_type, 'ALL') match_type, coalesce(b.event_type, 'ALL') event_type from match_innings a left join match_info b using (match_id) group by cube (match_type, event_type)
union
select 'Total Extras' as key, sum(a.runs_extras) as value, coalesce(b.match_type, 'ALL') match_type, coalesce(b.event_type, 'ALL') event_type from match_innings a left join match_info b using (match_id) group by cube (match_type, event_type)
union
select 'Total Wickets' as key, COUNT(CASE WHEN a.PLAYER_OUT_ID IS NOT NULL THEN 1 END) as value, coalesce(b.match_type, 'ALL') match_type, coalesce(b.event_type, 'ALL') event_type from match_innings a left join match_info b using (match_id) group by cube (match_type, event_type)
order by match_type
;

create or replace view vw_latest_years as
select match_type, max(season) as latest_year from match_info group by all;

