-- tworzenie bazy danych
CREATE database IF NOT EXISTS s304179;
-- tworzenie schematu firma
CREATE SCHEMA firma;
-- tworzenie roli
CREATE role księgowosc;
/*GRANT SELECT ON <tabela> TO ksiegowosc;*/


CREATE TABLE IF NOT EXISTS firma.pracownicy
(
id_pracownika VARCHAR(5) UNIQUE NOT NULL,
imie VARCHAR(20) NOT NULL,
nazwisko VARCHAR(30) NOT NULL,
adres VARCHAR(50),
telefon VARCHAR(20)
);
COMMENT ON TABLE firma.pracownicy IS 'wszyscy pracownicy firmy';

CREATE TABLE IF NOT EXISTS firma.godziny
(
id_godziny INT UNIQUE NOT NULL,
data DATE,
liczba_godzin FLOAT,
id_pracownika VARCHAR(5) 
);
COMMENT ON TABLE firma.godziny IS 'Godziny pracy';

CREATE TABLE IF NOT EXISTS firma.pensje
(
id_pensja VARCHAR(3) UNIQUE NOT NULL,
stanowisko VARCHAR(30),
kwota FLOAT
);
COMMENT ON TABLE firma.pensje IS 'pensje pracowników w firmie';

CREATE TABLE IF NOT EXISTS firma.premie
(
id_premii INT UNIQUE NOT NULL,
rodzaj VARCHAR(30),
kwota FLOAT(7)
);
COMMENT ON TABLE firma.premie IS 'Możliwe premie w firmie';

CREATE TABLE IF NOT EXISTS firma.wynagrodzenie
(
id_wynagrodzenia INT UNIQUE NOT NULL,
data DATE, 
id_pracownika VARCHAR(5),
id_godziny INT,
id_pensji VARCHAR(3),
id_premii INT
);
COMMENT ON TABLE firma.wynagrodzenie IS 'Wynagrodzenie pracownika';

ALTER TABLE firma.pracownicy ADD CONSTRAINT id_pracownika PRIMARY KEY(id_pracownika);
ALTER TABLE firma.godziny ADD CONSTRAINT id_godziny PRIMARY KEY(id_godziny);
ALTER TABLE firma.pensje ADD CONSTRAINT id_pensja PRIMARY KEY(id_pensja);
ALTER TABLE firma.premie ADD CONSTRAINT id_premii PRIMARY KEY(id_premii);
ALTER TABLE firma.wynagrodzenie ADD CONSTRAINT id_wynagrodzenia PRIMARY KEY(id_wynagrodzenia);
ALTER TABLE firma.godziny ADD CONSTRAINT id_pracownika FOREIGN KEY(id_pracownika) REFERENCES firma.pracownicy(id_pracownika);
ALTER TABLE firma.wynagrodzenie ADD CONSTRAINT id_pracownika FOREIGN KEY(id_pracownika) REFERENCES firma.pracownicy(id_pracownika);
ALTER TABLE firma.wynagrodzenie ADD CONSTRAINT id_premii FOREIGN KEY(id_premii) REFERENCES firma.premie(id_premii);
ALTER TABLE firma.wynagrodzenie ADD CONSTRAINT id_pensji FOREIGN KEY(id_pensji) REFERENCES firma.pensje(id_pensja);
ALTER TABLE firma.wynagrodzenie ADD CONSTRAINT id_godziny FOREIGN KEY(id_godziny) REFERENCES firma.godziny(id_godziny);


-- wczytanie danych do tabeli pracownicy
INSERT INTO firma.pracownicy VALUES
('S1011', 'Maria',  'Nowak','34-350 Katowice ul. Kasztanowa 23','982515462'),
('S1024', 'Jan', 'Kowalski','45-210 Warszawa ul. Wiejska 56a','515289264'),
('S1045', 'Anna',  'Jabłońska','34-350 Katowice ul. Maślana 345','462982515'),
('P100', 'Anna', 'Jeleń','44-456 Gdańsk ul. Martwa 34d ','829456215'),
('P105', 'Jarosław', 'Nicpoń','33-531 Tychy ul. Zielona 2','215654928'),
('P108', 'Joanna', 'Nosek','32-281 Kraków ul. Miła 13a','829215564'),
('P120', 'Jan', 'Kałuża','45-321 Wrocław ul. Długa 14b','465251289'),
('P130', 'Jerzy', 'Lis','21-978 Zielona Góra ul. Szeroka 321','928515462'),
('P123', 'Olga', 'Nowacka','21-978 Zielona Góra ul. Biała 33','426928515'),
('S1034',	'Marek', 'Potocki','33-351 Tychy ul. Komedii 321','825264515');

-- wczytanie danych do tabeli godziny
INSERT INTO firma.godziny VALUES
(1,'2020-03-14',11,'S1024'),
(2,'2020-03-23',10,'S1011'),
(3,'2020-03-24',4,'P123'),
(4,'2020-03-21',3,'P120'),
(5,'2020-03-16',17,'S1045'),
(6,'2020-03-24',9,'P130'),
(7,'2020-03-22',11,'P100'),
(8,'2020-03-23',2,'P105'),
(9,'2020-03-11',0,'S1034'),
(10,'2020-03-15',6,'P108');

-- wczytanie danych do tabeli pensja
INSERT INTO firma.pensje VALUES
('K01','kierownik',7000),
('K02','sekretarz',2500),
('K03','ksiegowy',3500),
('K04','sprzatacz',2500),
('K05','manadżer',5000),
('K06','pracownik zewnetrzny',3200),
('K07','kontroler jakosci',2700),
('K08','konsultant',4000),
('K09','konsultant do spraw sprzedazy',4000),
('K10','pomocnik',3000);

-- wczytanie danych do tabeli premia
INSERT INTO firma.premie VALUES
(1,'uznaniowa',300),
(2,'motywacyjna',500),
(3,'miesieczna',200),
(4,'okolicznosciowa',1000),
(5,'frekwencyjna',300),
(6,'wczasy pod grusza',500),
(7,'mundurowka',1000),
(8,'trzynastka',250),
(9,'kwartalna',700),
(10,'swiateczna',300);

-- wczytanie danych do tabeli wynagrodzenie
INSERT INTO firma.wynagrodzenie VALUES
(1,'2020-03-14','S1011',5,'K04',5),
(2,'2020-03-14','P123',4,'K03',3),
(3,'2020-03-14','P130',6,'K08',NULL),
(4,'2020-03-14','P105',1,'K05',3),
(5,'2020-03-14','S1024',2,'K02',8),
(6,'2020-03-14','P108',3,'K10',10),
(7,'2020-03-14','S1045',9,'K09',3),
(8,'2020-03-14','P100',10,'K06',NULL),
(9,'2020-03-14','S1034',7,'K07',1),
(10,'2020-03-14','P120',8,'K01',4);

-- zad5
-- a) W tabeli godziny, dodaj pola przechowujące informacje o miesiącu oraz numerze tygodnia danego roku (rok ma 53 tygodnie). Oba mają być typu DATE. 
ALTER TABLE firma.godziny ADD COLUMN miesiac INT;
UPDATE firma.godziny SET miesiac=DATE_PART('month',data)
SELECT DATE_PART('month',data) FROM firma.godziny
-- ////
ALTER TABLE firma.godziny ADD COLUMN tydzien INT
UPDATE firma.godziny SET tydzien=DATE_PART('week',data)
SELECT DATE_PART('week',data) FROM firma.godziny

-- b) W tabeli wynagrodzenie zamień pole data na typ tekstowy. 
ALTER TABLE firma.wynagrodzenie ALTER COLUMN data TYPE VARCHAR(20);
-- c) Pole ‘rodzaj’ w tabeli premia ma przyjmować także wartość ‘brak’. Wtedy kwota premii równa się zero. 
INSERT INTO firma.premie(id_premii,rodzaj,kwota) VALUES (11,'brak',0)

-- zad6
-- a)Wyświetl tylko id pracownika oraz jego nazwisko 
SELECT fp.id_pracownika, fp.nazwisko FROM firma.pracownicy as fp 
-- b) Wyświetl id pracowników, których płaca jest większa niż 1000 
SELECT fp.id_pracownika as placa FROM firma.pracownicy as fp, firma.pensje as fpen, firma.premie as fpr, firma.wynagrodzenie as fw 
WHERE fw.id_pracownika=fp.id_pracownika AND fw.id_premii=fpr.id_premii AND fw.id_pensji=fpen.id_pensja AND (fpen.kwota+fpr.kwota) >1000
-- c) Wyświetl id pracowników nie posiadających premii, których płaca jest większa niż 2000  
SELECT fp.id_pracownika FROM firma.pracownicy as fp, firma.pensje as fpen, firma.wynagrodzenie as fw 
WHERE fw.id_pracownika=fp.id_pracownika AND fw.id_pensji=fpen.id_pensja AND fpen.kwota > 2000
-- d) Wyświetl  pracowników, których pierwsza litera imienia zaczyna się na literę ‘J’ 
SELECT * FROM firma.pracownicy fp  WHERE fp.imie LIKE 'J%'
-- e) Wyświetl pracowników, których nazwisko zawiera literę ‘n’ oraz imię kończy się na literę ‘a’ 
SELECT * FROM firma.pracownicy fp  WHERE fp.nazwisko LIKE '%n%' AND fp.imie LIKE '%a'
-- f) Wyświetl imię i nazwisko pracowników oraz liczbę ich nadgodzin, przyjmując, iż standardowy czas pracy to 160 h miesięcznie. 
SELECT fp.imie, fp.nazwisko, (fg.liczba_godzin*20-160) as nadgodziny from firma.pracownicy fp, firma.godziny fg WHERE fp.id_pracownika = fg.id_pracownika 
-- g) Wyświetl imię i nazwisko pracowników, których pensja zawiera się  w przedziale 1500 – 3000  
SELECT fp.imie, fp.nazwisko from firma.pracownicy fp, firma.pensje fpen, firma.wynagrodzenie fw WHERE fp.id_pracownika = fw.id_pracownika AND fw.id_pensji=fpen.id_pensja AND fpen.kwota BETWEEN 1500 AND 3000
-- h) Wyświetl imię i nazwisko pracowników, którzy pracowali w nadgodzinach  i nie otrzymali premii 
SELECT fp.imie, fp.nazwisko FROM firma.pracownicy fp 
JOIN firma.wynagrodzenie fw ON fw.id_pracownika = fp.id_pracownika 
JOIN firma.godziny fg ON fg.id_pracownika = fp.id_pracownika 
WHERE (fg.liczba_godzin * 20 - 160) > 0 AND fw.id_premii IS NULL 


-- zad7
-- a) Uszereguj pracowników według pensji 
SELECT fw.id_pracownika, fpen.kwota FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
ORDER BY fpen.kwota DESC
-- b) Uszereguj pracowników według pensji i premii malejąco 
SELECT fw.id_pracownika, fpen.kwota, fpr.kwota FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
JOIN firma.premie fpr ON fw.id_premii = fpr.id_premii
ORDER BY fpen.kwota DESC, fpr.kwota DESC
-- c) Zlicz i pogrupuj pracowników według pola ‘stanowisko’ 
SELECT COUNT(fw.id_pracownika), fpen.stanowisko FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
GROUP BY fpen.stanowisko
-- d) Policz średnią, minimalną i maksymalną płacę dla stanowiska ‘kierownik’ (jeżeli takiego nie masz, to przyjmij dowolne inne) 
SELECT MIN(fpen.kwota) AS minimalna,MAX(fpen.kwota) AS maksymalna, AVG(fpen.kwota) AS srednia, fpen.stanowisko FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
GROUP BY fpen.stanowisko
-- e) Policz sumę wszystkich wynagrodzeń 
SELECT SUM(COALESCE(fpr.kwota,0))+ SUM(COALESCE(fpen.kwota,0)) FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
JOIN firma.premie fpr ON fpr.id_premii=fw.id_premii
-- f) Policz sumę wynagrodzeń w ramach danego stanowiska 
SELECT SUM(COALESCE(fpr.kwota,0))+ SUM(COALESCE(fpen.kwota,0)), fpen.stanowisko FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
JOIN firma.premie fpr ON fpr.id_premii=fw.id_premii
GROUP BY fpen.stanowisko
-- g) Wyznacz liczbę premii przyznanych dla pracowników danego stanowiska 
SELECT COUNT(fpr.rodzaj) AS ilosc_premii, fpen.stanowisko FROM firma.pensje fpen 
JOIN firma.wynagrodzenie fw ON fpen.id_pensja = fw.id_pensji
JOIN firma.premie fpr ON fpr.id_premii=fw.id_premii
GROUP BY fpen.stanowisko
-- h) Usuń wszystkich pracowników mających pensję mniejszą niż 1200 zł 
DELETE 
FROM firma.wynagrodzenie fw
USING firma.pensje kpen
WHERE kpen.kwota <1200 AND fw.id_pensji = kpen.id_pensja

--zad8
-- a) Zmodyfikuj numer telefonu w tabeli pracownicy, dodając do niego kierunkowy dla Polski w nawiasie (+48) 
UPDATE firma.pracownicy fp SET telefon='(+48)'||fp.telefon
-- b) Zmodyfikuj kolumnę telefon w tabeli pracownicy tak, aby numer oddzielony był myślnikami wg wzoru: ‘555-222-333’ 
UPDATE firma.pracownicy fp SET telefon=SUBSTRING(fp.telefon,1,8)||'-'||SUBSTRING(fp.telefon,9,3)||'-'||SUBSTRING(fp.telefon,12,3)
-- c) Wyświetl dane pracownika, którego nazwisko jest najdłuższe, używając wielkich liter 
SELECT upper(fp.imie) AS imie,upper(fp.nazwisko) AS nazwisko,upper(fp.adres) AS adres , length(fp.nazwisko) AS dlugosc FROM firma.pracownicy fp ORDER BY length(fp.nazwisko) DESC
-- d) Wyświetl dane pracowników i ich pensje zakodowane przy pomocy algorytmu md5
ALTER TABLE firma.pensje ALTER COLUMN kwota TYPE VARCHAR(15);
SELECT fp.*, MD5(fpen.kwota) as md5_kwota FROM firma.pracownicy fp 
JOIN firma.wynagrodzenie fw ON fw.id_pracownika = fp.id_pracownika 
JOIN firma.pensje fpen ON fw.id_pensji = fpen.id_pensja

--zad9
/* Utwórz zapytanie zwracające w wyniku treść wg poniższego szablonu: 
Pracownik Jan Nowak, w dniu 7.08.2017 otrzymał pensję całkowitą na kwotę 7540 zł, gdzie wynagrodzenie zasadnicze wynosiło: 5000 zł, premia: 2000 zł, nadgodziny: 540 zł.  */
SELECT CONCAT('Pracownik ',fp.imie,' ',fp.nazwisko,', w dniu ',fw.data,' pensje calkowita na kwote ',COALESCE(fpr.kwota,0)+COALESCE(fpen.kwota,0), 'zl, gdzie wynagrodzenie zasadnicze wynosilo: ',fpen.kwota,'zl, premia: ',fpr.kwota,'zl, nadgodziny: ',fpen.kwota) AS informacja
FROM firma.wynagrodzenie fw 
LEFT JOIN firma.pensje fpen ON fw.id_pensji=fpen.id_pensja
LEFT JOIN firma.premie fpr ON fw.id_premii=fpr.id_premii
LEFT JOIN firma.pracownicy fp ON fw.id_pracownika=fp.id_pracownika

