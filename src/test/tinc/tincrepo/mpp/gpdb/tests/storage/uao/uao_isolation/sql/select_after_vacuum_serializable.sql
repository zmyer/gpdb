-- @Description Ensures that a serializable select before during a vacuum operation blocks the vacuum.
-- 

DELETE FROM ao WHERE a < 128;
1: BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
1: SELECT COUNT(*) FROM ao2;
2: VACUUM ao;
1: SELECT COUNT(*) FROM ao;
1: COMMIT;
3: INSERT INTO ao VALUES (0);
