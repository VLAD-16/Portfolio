-- SQL project. Author Goncharuk Vladislav. 2025-07-02. Ver.1.0
-- TASK 1. Дослідження деталей онлайн-кампаній (PostgreSQL)
-- Subtask 1: Розраховано середнє, максимум і мінімум щоденних витрат по Facebook
with
	CTE_fb as (
		SELECT
			ad_date,
			'Facebook' AS platform,
			SUM(spend) AS total_spend,
			ROUND(AVG(spend), 2) AS avg_spend,
			MAX(spend) AS max_spend,
			MIN(spend) AS min_spend
		FROM
			facebook_ads_basic_daily
		GROUP BY
			ad_date
	),
	CTE_google as (
		SELECT
			ad_date,
			'Google' AS platform,
			SUM(spend) AS total_spend,
			ROUND(AVG(spend), 2) AS avg_spend,
			MAX(spend) AS max_spend,
			MIN(spend) AS min_spend
		FROM
			google_ads_basic_daily
		GROUP BY
			ad_date
	)
SELECT
	*
FROM
	CTE_fb
union ALL
SELECT
	*
from
	CTE_google
ORDER BY
	ad_date,
	platform;

------------------------------- END subtask 1 -------------------------------
-- Subtask 2. Знайдено топ-5 днів за рівнем ROMI загалом (включаючи Google та Facebook),
-- виведено дати та відповідні значення у порядку спадання.
SELECT
	ad_date,
	platform,
	ROUND(SUM(value)::numeric / SUM(spend)::numeric - 1, 3) AS romi
FROM
	(
		SELECT
			ad_date,
			spend,
			value,
			'Facebook' AS platform
		FROM
			facebook_ads_basic_daily
		WHERE
			spend > 0
			AND value IS NOT NULL
		UNION ALL
		SELECT
			ad_date,
			spend,
			value,
			'Google' AS platform
		FROM
			google_ads_basic_daily
		WHERE
			spend > 0
			AND value IS NOT NULL
	) AS combined
GROUP BY
	ad_date,
	platform
ORDER BY
	romi DESC
LIMIT
	5;

------------------------------- END subtask 2 -------------------------------
--Subtask 3. Знайдено кампанію з найвищим рівнем загального тижневого value.
-- ! вказано тиждень та значення value
with
	weekly_values AS (
		SELECT
			platform,
			campaign_name,
			DATE_TRUNC('week', ad_date) as week_start,
			SUM(value) as total_value
		FROM
			(
				select
					ad_date,
					campaign_name,
					value,
					'Facebook' as platform
				from
					facebook_ads_basic_daily
					left join FACEBOOK_CAMPAIGN using (CAMPAIGN_ID)
				where
					value is not null
				union all
				select
					ad_date,
					campaign_name,
					value,
					'Google' as platform
				from
					google_ads_basic_daily
				where
					value is not null
			) as all_data
		group by
			platform,
			campaign_name,
			week_start
	)
select
	*
from
	weekly_values
order by
	total_value desc
limit
	1;

------------------------------- END subtask 3 -------------------------------
-- Subtask 4. Знайдено кампанію, що мала найбільший приріст у охопленні (reach) місяць-до-місяця.
with
	montly_reach_data as (
		SELECT
			platform,
			campaign_name,
			DATE_TRUNC('month', ad_date) as month_start,
			SUM(reach) as total_reach
		FROM
			(
				select
					ad_date,
					campaign_name,
					reach,
					'Facebook' as platform
				from
					facebook_ads_basic_daily
					left join FACEBOOK_CAMPAIGN using (CAMPAIGN_ID)
				where
					reach is not null
				union all
				select
					ad_date,
					campaign_name,
					reach,
					'Google' as platform
				from
					google_ads_basic_daily
				where
					reach is not null
			) as all_data
		group by
			platform,
			campaign_name,
			month_start
	),
	reach_growths_data as (
		select
			platform,
			campaign_name,
			month_start,
			total_reach,
			lag(total_reach) over (
				partition by
					platform,
					campaign_name
				order by
					month_start
			) as prev_month_reach,
			total_reach - lag(total_reach) over (
				partition by
					platform,
					campaign_name
				order by
					month_start
			) as reach_growth
		from
			montly_reach_data
	)
select
	*
from
	reach_growths_data
where
	reach_growth is not null
order by
	reach_growth desc
limit
	1;

------------------------------- END subtask 4 -------------------------------
-- Subtask 5. Знайдено тривалість найдовшого 
-- безперервного щоденного показу adset_name (разом із Google та Facebook)
WITH
	all_adsets AS (
		SELECT
			ad_date,
			fc.campaign_name,
			fa.adset_name,
			'Facebook' as platform
		FROM
			facebook_ads_basic_daily fb
			LEFT JOIN facebook_adset fa USING (adset_id)
			LEFT JOIN facebook_campaign fc USING (campaign_id)
		WHERE
			adset_id IS NOT NULL
			AND ad_date IS NOT NULL
		UNION ALL
		SELECT
			ad_date,
			campaign_name,
			adset_name,
			'Google' as platform
		FROM
			google_ads_basic_daily
		WHERE
			adset_name IS NOT NULL
			AND ad_date IS NOT NULL
	),
	adset_sequences AS (
		SELECT
			platform,
			campaign_name,
			adset_name,
			ad_date,
			ad_date - ROW_NUMBER() OVER (
				PARTITION BY
					platform,
					campaign_name,
					adset_name
				ORDER BY
					ad_date
			) * INTERVAL '1 day' AS sequence_group
		FROM
			all_adsets
	),
	series_lengths AS (
		SELECT
			platform,
			campaign_name,
			adset_name,
			MIN(ad_date) AS start_date,
			MAX(ad_date) AS end_date,
			COUNT(*) AS duration_days
		FROM
			adset_sequences
		GROUP BY
			platform,
			campaign_name,
			adset_name,
			sequence_group
	)
select
	*
from
	series_lengths
order by
	duration_days desc
limit
	1;

------------------------------- END subtask 5 -------------------------------
------------------------------- END OF QUERY --------------------------------