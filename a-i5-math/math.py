import json
FIX = {"Sheet1": {
  "A1": 1, "A2": 2, "A3": "3", "A4": True, "A6": 4.5, "A7": -2, "A8": "abc",
  "B1": 3, "B2": 1, "B3": 4, "B4": 1, "B5": 5, "B6": 9,
  "C1": 1, "C2": {"error": "#DIV/0!"}, "C3": 2,
  "D1": "x", "D3": "y",
  "E1": "apple", "E2": "banana", "E3": "Apple", "E4": "cherry", "E5": 10, "E6": 20, "E7": "b*n", "E9": "10",
  "F1": 1, "F2": 2, "F3": 3, "F4": 4, "F5": 5, "F6": 6, "F7": 7, "F8": 8, "F9": 9,
  "H1": False, "H2": True, "H3": 0,
}}
B1 = """=SUM(A1:A8)|=SUM(B1:B6)|=SUM(1,2,3)|=SUM(A1:A8,10)|=SUM("3",1)|=SUM(TRUE,1)|=SUM(A3)|=SUM(G1:G5)|=SUM(C1:C3)|=SUM("abc")|=SUM(A4)|=SUM(A1:B6)|=SUM(H1:H3)|=SUM(D1:D3)|=SUM(A1,A2,A3)|=SUM(0.1,0.2)
=AVERAGE(A1:A8)|=AVERAGE(B1:B6)|=AVERAGE(G1:G5)|=AVERAGE(D1:D3)|=AVERAGE(1,"2",TRUE)|=AVERAGE(C1:C3)|=AVERAGE(A3)|=AVERAGE(H1:H3)|=AVERAGE(B1:B6,A1:A2)
=MIN(A1:A8)|=MIN(G1:G5)|=MIN(B1:B6,0.5)|=MIN("x")|=MIN(C1:C3)|=MIN(D1:D3)|=MIN("-7",1)|=MIN(H1:H3)|=MIN(A7,A6)
=MAX(A1:A8)|=MAX(G1:G5)|=MAX(B1:B6,-1)|=MAX(TRUE,0)|=MAX("7",1)|=MAX(C1:C3)|=MAX(D1:D3)|=MAX(-1,-5)|=MAX(A7)
=COUNT(A1:A8)|=COUNT(G1:G5)|=COUNT(1,"2","x",TRUE)|=COUNT(C1:C3)|=COUNT(D1:D3)|=COUNT(B1:B6)|=COUNT(H1:H3)|=COUNT(A3)|=COUNT(1/0)
=COUNTA(A1:A8)|=COUNTA(G1:G5)|=COUNTA(C1:C3)|=COUNTA(1,"","x")|=COUNTA(D1:D3)|=COUNTA(E1:E9)|=COUNTA(1/0,1)
=PRODUCT(B1:B6)|=PRODUCT(A1:A8)|=PRODUCT(G1:G5)|=PRODUCT(2,"3")|=PRODUCT(C1:C3)|=PRODUCT(D1:D3)|=PRODUCT(A7,A6,-1)|=PRODUCT(TRUE,5)
=MEDIAN(B1:B6)|=MEDIAN(A1:A8)|=MEDIAN(1,2,3,4)|=MEDIAN(G1:G5)|=MEDIAN(B1:B5)|=MEDIAN(C1:C3)|=MEDIAN(D1:D3)|=MEDIAN(5,"1",3)
=STDEV(B1:B6)|=STDEV(A1:A8)|=STDEV(1)|=STDEV(1,2,"3")|=STDEV(C1:C3)|=STDEV(G1:G5)|=STDEV(2,4,4,4,5,5,7,9)|=STDEV(H1:H3)|=STDEV(D1:D3,1,2)"""
B2 = """=ROUND(2.5,0)|=ROUND(-2.5,0)|=ROUND(1.005,2)|=ROUND(1234.567,-2)|=ROUND(2.345,2)|=ROUND(A6,0)|=ROUND("2.5",0)|=ROUND(1/0,0)|=ROUND("abc",1)|=ROUND(2.5)|=ROUND(0.5,0)|=ROUND(-0.5,0)|=ROUND(2.15,1)|=ROUND(TRUE,0)|=ROUND(A5,0)|=ROUND(5.5,-1)|=ROUND(3.14159,3)|=ROUND(2.5,0.9)|=ROUND(1,1/0)|=ROUND(A8,1)|=ROUND(-1.55,1)
=ROUNDUP(1.21,1)|=ROUNDUP(-1.21,1)|=ROUNDUP(3.2)|=ROUNDUP(1234,-2)|=ROUNDUP(0.1+0.2,1)|=ROUNDUP(5,0)|=ROUNDUP(2.0000001,2)|=ROUNDUP("x",1)|=ROUNDUP(C2,1)
=ROUNDDOWN(1.29,1)|=ROUNDDOWN(-1.29,1)|=ROUNDDOWN(1299,-2)|=ROUNDDOWN(2.5)|=ROUNDDOWN(-2.5)|=ROUNDDOWN(0.3,1)|=ROUNDDOWN(A8,0)
=INT(2.7)|=INT(-2.7)|=INT("3.9")|=INT(A8)|=INT(TRUE)|=INT(-0.5)|=INT(5)|=INT(A5)|=INT(1/0)
=MOD(10,3)|=MOD(-10,3)|=MOD(10,-3)|=MOD(-10,-3)|=MOD(5,0)|=MOD(5.5,2)|=MOD(0,5)|=MOD(1/0,2)|=MOD(7,1/0)|=MOD("7",2)|=MOD(A8,2)|=MOD(-1.5,1)|=MOD(3,A5)
=ABS(-3.5)|=ABS("-2")|=ABS(A8)|=ABS(A5)|=ABS(C2)|=ABS(TRUE)|=ABS(0)
=POWER(2,10)|=POWER(2,-1)|=POWER(-8,1/3)|=POWER(0,0)|=POWER(0,-1)|=POWER(-1,0.5)|=POWER("2",3)|=POWER(4,0.5)|=POWER(-2,3)|=POWER(A8,2)|=POWER(1/0,2)|=POWER(10,400)
=SQRT(16)|=SQRT(2)|=SQRT(-1)|=SQRT(0)|=SQRT("9")|=SQRT(A8)|=SQRT(A5)|=SQRT(C2)|=SQRT(TRUE)"""
B3 = """=SUMIF(F1:F8,">4")|=SUMIF(E1:E8,"apple",F1:F8)|=SUMIF(E1:E8,"<>apple",F1:F8)|=SUMIF(F1:F8,"<"&F3)|=SUMIF(E1:E8,"b*",F1:F8)|=SUMIF(F1:F8,">100")|=SUMIF(E1:E8,"cherry",F1)|=SUMIF(E1:E8,"apple",F1:F2)|=SUMIF(E1:E9,10,F1:F9)|=SUMIF(F1:F8,4)|=SUMIF(F1:F8,"4")|=SUMIF(F1:F8,"=4")|=SUMIF(F1:F8,"<=3")|=SUMIF(F1:F8,">=7")|=SUMIF(E1:E8,"*an*",F1:F8)|=SUMIF(E1:E8,"?pple",F1:F8)|=SUMIF(A1:A8,">1")|=SUMIF(C1:C3,">0")|=SUMIF(B1:B6,1)|=SUMIF(E1:E9,"",F1:F9)
=COUNTIF(E1:E8,"apple")|=COUNTIF(E1:E8,"a*")|=COUNTIF(F1:F8,">=3")|=COUNTIF(F1:F8,"<>4")|=COUNTIF(E1:E8,"<>apple")|=COUNTIF(E1:E9,10)|=COUNTIF(E1:E9,"10")|=COUNTIF(E1:E8,">15")|=COUNTIF(E1:E8,"b?nana")|=COUNTIF(E1:E9,"")|=COUNTIF(E1:E9,"=")|=COUNTIF(E1:E9,"<>")|=COUNTIF(E1:E9,"*")|=COUNTIF(A1:A8,3)|=COUNTIF(A1:A8,"3")|=COUNTIF(A1:A8,TRUE)|=COUNTIF(H1:H3,FALSE)|=COUNTIF(E1:E8,"b*n")|=COUNTIF(E1:E8,"APPLE")|=COUNTIF(C1:C3,">0")|=COUNTIF(F1:F8,">"&"5")|=COUNTIF(E1:E8,"<c")|=COUNTIF(E1:E8,">=b")|=COUNTIF(G1:G5,"")|=COUNTIF(F1:F8,"abc")|=COUNTIF(B1:B6,1)|=COUNTIF(E1:E8,"~*")|=COUNTIF(F1:F8,"<>")|=COUNTIF(A1:A8,"<>3")
=AVERAGEIF(F1:F8,">4")|=AVERAGEIF(E1:E8,"apple",F1:F8)|=AVERAGEIF(F1:F8,">100")|=AVERAGEIF(E1:E8,"cherry",F1:F8)|=AVERAGEIF(E1:E8,"b*",F1:F8)|=AVERAGEIF(A1:A8,">0")|=AVERAGEIF(E1:E9,10,F1:F9)|=AVERAGEIF(F1:F8,"<>4")|=AVERAGEIF(C1:C3,">0")|=AVERAGEIF(E1:E8,"apple",F1)"""
groups = {"b1": B1, "b2": B2, "b3": B3}
allf = []
for g, txt in groups.items():
    for line in txt.split("\n"):
        allf += [(g, f) for f in line.split("|")]
json.dump({"groups": allf}, open("/tmp/lo-tools/math-groups.json", "w"))
json.dump({"sheets": FIX, "formula_sheet": "Sheet1", "formulas": [f for _, f in allf]}, open("/tmp/lo-tools/math.json", "w"))
print(len(allf))
