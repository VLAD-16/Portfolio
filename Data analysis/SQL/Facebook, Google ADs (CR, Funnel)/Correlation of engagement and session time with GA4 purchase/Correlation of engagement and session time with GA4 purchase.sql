-- Correlation of engagement and session time with GA4 purchase
-- Отримати всі необхідні дані для роботи
WITH base_data AS (
  SELECT
    event_name,
    user_pseudo_id,
    event_timestamp,
    -- створюємо унікальний ключ сесії для користувача
    concat(
      user_pseudo_id, '-', (SELECT value.int_value FROM Unnest(event_params) WHERE key='ga_session_id')
    ) AS session_key,
    -- витягуємо ознаку, чи був користувач залучений під час цієї сесії
    (select value.string_value from unnest(event_params) where key='session_engaged'
    ) AS session_engaged,
    (select value.int_value from unnest(event_params) where key='engagement_time_msec'
    ) AS engagement_time_msec
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _table_suffix BETWEEN '20210101' AND '20211231'
    -- Фільтруємо ті події, які нам потрібні
    AND event_name IN ('session_start', 'purchase','user_engagement')
),
--2. агрегуємо показники
agreggated_data AS(
  select
    session_key,
    user_pseudo_id,
    -- Чи була сесія залученою (1 якщо так, 0 якщо ні)
    max(case when safe_cast(session_engaged AS int64) = 1 
         THEN 1 ELSE 0
    END)
    as is_session_engaged,
    -- Сума загального часу активності в мілісекундах для всієї сесії
    sum(coalesce(engagement_time_msec, 0)) AS total_engagement_time_msec,
    -- Чи відбулася покупка під час сесії (1 якщо так, 0 якщо ні)
    max(case when event_name = 'purchase' 
      THEN 1 ELSE 0
    END) 
    as has_purchase
  from base_data
  group by session_key, user_pseudo_id -- Групуємо за унікальними сесіями та користувачами
)
--3. отримуємо необхідні кореляції
SELECT 
  CORR(is_session_engaged, has_purchase) AS session_engage_to_purchase_corr,
  CORR(total_engagement_time_msec, has_purchase) engagement_time_to_purchase_corr
FROM agreggated_data;











-- get all params_name
SELECT
 distinct event_params.key as param_name 
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`, 
   UNNEST (event_params) AS event_params
WHERE
    _table_suffix BETWEEN '20201025' AND '20201112'
ORDER BY param_name;