-- Session-to-purchase conversion analysis by GA4 landing pages
-- Витягуємо базові дані, включаючи сирий URL сторінки
WITH base_data AS (
  SELECT
    date(timestamp_micros(event_timestamp)) AS event_date,
    event_name,
    user_pseudo_id,
    concat(
      user_pseudo_id, '-', (SELECT value.int_value FROM Unnest(event_params) WHERE key='ga_session_id')
    ) AS session_key,
    -- Витягуємо URL для кожної події
    (SELECT value.string_value FROM UNNEST(event_params) WHERE key = "page_location") AS page_location
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _table_suffix BETWEEN '20200101' AND '20201231'
    -- Фільтруємо ті події, які нам потрібні для визначення початку сесії та покупки
    AND event_name IN ('session_start', 'purchase')
),
-- Агрегуємо дані на рівні сесії
aggregated_by_session AS (
  SELECT
    session_key,
    user_pseudo_id,
    -- Визначаємо посадкову сторінку для сесії:
    REGEXP_EXTRACT(
      ANY_VALUE(
        CASE WHEN event_name = 'session_start' 
        THEN page_location END),
      r'^https?:\/\/[^\/]+(\/[^?]*)'
    ) AS page_path,
    -- Позначаємо, чи була подія 'session_start' 
    MAX(CASE WHEN event_name = 'session_start' 
      THEN 1 ELSE 0 END) 
    AS has_session_start,
    -- Позначаємо, чи була подія 'purchase' в цій сесії
    MAX(CASE WHEN event_name = 'purchase' 
      THEN 1 ELSE 0 END) 
    AS has_purchase
  FROM
    base_data
  GROUP BY
    session_key,
    user_pseudo_id
  HAVING
  -- Забезпечуємо, що ми розглядаємо тільки сесії, які дійсно почалися
    has_session_start = 1
    AND REGEXP_EXTRACT(
          ANY_VALUE(
            CASE WHEN event_name = 'session_start' 
            THEN page_location END),
          r'^https?:\/\/[^\/]+(\/[^?]*)'
    ) IS NOT NULL -- Виключаємо сесії без посадкової сторінки
),
-- Агрегуємо результати за посадковими сторінками
final_report AS (
  SELECT
    page_path,
    COUNT(DISTINCT session_key) AS total_sessions, 
    COUNT(DISTINCT user_pseudo_id) AS total_users, 
    COUNT(DISTINCT CASE WHEN has_purchase = 1 THEN session_key END) AS purchase_sessions -- Кількість сесій з покупками
  FROM
    aggregated_by_session
  GROUP BY
    page_path
)
-- Розраховуємо конверсію та виводимо фінальні дані
SELECT
  page_path,
  total_sessions,
  total_users,
  purchase_sessions,
  -- Конверсія від початку сесії до покупки
  SAFE_DIVIDE(purchase_sessions, total_sessions) * 100 AS session_to_purchase_rate
FROM
  final_report
ORDER BY
  total_sessions DESC;