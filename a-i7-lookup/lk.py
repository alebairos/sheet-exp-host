import json
FIX = {"Sheet1": {
  "A1": 10, "B1": "ten", "C1": 1.5,
  "A2": 20, "B2": "twenty", "C2": 2.5,
  "A3": 30, "B3": "thirty", "C3": {"error": "#N/A"},
  "A4": 40, "B4": "forty", "C4": 4,
  "A5": 50, "B5": "fifty",
  "E1": "apple", "F1": 1, "E2": "Banana", "F2": 2, "E3": "cherry", "F3": 3, "E4": "date", "F4": 4, "E5": "fig", "F5": 5,
  "G1": 3, "G2": "x", "G3": 1, "G4": 3, "G5": True, "G7": "3",
  "I1": 5, "J1": 10, "K1": 15, "L1": 20, "I2": "a", "J2": "b", "K2": "c", "L2": "d",
  "M1": 1, "N1": "a", "M2": 2, "N2": "b", "M3": 2, "N3": "c", "M4": 2, "N4": "d", "M5": 3, "N5": "e",
  "P1": 7,
}, "Sheet2": {"A1": "k1", "B1": 100, "A2": "k2", "B2": 200}}
B1 = """=VLOOKUP(30,A1:C5,2,0)|=VLOOKUP(30,A1:C5,2,FALSE)|=VLOOKUP(35,A1:C5,2,0)|=VLOOKUP(35,A1:C5,2,1)|=VLOOKUP(35,A1:C5,2)|=VLOOKUP(5,A1:C5,2,1)|=VLOOKUP(99,A1:C5,2)|=VLOOKUP(30,A1:C5,4,0)|=VLOOKUP(30,A1:C5,0,0)|=VLOOKUP(30,A1:C5,1,0)|=VLOOKUP(50,A1:C5,3,0)|=VLOOKUP("30",A1:C5,2,0)|=VLOOKUP("banana",E1:F5,2,0)|=VLOOKUP("b*",E1:F5,2,0)|=VLOOKUP("c?erry",E1:F5,2,0)|=VLOOKUP("cat",E1:F5,2,1)|=VLOOKUP("zzz",E1:F5,2,TRUE)|=VLOOKUP("a",E1:F5,2,1)|=VLOOKUP(1/0,A1:C5,2,0)|=VLOOKUP(30,A1:C5,"2",0)|=VLOOKUP(30,A1:C5,2.9,0)|=VLOOKUP(20,A1:C5,3,0)|=VLOOKUP(40,A1:C5,3,1)|=VLOOKUP(30,A1:C5,3,0)|=VLOOKUP(3,G1:G7,1,0)|=VLOOKUP("3",G1:G7,1,0)|=VLOOKUP("k2",Sheet2!A1:B2,2,0)|=VLOOKUP("fig",E1:F5,2,0)|=VLOOKUP(2,M1:N5,2,0)|=VLOOKUP(2,M1:N5,2,1)|=VLOOKUP(2.5,M1:N5,2,1)|=VLOOKUP(10,A1:C5,2,1)|=VLOOKUP(50,A1:C5,2,1)|=VLOOKUP(P1,A1:C5,2,1)|=VLOOKUP(30,A1:C5,-1,0)|=VLOOKUP(30,A1:C5,2,"x")|=VLOOKUP(30,A1:C5,2,2)|=VLOOKUP(A5,A1:C5,2,0)|=VLOOKUP("Apple",E1:F5,2,0)|=VLOOKUP("~*",E1:F5,2,0)|=VLOOKUP(30,A1:A5,1,0)|=VLOOKUP(30,A1:C5,2,0)&"!"
=INDEX(A1:C5,2,2)|=INDEX(A1:C5,2)|=INDEX(A1:A5,3)|=INDEX(A1:C5,6,1)|=INDEX(A1:C5,1,4)|=INDEX(I1:L1,3)|=INDEX(I1:L1,1,3)|=INDEX(A1:C5,-1,1)|=INDEX(A1:C5,"2",2)|=INDEX(A1:C5,2.7,1)|=INDEX(A1:C5,5,3)|=INDEX(A1:C5,3,3)|=INDEX(A1:A5,1/0)|=INDEX(A1:C5,MATCH(40,A1:A5,0),2)|=INDEX(A1:C5,1,1)|=INDEX(B1:B5,5)|=INDEX(Sheet2!A1:B2,2,2)|=INDEX(A1:A5,0)|=INDEX(A1:A5,6)|=INDEX(A1:C5,0,0)|=INDEX(I1:L2,2,4)|=INDEX(I1:L2,2)|=INDEX(A1:A5,2,1)|=INDEX(A1:A5,2,2)|=INDEX(A1:C5,"x",1)|=INDEX(A1:C5,3,2)&"?"|=INDEX(G1:G7,6)|=INDEX(A1:C5,MATCH("fifty",B1:B5,0),1)
=MATCH(30,A1:A5,0)|=MATCH(35,A1:A5,0)|=MATCH(35,A1:A5,1)|=MATCH(35,A1:A5)|=MATCH(5,A1:A5,1)|=MATCH(99,A1:A5,1)|=MATCH("BANANA",E1:E5,0)|=MATCH("b*",E1:E5,0)|=MATCH("d?te",E1:E5,0)|=MATCH("cat",E1:E5,1)|=MATCH(15,I1:L1,1)|=MATCH(15,I1:L1,0)|=MATCH(12,I1:L1)|=MATCH(3,G1:G7,0)|=MATCH("3",G1:G7,0)|=MATCH(2,M1:M5,0)|=MATCH(2,M1:M5,1)|=MATCH(30,A1:C5,0)|=MATCH(1/0,A1:A5,0)|=MATCH(30,A1:A5,2)|=MATCH("zzz",E1:E5,1)|=MATCH("a",E1:E5,1)|=MATCH("x",G1:G7,0)|=MATCH(30,A1:A5,"x")|=MATCH(10,A1:A5,0)|=MATCH("c",I2:L2,0)|=MATCH("cc",I2:L2,1)|=MATCH(50,A1:A5,1)|=MATCH(30,A3,0)|=MATCH(30,A1:A5,0.5)|=MATCH(1,G1:G7,0)|=MATCH(P1,A1:A5,1)|=MATCH("*",E1:E5,0)|=MATCH(2.5,M1:M5,1)"""
allf = []
for g, txt in {"b1": B1, "b2": B2}.items() if False else []:
    pass
lines = B1.split("\n")
for f in lines[0].split("|"): allf.append(("b1", f))
for line in lines[1:]:
    allf += [("b2", f) for f in line.split("|")]
json.dump({"groups": allf}, open("/tmp/lo-tools/lk-groups.json", "w"))
json.dump({"sheets": FIX, "formula_sheet": "Sheet1", "formulas": [f for _, f in allf]}, open("/tmp/lo-tools/lk.json", "w"))
print(len(allf))
