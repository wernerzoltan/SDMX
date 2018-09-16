
create or replace PACKAGE BODY SDMX_2200_302 AS

PROCEDURE smdx_input(P_EVSZAM VARCHAR2, P_N13G_V VARCHAR2, P_N13G_Y VARCHAR2) AS  
V_PRICES T_PRICES;
V_GFCF_TABLE T_GFCF_TABLE;
v_temp_tables t_temp_tables;
v_tables t_tables;
v_NaN_rows t_NaN_rows;
v_year_keszlet t_year_keszlet;
v_manual t_manual;
V_PRICES_NAN T_PRICES_NAN;
--v_NaN_0302 t_NaN_0302;

procName VARCHAR2(50);
v NUMERIC;
d NUMERIC;
g NUMERIC;
h NUMERIC;
sql_statement VARCHAR2(500);
keszlet VARCHAR2(10);
N12G VARCHAR2(10);
N13G VARCHAR2(10);

v_year VARCHAR2(5) := ''|| P_EVSZAM ||'';
v_prev_year VARCHAR2(10) := ''|| P_EVSZAM ||'-1';
v_gfcf_link VARCHAR2(20) := 'GFCF_LINK';

TYPE gfcf_set IS TABLE OF GFCF_LINK%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf gfcf_set; -- Holds set of rows from GFCF_LINK table. 

TYPE gfcf_agazat_set IS TABLE OF GFCF_V%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_agazat gfcf_agazat_set; -- Holds set of rows from GFCF_V table. 

TYPE gfcf_sdmx_set IS TABLE OF gfcf_sdmx%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab gfcf_sdmx_set; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_set_2200 IS TABLE OF gfcf_sdmx%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab_2200 gfcf_sdmx_set_2200; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_set_all IS TABLE OF gfcf_sdmx%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab_all gfcf_sdmx_set_all; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_set_nan IS TABLE OF gfcf_sdmx%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab_nan gfcf_sdmx_set_nan; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_sum IS TABLE OF gfcf_sum%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab_sum gfcf_sdmx_sum; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_sum_2 IS TABLE OF gfcf_sum%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab_sum_2 gfcf_sdmx_sum_2; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_0302 IS TABLE OF gfcf_sdmx%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_tab_0302 gfcf_sdmx_0302; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_t IS TABLE OF T0302A_TEMP%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_l gfcf_t; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_t_2200 IS TABLE OF GFCF_SDMX%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_2200 gfcf_t_2200; -- Holds set of rows from GFCF_SDMX table. 

TYPE gfcf_sdmx_all_2_t IS TABLE OF GFCF_SDMX%ROWTYPE; -- tábla, ahonnan vesszük az adatokat
gfcf_sdmx_all_2 gfcf_sdmx_all_2_t; -- Holds set of rows from GFCF_SDMX table. 



BEGIN

V_PRICES(1) := 'V'; 	
V_PRICES(2) := 'Y'; 

V_PRICES_NAN(1) := 'V';
V_PRICES_NAN(2) := 'Y';
V_PRICES_NAN(3) := 'L';

V_GFCF_TABLE(1) := 'GFCF_V';
V_GFCF_TABLE(2) := 'GFCF_Y';

v_temp_tables(1) := 'T2200A_TEMP';
v_temp_tables(2) := 'T0302A_TEMP';

v_tables(1) := 'T2200A';
v_tables(2) := 'T0302A';

v_NaN_rows(1) := 'L68A';
v_NaN_rows(2) := 'T';
v_NaN_rows(3) := 'U';

/*v_NaN_0302(1) := 'N1MG';
v_NaN_0302(2) := 'N12G';
v_NaN_0302(3) := 'N13G';*/

v_year_keszlet(1) := 'Y'|| v_year ||'2';-- KESZLET adattábla Yév2 mezőt veszi (folyó ár)
v_year_keszlet(2) := 'Y'|| v_year ||''; -- KESZLET adattábla Yév mezőt veszi (változatlan ár)
keszlet := 'KESZLET'; 					-- KESZLET adattábla adatbázis neve
N12G := 'N12G';							-- KESZLET adattáblából ebbe a mezőbe írjuk be az adatokat
N13G := 'N13G';							-- manuálisan ebbe a mezőbe írjuk be az adatokat
v_manual(1) := ''|| P_N13G_V ||'';		-- manuális adatbeírás (N13G, folyó ár)
v_manual(2) := ''|| P_N13G_Y ||'';		-- manuális adatbeírás (N13G, változatlan ár)

procName := 'Create_sdmx';

	EXECUTE IMMEDIATE' TRUNCATE TABLE T2200A_TEMP 	';
	EXECUTE IMMEDIATE' TRUNCATE TABLE T0302A_TEMP 	';

	-- kell egy plusz mező számítása a GFCF táblákba: GFCF_ICT: GEPEK mező értéke mínusz ICT
	
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'STARTING', '');

	
	
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Calculate GEP_ICT column', '');

	FOR a IN v_gfcf_table.FIRST..v_gfcf_table.LAST LOOP

		-- hozzátesszük a plusz mezőt
		SELECT COUNT(*) INTO v FROM user_tab_cols WHERE column_name = UPPER('GEP_ICT') AND table_name = ''|| v_gfcf_table(a) ||'';
	
		IF v=0 THEN
			
			EXECUTE IMMEDIATE'
			ALTER TABLE '|| v_gfcf_table(a) ||'
			ADD GEP_ICT NUMBER
			'
			; 
		
		END IF;
		
		--ágazatonként kiszámítjuk a mező értékét
		SELECT * BULK COLLECT INTO gfcf_agazat FROM GFCF_V;
		
		FOR b IN gfcf_agazat.FIRST..gfcf_agazat.LAST LOOP
		
			EXECUTE IMMEDIATE'
			UPDATE '|| v_gfcf_table(a) ||'
			SET GEP_ICT = (SELECT GEPEK-ICT FROM '|| v_gfcf_table(a) ||' WHERE AGAZAT = '|| gfcf_agazat(b).AGAZAT ||')
			WHERE AGAZAT = '|| gfcf_agazat(b).AGAZAT ||'
			'
			;
		
		END LOOP;
		

INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Insert YEAR into GFCF table', '');
		
		-- a GFCF táblákba teszünk évszámot is
		SELECT COUNT(*) INTO d FROM user_tab_cols WHERE column_name = UPPER('YEAR') AND table_name = ''|| v_gfcf_table(a) ||'';
	
		IF d=0 THEN
			
			EXECUTE IMMEDIATE'
			ALTER TABLE '|| v_gfcf_table(a) ||'
			ADD YEAR NUMBER
			'
			; 
		
		END IF;
		
			EXECUTE IMMEDIATE'
			UPDATE '|| v_gfcf_table(a) ||'
			SET YEAR = '''|| P_EVSZAM ||'''
			'
			;
		
		
	END LOOP;
	


	-- létrehozzuk az SDMX_TEMP táblákat

	-- associative array-ba áttesszük a GFCF_SDMX tábla sorait, ahol az input tábla a GFCF és ahol nem SUM_ értékek vannak és nem NaN értékek, és ahol mindkét táblával közös (BOTH)
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab FROM GFCF_SDMX WHERE TABLE_NAME = 'GFCF' AND COLUMN_NAME NOT LIKE 'SUM_%' AND COLUMN_NAME != 'NaN' AND TABLE_OUT = 'BOTH';
	
		-- associative array-ba áttesszük a GFCF_SDMX tábla sorait, ahol az input tábla a GFCF és ahol nem SUM_ értékek vannak és nem NaN értékek, és ahol csak a 2200A-ba teszünk adatokat
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab_2200 FROM GFCF_SDMX WHERE TABLE_NAME = 'GFCF' AND COLUMN_NAME NOT LIKE 'SUM_%' AND COLUMN_NAME != 'NaN' AND TABLE_OUT = 'A2200';
	
	-- associative array-ba áttesszük a GFCF_LINK tábla sorait
	SELECT * BULK COLLECT INTO gfcf FROM GFCF_LINK;
	
	-- a TEMP táblákba kiszámoljuk az OBS_VALUE értékeket
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Create OBS_VALUE into temp tables', '');	
	
	-- a temp táblába külön beolvassuk a V és Y értékeket
	FOR a IN V_PRICES.FIRST .. V_PRICES.LAST LOOP
		
		-- a temp táblában kiszámoljuk az OBS_VALUE értékeket az array tartalma alapján minden sorra mindkét táblában
		FOR i IN gfcf.FIRST .. gfcf.LAST LOOP
	
			FOR b IN v_temp_tables.FIRST..v_temp_tables.LAST LOOP
	
				-- végigmegyünk az ágazatokon	
				FOR s IN gfcf_sdmx_tab.FIRST..gfcf_sdmx_tab.LAST LOOP

					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(b) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT '|| v_year ||', '''|| gfcf_sdmx_tab(s).INSTR_ASSET_CODE ||''', '''|| gfcf(i).ACTIVITY ||''', '''|| V_PRICES(a) ||''', sum('|| gfcf_sdmx_tab(s).COLUMN_NAME ||')
					FROM '|| V_GFCF_TABLE(a) ||' 
					WHERE AGAZAT IN '|| gfcf(i).TEAOR ||'
					'
					;
		
				END LOOP;
			
			END LOOP;
			
			-- az N1171G,N1173G oszlopokat a T2200A_TEMP táblába pluszban be kell illeszteni	
			FOR s IN gfcf_sdmx_tab_2200.FIRST..gfcf_sdmx_tab_2200.LAST LOOP

					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(1) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT '|| v_year ||', '''|| gfcf_sdmx_tab_2200(s).INSTR_ASSET_CODE ||''', '''|| gfcf(i).ACTIVITY ||''', '''|| V_PRICES(a) ||''', sum('|| gfcf_sdmx_tab_2200(s).COLUMN_NAME ||')
					FROM '|| V_GFCF_TABLE(a) ||' 
					WHERE AGAZAT IN '|| gfcf(i).TEAOR ||'
					'
					;
		
			END LOOP;
			
		END LOOP;
		
	END LOOP;	

	-- KESZLET adatok beillesztése a T0302A táblába
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Insert N12G rows into '|| v_temp_tables(2) ||' table', '');	

	FOR a IN V_PRICES.FIRST .. V_PRICES.LAST LOOP

		FOR i IN gfcf.FIRST .. gfcf.LAST LOOP
	
			EXECUTE IMMEDIATE'
				INSERT INTO '|| v_temp_tables(2) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
				SELECT '|| v_year ||', '''|| N12G ||''', '''|| gfcf(i).ACTIVITY ||''', '''|| V_PRICES(a) ||''', sum('|| v_year_keszlet(a) ||')
				FROM '|| keszlet ||'
				WHERE AGAZAT IN '|| gfcf(i).TEAOR ||'
				'
				;	

		END LOOP;
		
	END LOOP;
	
	-- KESZLET MANUAL adatok beillesztése a T0302A táblába
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Insert N12G rows into '|| v_temp_tables(2) ||' table', '');	

	FOR a IN V_PRICES.FIRST .. V_PRICES.LAST LOOP
	
		EXECUTE IMMEDIATE'
			INSERT INTO '|| v_temp_tables(2) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
				SELECT '|| v_year ||', '''|| N13G ||''', ''_T'' , '''|| V_PRICES(a) ||''', '''|| v_manual(a) ||'''
				FROM '|| keszlet ||'
				WHERE AGAZAT IN ''01''
				'
				;	

	END LOOP;
	
	
	-- SUM értékek számolása T0302A
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Calculate SUM data - T0302A_TEMP', '');	
	
	-- associative array-ba áttesszük a GFCF_SUM tábla sorait, ahol T0302A értékek vannak
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab_sum FROM GFCF_SUM WHERE OUTPUT_TABLES = 'T0302A';
	
	FOR b IN V_PRICES.FIRST .. V_PRICES.LAST LOOP
	
		FOR c IN gfcf_sdmx_tab_sum.FIRST..gfcf_sdmx_tab_sum.LAST LOOP
		
			FOR i IN gfcf.FIRST .. gfcf.LAST LOOP
		
				EXECUTE IMMEDIATE'
				INSERT INTO '|| v_temp_tables(2) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
				SELECT DISTINCT '|| v_year ||', '''|| gfcf_sdmx_tab_sum(c).OUT_COLUMN_NAME ||''', '''|| gfcf(i).ACTIVITY ||''', '''|| V_PRICES(b) ||''', sum(OBS_VALUE)
				FROM '|| v_temp_tables(2) ||'
				WHERE INSTR_ASSET IN '|| gfcf_sdmx_tab_sum(c).INPUT_COLUMNS ||'
				AND ACTIVITY = '''|| gfcf(i).ACTIVITY ||'''
				AND PRICES = '''|| V_PRICES(b) ||'''
				AND OBS_VALUE != ''NaN''
				'
				;
			
			END LOOP;
			
		END LOOP;
	
	END LOOP;
	
		
-- SUM értékek számolása T2200A
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Calculate SUM data - T2200A_TEMP', '');	
	
	
	-- associative array-ba áttesszük a GFCF_SUM tábla sorait, ahol T2200A értékek vannak
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab_sum_2 FROM GFCF_SUM WHERE OUTPUT_TABLES = 'T2200A';	

	FOR b IN V_PRICES.FIRST .. V_PRICES.LAST LOOP
	
		FOR c IN gfcf_sdmx_tab_sum_2.FIRST..gfcf_sdmx_tab_sum_2.LAST LOOP
		
			FOR i IN gfcf.FIRST .. gfcf.LAST LOOP
		
				EXECUTE IMMEDIATE'
				INSERT INTO '|| v_temp_tables(1) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
				SELECT DISTINCT '|| v_year ||', '''|| gfcf_sdmx_tab_sum_2(c).OUT_COLUMN_NAME ||''', '''|| gfcf(i).ACTIVITY ||''', '''|| V_PRICES(b) ||''', sum(OBS_VALUE)
				FROM '|| v_temp_tables(1) ||'
				WHERE INSTR_ASSET IN '|| gfcf_sdmx_tab_sum_2(c).INPUT_COLUMNS ||'
				AND ACTIVITY = '''|| gfcf(i).ACTIVITY ||'''
				AND PRICES = '''|| V_PRICES(b) ||'''
				AND OBS_VALUE != ''NaN''
				'
				;
			
			END LOOP;
			
			
		END LOOP;
	
	END LOOP;

		
		-- 'L' output létrehozása
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Create L rows', '');
	
	-- a NaN létrehozáshoz kellenek :
	-- a közös oszlopokra: kell egy array, ahol TABLE_OUT = BOTH, megkötés nélkül, mindkét táblára fusson le
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab_all FROM GFCF_SDMX WHERE TABLE_OUT = 'BOTH';
	
	-- a 2200A plusz oszlopaira: kell egy array, ahol TABLE_OUT = A2200 és COLUMN_NAME != 'NaN', csak a 2200A-ra fusson le. Korábban már létre lett hozva, ide is jó lesz:  SELECT * BULK COLLECT INTO gfcf_sdmx_tab_2200 FROM GFCF_SDMX WHERE TABLE_NAME = 'GFCF' AND COLUMN_NAME NOT LIKE 'SUM_%' AND COLUMN_NAME != 'NaN' AND TABLE_OUT = 'A2200';
	
	-- 0302A plusz oszlopaira -- kell egy array, ahol TABLE_OUT = A0302, csak a 0302A-ra fusson le:
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab_0302 FROM GFCF_SDMX WHERE TABLE_OUT = 'A0302';
	
	-- N11321G és 11322G minden sora: array, ahol TABLE_OUT = A2200 és COLUMN_NAME = 'NaN', csak a 2200A-ra fusson le: 
	SELECT * BULK COLLECT INTO gfcf_sdmx_tab_nan FROM GFCF_SDMX WHERE COLUMN_NAME = 'NaN' AND TABLE_OUT = 'A2200';

	-- a 'L' sorok létrehozásához kellenek:
	--létrehozunk egy associative array-t, amiből az ACTIVITY értékeket fogjuk felhasználni 
	SELECT * BULK COLLECT INTO gfcf_l FROM T0302A_TEMP WHERE INSTR_ASSET = 'N1G' AND PRICES = 'V';
		
	-- gfcf_sdmx_tab_all - a BOTH értékeket tartalmazza és a INSTR_ASSET értékeket fogjuk felhasználni 
		
	-- gfcf_sdmx_tab_0302 - a 0302 értékeket tartalmazza és a INSTR_ASSET értékeket fogjuk felhasználni 
		
	--létrehozunk egy associative array-t, ami a 2200A értékeket tartalmazza és a INSTR_ASSET értékeket fogjuk felhasználni 
	SELECT * BULK COLLECT INTO gfcf_2200 FROM GFCF_SDMX WHERE TABLE_OUT = 'A2200';
		
		
		FOR a IN v_temp_tables.FIRST..v_temp_tables.LAST LOOP
		
			FOR b IN gfcf_l.FIRST..gfcf_l.LAST LOOP
			
				-- a közös INSTR_ASSET-ekre futás
				FOR d IN gfcf_sdmx_tab_all.FIRST..gfcf_sdmx_tab_all.LAST LOOP
		
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(a) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', 
					'''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''',
					'''|| gfcf_l(b).ACTIVITY ||''',
					''L'',
					ROUND(
					(SELECT OBS_VALUE FROM '|| v_temp_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''Y'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_year ||') /
					(SELECT OBS_VALUE FROM '|| v_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND OBS_VALUE != ''0'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''V'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||') *
					(SELECT OBS_VALUE FROM '|| v_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||')
					) as OBS_VALUE
					FROM '|| v_tables(a) ||'
					WHERE ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE != ''NaN''
					'
					;
					
					--szükség van arra is, hogy ha az előző évben az 'L' táblában 'NaN' érték volt, akkor az az ideiben is az legyen
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(a) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', 
					'''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''',
					'''|| gfcf_l(b).ACTIVITY ||''',
					''L'',
					''NaN'' 
					FROM '|| v_tables(a) ||'
					WHERE ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE = ''NaN''
					'
					;
					
					-- szükség van arra is, hogy ha az előző évben a 'V' táblában '0' érték szerepelt ÉS az idei évben az 'Y' értéke NEM '0', akkor az az ideiben '0' értéket kapjon
					sql_statement := 'SELECT COUNT(*) FROM '|| v_temp_tables(a) ||'
					WHERE TIME_PERIOD = '''|| v_year ||''' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''Y'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''' AND OBS_VALUE = ''0'' ';
														
					EXECUTE IMMEDIATE sql_statement INTO h;
														
					IF h=0 THEN
																			
							EXECUTE IMMEDIATE'
							UPDATE '|| v_temp_tables(a) ||' 
							SET OBS_VALUE = (SELECT ''0'' FROM '|| v_tables(a) ||' WHERE TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE = ''0'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''V'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||''')
							WHERE OBS_VALUE IS NULL AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_all(d).INSTR_ASSET_CODE ||'''
							'
							;
																
					END IF;
											
				END LOOP;
					
				-- a 0302-es INSTR_ASSET-ekre futás
				FOR d IN gfcf_sdmx_tab_0302.FIRST..gfcf_sdmx_tab_0302.LAST LOOP
						
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(a) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', 
					'''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''',
					'''|| gfcf_l(b).ACTIVITY ||''',
					''L'',
					ROUND(
					(SELECT OBS_VALUE FROM '|| v_temp_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''Y'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_year ||') /
					(SELECT OBS_VALUE FROM '|| v_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND OBS_VALUE != ''0'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''V'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||') *
					(SELECT OBS_VALUE FROM '|| v_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||')
					) as OBS_VALUE
					FROM '|| v_tables(a) ||'
					WHERE ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE != ''NaN''
					'
					;
					
					--szükség van arra is, hogy ha az előző évben az 'L' táblában 'NaN' érték volt, akkor az az ideiben is az legyen
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(a) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', 
					'''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''',
					'''|| gfcf_l(b).ACTIVITY ||''',
					''L'',
					''NaN'' 
					FROM '|| v_tables(a) ||'
					WHERE ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE = ''NaN''
					'
					;
					
					-- szükség van arra is, hogy ha az előző évben a 'V' táblában '0' érték szerepelt ÉS az idei évben az 'Y' értéke NEM '0', akkor az az ideiben '0' értéket kapjon
					sql_statement := 'SELECT COUNT(*) FROM '|| v_temp_tables(a) ||'
					WHERE TIME_PERIOD = '''|| v_year ||''' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''Y'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''' AND OBS_VALUE = ''0'' ';
										
					EXECUTE IMMEDIATE sql_statement INTO h;
															
					IF h=0 THEN
						
						
					
							EXECUTE IMMEDIATE'
							UPDATE '|| v_temp_tables(a) ||' 
							SET OBS_VALUE = (SELECT ''0'' FROM '|| v_tables(a) ||' WHERE TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE = ''0'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''V'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||''')
							WHERE OBS_VALUE IS NULL AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_tab_0302(d).INSTR_ASSET_CODE ||'''
							'
							;
											
						
					END IF;
										
									
				END LOOP;
						
								
				-- a 2200-es INSTR_ASSET-ekre futás
				FOR d IN gfcf_2200.FIRST..gfcf_2200.LAST LOOP
						
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(a) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', 
					'''|| gfcf_2200(d).INSTR_ASSET_CODE ||''',
					'''|| gfcf_l(b).ACTIVITY ||''',
					''L'',
					ROUND(
					(SELECT OBS_VALUE FROM '|| v_temp_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''Y'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_year ||') /
					(SELECT OBS_VALUE FROM '|| v_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND OBS_VALUE != ''0'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''V'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||') *
					(SELECT OBS_VALUE FROM '|| v_tables(a) ||' WHERE OBS_VALUE != ''NaN'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||')
					) as OBS_VALUE
					FROM '|| v_tables(a) ||'
					WHERE ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE != ''NaN''
					'
					;
					
					
					--szükség van arra is, hogy ha az előző évben az 'L' táblában 'NaN' érték volt, akkor az az ideiben is az legyen
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(a) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', 
					'''|| gfcf_2200(d).INSTR_ASSET_CODE ||''',
					'''|| gfcf_l(b).ACTIVITY ||''',
					''L'',
					''NaN'' 
					FROM '|| v_tables(a) ||'
					WHERE ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''' AND TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE = ''NaN''
					'
					;
					
					-- szükség van arra is, hogy ha az előző évben a 'V' táblában '0' érték szerepelt ÉS az idei évben az 'Y' értéke NEM '0', akkor az az ideiben '0' értéket kapjon
					sql_statement := 'SELECT COUNT(*) FROM '|| v_temp_tables(a) ||'
					WHERE TIME_PERIOD = '''|| v_year ||''' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''Y'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''' AND OBS_VALUE = ''0'' ';
															
					EXECUTE IMMEDIATE sql_statement INTO h;
					
										
					IF h=0 THEN
						
															
							EXECUTE IMMEDIATE'
							UPDATE '|| v_temp_tables(a) ||' 
							SET OBS_VALUE = (SELECT ''0'' FROM '|| v_tables(a) ||' WHERE TIME_PERIOD = '|| v_prev_year ||' AND OBS_VALUE = ''0'' AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''V'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||''')
							WHERE OBS_VALUE IS NULL AND ACTIVITY = '''|| gfcf_l(b).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_2200(d).INSTR_ASSET_CODE ||'''
							'
							;
							
											
					END IF;
																				
					
				END LOOP;
					
			END LOOP;
			
		END LOOP;
	
	
				-- a temp táblákat a hiányzó NaN értékekkel feltöltjük
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'Insert NaN rows', '');
		
--létrehozunk egy associative array-t, ami az összes  INSTR_ASSET értéket tárolja
	SELECT * BULK COLLECT INTO gfcf_sdmx_all_2 FROM GFCF_SDMX;		
	
		FOR a IN V_PRICES_NAN.FIRST..V_PRICES_NAN.LAST LOOP
			
			-- mindenhol van 3 sor, ahol NaN értéket be kell írni
			FOR d IN v_NaN_rows.FIRST..v_NaN_rows.LAST LOOP
		
				FOR b IN v_temp_tables.FIRST..v_temp_tables.LAST LOOP
			
					-- a közös oszlopoknál mindenhol a 3 sor beírása
					--FOR c IN gfcf_sdmx_all_2.FIRST..gfcf_sdmx_all_2.LAST LOOP
					FOR c IN gfcf_sdmx_tab_all.FIRST..gfcf_sdmx_tab_all.LAST LOOP
					
						
						EXECUTE IMMEDIATE'
						INSERT INTO '|| v_temp_tables(b) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
						SELECT DISTINCT '|| v_year ||', '''|| gfcf_sdmx_tab_all(c).INSTR_ASSET_CODE ||''', '''|| v_NaN_rows(d) ||''', '''|| V_PRICES_NAN(a) ||''', ''NaN''
						FROM GFCF_V
						'
						;
				
					END LOOP;
			
					-- csak a 0302-nél a 3 sor beírása
					FOR c IN gfcf_sdmx_tab_0302.FIRST..gfcf_sdmx_tab_0302.LAST LOOP
					
						
						EXECUTE IMMEDIATE'
						INSERT INTO '|| v_temp_tables(2) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
						SELECT DISTINCT '|| v_year ||', '''|| gfcf_sdmx_tab_0302(c).INSTR_ASSET_CODE ||''', '''|| v_NaN_rows(d) ||''', '''|| V_PRICES_NAN(a) ||''', ''NaN''
						FROM GFCF_V
						'
						;
				
					END LOOP;
					
					
					-- csak a 2200-nál a 3 sor beírása
					FOR c IN gfcf_2200.FIRST..gfcf_2200.LAST LOOP
											
						EXECUTE IMMEDIATE'
						INSERT INTO '|| v_temp_tables(1) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
						SELECT DISTINCT '|| v_year ||', '''|| gfcf_2200(c).INSTR_ASSET_CODE ||''', '''|| v_NaN_rows(d) ||''', '''|| V_PRICES_NAN(a) ||''', ''NaN''
						FROM GFCF_V
						'
						;
				
					END LOOP;
						
				END LOOP;
				
			END LOOP;
			
		END LOOP;
				
			
			-- N11321G és 11322G minden soránál a T2200A_TEMP táblában
		FOR a IN V_PRICES_NAN.FIRST..V_PRICES_NAN.LAST LOOP
		
			FOR g IN gfcf_sdmx_tab_nan.FIRST..gfcf_sdmx_tab_nan.LAST LOOP
			
				FOR h IN gfcf.FIRST..gfcf.LAST LOOP
				
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(1) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', '''|| gfcf_sdmx_tab_nan(g).INSTR_ASSET_CODE ||''', '''|| gfcf(h).ACTIVITY ||''', '''|| V_PRICES_NAN(a) ||''', ''NaN''
					FROM GFCF_V
					'
					;
				
				END LOOP;

			END LOOP;
			
		END LOOP;
	
			
			-- az N13G minden soránál a T0302A_TEMP táblában
			
			FOR a IN V_PRICES_NAN.FIRST..V_PRICES_NAN.LAST LOOP
			
				FOR h IN 2..gfcf.LAST LOOP -- a _T sort nem írjuk felül
				
					EXECUTE IMMEDIATE'
					INSERT INTO '|| v_temp_tables(2) ||' (TIME_PERIOD, INSTR_ASSET, ACTIVITY, PRICES, OBS_VALUE)
					SELECT DISTINCT '|| v_year ||', '''|| N13G ||''', '''|| gfcf(h).ACTIVITY ||''', '''|| V_PRICES_NAN(a) ||''', ''NaN''
					FROM GFCF_V
					'
					;
				
				END LOOP;
		
			END LOOP;	
			
			
		
		
		-- ha van valahol (null) érték, azt '0' értékre átírjuk az 'L' táblában
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'UPDATE rows from NULL to NaN', '');		

	
		FOR a IN v_temp_tables.FIRST..v_temp_tables.LAST LOOP
		
			FOR h IN gfcf.FIRST..gfcf.LAST LOOP 
			
				FOR i IN gfcf_sdmx_all_2.FIRST..gfcf_sdmx_all_2.LAST LOOP
		
				EXECUTE IMMEDIATE'
				UPDATE '|| v_temp_tables(a) ||' 
				SET OBS_VALUE = (SELECT NVL(OBS_VALUE, ''0'') FROM '|| v_temp_tables(a) ||' WHERE OBS_VALUE IS NULL AND ACTIVITY = '''|| gfcf(h).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_all_2(i).INSTR_ASSET_CODE ||''')
				WHERE OBS_VALUE IS NULL AND ACTIVITY = '''|| gfcf(h).ACTIVITY ||''' AND PRICES = ''L'' AND INSTR_ASSET = '''|| gfcf_sdmx_all_2(i).INSTR_ASSET_CODE ||'''
				'
				;
				
				END LOOP;
			
			END LOOP;
			
		END LOOP;
		
		
INSERT INTO logging_sdmx_2200_0302 (created_on, info, proc_name, message, backtrace)
VALUES (TO_CHAR(CURRENT_TIMESTAMP, 'YYYY.MM.DD HH24:MI:SS.FF'), 'Info', ''|| procName ||'', 'END', '');


END smdx_input;

--procedure smdx_upload(P_EVSZAM VARCHAR2);

-- a végtáblába történő áttöltés		
/* ezt még egyeztetni szükséges
*/


--END smdx_upload;



END SDMX_2200_302;