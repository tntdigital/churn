-- CREATE THE DATASET THAT NEEDS TO BE SCORED
-- and create a random trainset

BEGIN; 

DROP TABLE IF EXISTS CHURN_ACTIVE_CUSTOMERS;

CREATE TABLE CHURN_ACTIVE_CUSTOMERS (CUS_ID BIGINT NOT NULL PRIMARY KEY, acc_country VARCHAR(2) );

INSERT INTO CHURN_ACTIVE_CUSTOMERS
SELECT CUS_ID, MAX(LAC_LEGACY_COU_CD) AS acc_country
FROM stg2_CUST_DAILY_METRICS fc
INNER JOIN stg1_accntxref acc 
ON fc.CUS_ID = acc.CUS_ID
AND LAC_LEGACY_COU_CD IN ('IE','NL','DE','CY','GR','BE')
WHERE DT BETWEEN CURRENT_DATE - 80 AND CURRENT_DATE
GROUP BY 1;

ANALYZE CHURN_ACTIVE_CUSTOMERS;

DROP TABLE IF EXISTS CHURN_TRAIN_CUSTOMERS;

CREATE TABLE CHURN_TRAIN_CUSTOMERS (
  CUS_ID BIGINT NOT NULL 
  , TRAIN_WEEK_END_DT DATE NOT NULL
  , TRAIN_DT DATE NOT NULL
  , acc_country VARCHAR(2)
  , PRIMARY KEY(CUS_ID, TRAIN_WEEK_END_DT)
  );

INSERT INTO CHURN_TRAIN_CUSTOMERS
SELECT 
  fc.CUS_ID
  , TRAIN_DT + 7 - EXTRACT(dow FROM TRAIN_DT) TRAIN_WEEK_END_DT
  , TRAIN_DT
  , acc_country
FROM (
  SELECT 
    daily.CUS_ID
    , MIN_SHIP_DT, MAX_SHIP_DT, 
	            GREATEST(MIN_SHIP_DT,'2015-02-01')  
	            + CAST(random() * (80 + LEAST(MAX_SHIP_DT, '2016-12-01') - GREATEST(MIN_SHIP_DT,'2015-02-01')) AS int) TRAIN_DT
    , MAX(LAC_LEGACY_COU_CD) AS acc_country
  FROM stg2_CUST_LIFETIME_METRICS  daily
  INNER JOIN stg1_accntxref acc 
  ON daily.CUS_ID = acc.CUS_ID
    AND LAC_LEGACY_COU_CD IN ('IE','NL','DE','CY','GR','BE')
  WHERE MIN_SHIP_DT < '2016-12-01' AND MAX_SHIP_DT > '2015-02-01'
  GROUP BY 1,2,3
  ORDER BY random() 
  LIMIT 100*1000
)fc
;

ANALYZE CHURN_TRAIN_CUSTOMERS;

COMMIT;