INSERT INTO  book_records (b_loc, o_id,  type, description, amount) VALUES  ( "STORE_1", 0, "Caja inicial", "Auto generada",  

(select * from (
select sum(amount) from book_records WHERE convert_tz(created_at, "+0:0", "-3:0") >=
(SELECT left( MAX(convert_tz(created_at, "+0:0", "-3:0")), 10) AS old FROM book_records WHERE convert_tz(created_at, "+0:0", "-3:0") < (select left(now(), 10)))
AND convert_tz(created_at, "+0:0", "-3:0") < (select left(now(), 10))
) as uno)

);
