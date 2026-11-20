# a-r1-engine: Calc's answers

LibreOffice Calc (headless, UNO) loaded each workbook whole, recalculated, and returned every formula cell below. The checks hold these exact workbooks and answers.

## mixed

| cell | formula | Calc |
|---|---|---|
| Data!E2 | `=C2*D2` | 6 |
| Data!E3 | `=C3*D3` | 1.75 |
| Data!E4 | `=C4*D4` | 2 |
| Data!E5 | `=C5*D5` | 5.25 |
| Data!E6 | `=C6*D6` | 4.8 |
| Data!E7 | `=C7*D7` | 7.2 |
| Data!E8 | `=C8*D8` | 4.5 |
| Data!E9 | `=C9*D9` | 12 |
| Data!F2 | `=ROUND(E2*(1-VLOOKUP(B2,$G$2:$H$4,2,0)),2)` | 5.4 |
| Data!F3 | `=ROUND(E3*(1-VLOOKUP(B3,$G$2:$H$4,2,0)),2)` | 1.58 |
| Data!F4 | `=ROUND(E4*(1-VLOOKUP(B4,$G$2:$H$4,2,0)),2)` | 2 |
| Data!F5 | `=ROUND(E5*(1-VLOOKUP(B5,$G$2:$H$4,2,0)),2)` | 4.99 |
| Data!F6 | `=ROUND(E6*(1-VLOOKUP(B6,$G$2:$H$4,2,0)),2)` | 4.8 |
| Data!F7 | `=ROUND(E7*(1-VLOOKUP(B7,$G$2:$H$4,2,0)),2)` | 6.48 |
| Data!F8 | `=ROUND(E8*(1-VLOOKUP(B8,$G$2:$H$4,2,0)),2)` | 4.28 |
| Data!F9 | `=ROUND(E9*(1-VLOOKUP(B9,$G$2:$H$4,2,0)),2)` | 12 |
| Data!B11 | `=IF(A11,"on","off")` | "on" |
| Summary!A1 | `=SUM(Data!E2:E9)` | 43.5 |
| Summary!A2 | `=SUM(Data!F2:F9)` | 41.53 |
| Summary!A3 | `=AVERAGE(Data!C2:C9)` | 10 |
| Summary!A4 | `=COUNT(Data!C2:C9)` | 7 |
| Summary!A5 | `=COUNTA(Data!A1:A12)` | 10 |
| Summary!A6 | `=MIN(Data!D2:D9)` | 0.1 |
| Summary!A7 | `=MAX(Data!E2:E9)` | 12 |
| Summary!A8 | `=MEDIAN(Data!C2:C9)` | 9 |
| Summary!A9 | `=ROUND(STDEV(Data!C2:C9),4)` | 6.1101 |
| Summary!A10 | `=SUMIF(Data!B2:B9,"fruit",Data!E2:E9)` | 14.95 |
| Summary!A11 | `=COUNTIF(Data!B2:B9,"veg")` | 3 |
| Summary!A12 | `=AVERAGEIF(Data!C2:C9,">5")` | 12.6 |
| Summary!A13 | `=SUMIF(Data!C2:C9,">=10")` | 47 |
| Summary!A14 | `=PRODUCT(Data!H2:H3)*100` | 0.5000000000000001 |
| Summary!A15 | `=POWER(A4,2)+SQRT(16)-ABS(-3)` | 50 |
| Summary!A16 | `=MOD(A4*7,5)` | 4 |
| Summary!A17 | `=INT(-A3)` | -10 |
| Summary!A18 | `=ROUNDUP(A3,1)` | 10 |
| Summary!A19 | `=ROUNDDOWN(A3,1)` | 10 |
| Summary!B1 | `=INDEX(Data!A2:A9,MATCH(MAX(Data!E2:E9),Data!E2:E9,0))` | "  kale  " |
| Summary!B2 | `=VLOOKUP("fig",Data!A2:F9,6,0)` | 6.48 |
| Summary!B3 | `=VLOOKUP("zucchini",Data!A2:F9,6,0)` | {"error": "#N/A"} |
| Summary!B4 | `=IFERROR(B3,"none")` | "none" |
| Summary!B5 | `=ISERROR(B3)` | true |
| Summary!B6 | `=IF(ISERROR(B3),"missing",B3)` | "missing" |
| Summary!B7 | `=IF(AND(A1>10,OR(A4=7,A4=8)),"big","small")` | "big" |
| Summary!B8 | `=NOT(ISBLANK(Data!A12))` | false |
| Summary!B9 | `=ISNUMBER(Data!C9)` | false |
| Summary!B10 | `=ISTEXT(Data!C9)` | true |
| Summary!B11 | `=Data!C9+1` | 7 |
| Summary!B12 | `=CONCATENATE(UPPER(LEFT(Data!A2,1)),LOWER(MID(Data!A2,2,10)),": ",A1)` | "Apple: 43.5" |
| Summary!B13 | `=LEN(Data!A9)&"/"&LEN(TRIM(Data!A9))` | "8/4" |
| Summary!B14 | `=RIGHT(B1,3)&"-"&B2` | "e  -6.48" |
| Summary!B15 | `=MATCH("herb",Data!G2:G4,0)` | 2 |
| Summary!B16 | `=INDEX(Data!G2:H4,B15,2)*A1` | 2.1750000000000003 |
| Summary!B17 | `=Data!B11&" "&A4` | "on 7" |
| Summary!B18 | `=A1/(A4-A4)` | {"error": "#DIV/0!"} |
| Summary!B19 | `=IFERROR(B18,-1)+B16` | 1.1750000000000003 |
| Summary!C1 | `=Calc!A1*2` | 16 |
| Summary!C2 | `=SUM(Calc!A1:A3)` | 18.175 |
| Summary!C3 | `=COUNTIF(Calc!A1:A5,"<>x")` | 4 |
| Summary!C4 | `=Calc!B1` | "apple: 43.5" |
| Summary!C5 | `=A2>A1` | false |
| Summary!C6 | `=A1-A2&""` | "1.97" |
| Summary!C7 | `=-A4^2` | 49 |
| Summary!C8 | `=2^3^2` | 64 |
| Summary!C9 | `=50%*A4` | 3.5 |
| Summary!C10 | `="3"+Data!A11` | 4 |
| Summary!C11 | `=SUM(Data!A2:A3)` | 0 |
| Summary!C12 | `=Data!A2+1` | {"error": "#VALUE!"} |
| Calc!A1 | `=Summary!A4+1` | 8 |
| Calc!A2 | `=Summary!B16` | 2.1750000000000003 |
| Calc!A3 | `=LEN(Summary!B1)` | 8 |
| Calc!B1 | `=IF(Summary!C5,UPPER(Summary!B12),LOWER(Summary!B12))` | "apple: 43.5" |

## chain

| cell | formula | Calc |
|---|---|---|
| Sheet1!A2 | `=A1+1` | 2 |
| Sheet1!A38 | `=A37+1` | 38 |
| Sheet1!A39 | `=A38+1` | 39 |
| Sheet1!A40 | `=A39/(A1-1)` | {"error": "#DIV/0!"} |
| Sheet1!A41 | `=A40+1` | {"error": "#DIV/0!"} |
| Sheet1!A99 | `=A98+1` | {"error": "#DIV/0!"} |
| Sheet1!A100 | `=A99+1` | {"error": "#DIV/0!"} |
| Sheet1!B1 | `=SUM(A1:A39)` | 780 |
| Sheet1!B2 | `=SUM(A1:A100)` | {"error": "#DIV/0!"} |
| Sheet1!B3 | `=COUNT(A1:A100)` | 39 |
| Sheet1!B4 | `=IFERROR(A100,"caught")` | "caught" |
| Sheet1!B5 | `=ISERROR(A41)` | true |
| Sheet1!B6 | `=A100` | {"error": "#DIV/0!"} |
| Sheet1!B7 | `=COUNTA(A1:A100)` | 100 |
| Sheet1!B8 | `=MAX(A1:A39)` | 39 |
| Sheet1!B9 | `=IF(ISERROR(A60),A39*2,A60)` | 78 |
| Sheet1!C1 | `=C2*1+1` | 101 |
| Sheet1!C2 | `=C3*1+1` | 100 |
| Sheet1!C38 | `=C39*1+1` | 64 |
| Sheet1!C39 | `=C40*1+1` | 63 |
| Sheet1!C40 | `=C41*1+1` | 62 |
| Sheet1!C41 | `=C42*1+1` | 61 |
| Sheet1!C99 | `=C100*1+1` | 3 |
| Sheet1!C100 | `=LEN("ab")` | 2 |
| Sheet1!D1 | `=C1` | 101 |
| Sheet2!A1 | `=VLOOKUP("nope",Sheet1!A1:A5,1,0)` | {"error": "#N/A"} |
| Sheet2!A2 | `=UPPER(A1)` | {"error": "#N/A"} |
| Sheet2!A3 | `=CONCATENATE(Sheet2!A2,"x")` | {"error": "#N/A"} |
| Sheet2!A10 | `=UPPER(A9)` | {"error": "#N/A"} |
| Sheet2!A99 | `=CONCATENATE(Sheet2!A98,"x")` | {"error": "#N/A"} |
| Sheet2!A100 | `=UPPER(A99)` | {"error": "#N/A"} |
| Sheet2!B1 | `=ISERROR(A100)` | true |
| Sheet2!B2 | `=IFERROR(LEN(A100),0)` | 0 |
| Sheet2!C2 | `=IF(LEN(C1)>20,LEFT(C1,5),C1&"+")` | "start+" |
| Sheet2!C3 | `=IF(LEN(C2)>20,LEFT(C2,5),C2&"+")` | "start++" |
| Sheet2!C10 | `=IF(LEN(C9)>20,LEFT(C9,5),C9&"+")` | "start+++++++++" |
| Sheet2!C99 | `=IF(LEN(C98)>20,LEFT(C98,5),C98&"+")` | "start+++++++++++++" |
| Sheet2!C100 | `=IF(LEN(C99)>20,LEFT(C99,5),C99&"+")` | "start++++++++++++++" |
| Sheet2!D1 | `=C100` | "start++++++++++++++" |
| Sheet2!D2 | `=Sheet1!A100&""` | {"error": "#DIV/0!"} |
| Sheet2!D3 | `=Sheet1!C1+Sheet1!A39` | 140 |

The chain rows not shown follow the same pattern (see books.json and calc.json for all 400+ formulas).
