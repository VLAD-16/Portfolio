-- conversion funnel analysis with GA4
--1. get user sessions
WITH sessions AS(
  select 
    date(timestamp_micros(event_timestamp)) as event_date,
    event_name,
    traffic_source.name as campaign,
    traffic_source.source as source,
    traffic_source.medium as medium,
    concat(
      user_pseudo_id, '-', (select value.int_value from Unnest(event_params) where key='ga_session_id')  
    ) AS session_key,
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  where _table_suffix BETWEEN '20210101' AND '20211231'
),
--2. get agreggated data
agreggated_data AS(
    select
    event_date, campaign, source, medium,
    count(distinct case when event_name='session_start' then session_key END) as session_start_count,
    count(distinct case when event_name='add_to_cart' then session_key END) as add_to_cart_count,
    count(distinct case when event_name='begin_checkout' then session_key END) as begin_checkout_count,
    count(distinct case when event_name='purchase' then session_key END) as purchase_count
  from sessions
  group by event_date, campaign, source, medium
)
--3. count all conversions 
  select
    event_date, campaign, source, medium, session_start_count,
    SAFE_DIVIDE(add_to_cart_count, session_start_count) * 100 AS visit_to_cart, 
    SAFE_DIVIDE (begin_checkout_count, session_start_count) * 100 AS visit_to_checkout, 
    SAFE_DIVIDE(purchase_count, session_start_count) * 100 AS visit_to_purchase, 
  from agreggated_data;

-- 4. будуємо конверсійну лійку
--4.1. Визначаємо початок сесій
WITH sessions AS(
  select 
    date(timestamp_micros(event_timestamp)) as event_date, -- конвертуємо час у дату
    user_pseudo_id,  -- унікальний користувач
    event_timestamp,  -- час події у мікросекундах
    concat(
      user_pseudo_id, '-', 
        cast(event_timestamp AS string)
      ) AS session_key,   -- створюємо унікальний ключ сесії (користувач + час), бо тільки по session_id недостатньо
    traffic_source.name as source,   -- звідки прийшов користувач
    traffic_source.medium as medium,   -- тип трафіку (organic, cpc і т.п.)
  from `ambient-stone-463119-k9.Results.Copy_events_20210131`
  where event_name = 'session_start'   -- беремо тільки події початку сесії
),

--4.2. Знаходимо першу згадку кампанії після старту сесії session -> event 
campaigns AS(
    select
    user_pseudo_id,
    event_timestamp,
    (select value.string_value 
        from Unnest(event_params) 
        where key='campaign') 
      AS campaign, 
    ROW_NUMBER() over (
      partition by user_pseudo_id
      order by event_timestamp
    ) AS rn  
  from `ambient-stone-463119-k9.Results.Copy_events_20210131`
  where exists (
    select 1 From unnest(event_params) ep
    where ep.key = 'campaign'  -- залишаємо тільки ті події, де є ключ 'campaign'
  )
),
--4.3. Вибираємо потрібні події-конверсії
conversions AS (
  select
    user_pseudo_id,
    event_name,
    event_timestamp,
    CONCAT (
      user_pseudo_id, '-', 
      cast(event_timestamp AS string)
    ) AS conv_session_key
  from `ambient-stone-463119-k9.Results.Copy_events_20210131`
  where event_name in ('add_to_cart','begin_checkout','purchase')   --потрібні конверсії
),
--Щоб далі порахувати, чи сталася якась із цих дій після старту сесії.

--4.4. join sessions with campaigns  З'єднуємо сесію з кампанією
session_with_campaigns AS (
  SELECT 
    s.*,
    c.campaign
  FROM sessions s
  LEFT JOIN campaigns c
    ON s.user_pseudo_id = c.user_pseudo_id
    AND c.event_timestamp BETWEEN s.event_timestamp AND s.event_timestamp + (30 * 60 * 1000000) -- 30 min
    AND c.rn = 1
),
--LEFT JOIN — щоб залишити всі сесії, навіть якщо немає кампанії
--AND c.rn = 1 — обмежуємо до першої згадки campaign для користувача (завдяки ROW_NUMBER())
--4.5. join sessions with conversions within 30 minutes Додаємо інфо про конверсії до кожної сесії
session_conversions AS (
  SELECT 
    s.event_date,
    s.source,
    s.medium,
    s.campaign,
    CONCAT(s.user_pseudo_id, '-', CAST(s.event_timestamp AS STRING)) AS session_key,
    s.user_pseudo_id,
    MAX(IF(c.event_name = 'add_to_cart', 1, 0)) AS visit_to_cart,
    MAX(IF(c.event_name = 'begin_checkout', 1, 0)) AS visit_to_checkout,
    MAX(IF(c.event_name = 'purchase', 1, 0)) AS visit_to_purchase
    -- find conversions 
  FROM session_with_campaigns s
  LEFT JOIN conversions c
    ON s.user_pseudo_id = c.user_pseudo_id
      AND c.event_timestamp BETWEEN s.event_timestamp 
      AND s.event_timestamp + (30 * 60 * 1000000)  -- 30 min in microsec
      --поєднуємо все в один рядок на кожну унікальну сесію
  GROUP BY 1,2,3,4,5,6
)
--4.6. final aggregate unique sessions by event_date, source, medium, campaign
SELECT
  event_date,
  source,
  medium,
  campaign,
  COUNT(DISTINCT session_key) AS user_sessions_count,
  SUM(visit_to_cart) AS visit_to_cart,
  SUM(visit_to_checkout) AS visit_to_checkout,
  SUM(visit_to_purchase) AS visit_to_purchase
FROM session_conversions
GROUP BY event_date, source, medium, campaign
ORDER BY event_date, source, medium;