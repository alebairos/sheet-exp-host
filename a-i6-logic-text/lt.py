import json
FIX = {"Sheet1": {
  "A1": 1, "A2": 0, "A3": "abc", "A4": True, "A6": "  hello   world  ", "A7": {"error": "#N/A"},
  "A8": "3", "A9": 2.5, "A10": False, "A12": {"error": "#DIV/0!"}, "A13": 1234.5678, "A14": "Ünïcode straße", "A15": -3,
  "A16": "TRUE", "A17": 0.1,
}}
B1 = """=IF(A1,"y","n")|=IF(A2,"y","n")|=IF(A3,"y","n")|=IF(A5,"y","n")|=IF(A7,"y","n")|=IF(1>2,"y")|=IF(1<2,"y")|=IF(TRUE,,1)|=IF(FALSE,1)|=IF("TRUE",1,2)|=IF(A8,1,2)|=IF(A9,"y","n")|=IF(1,A5)|=IF(1,1/0,2)|=IF(0,1/0,2)|=IF(A4,"t","f")|=IF(A10,"t","f")|=IF(A16,1,2)|=IF(A12,1,2)|=IF(-1,"y","n")|=IF(1,A3)|=IF(0,1)|=IF(1,"")
=IFERROR(1/0,"e")|=IFERROR(A7,"na")|=IFERROR(1,"e")|=IFERROR(A3,"e")|=IFERROR(A5,"e")|=IFERROR(A12,0)|=IFERROR("a"+1,"v")|=IFERROR(A4,0)|=IFERROR(1/0,1/0)|=IFERROR(A7,A5)|=IFERROR(FOO(),"n")
=AND(1,1)|=AND(1,0)|=AND(A1:A2)|=AND(A3)|=AND(A4,A1)|=AND(A5)|=AND(TRUE,"x")|=AND(A7,1)|=AND(A1:A10)|=AND("TRUE")|=AND(2)|=AND(A1,A3)|=AND(A1:A4)|=AND(A16)|=AND(1/0,0)|=AND(A9,A15)
=OR(0,0)|=OR(0,1)|=OR(A2,A10)|=OR(A3)|=OR(A7,1)|=OR(A1:A3)|=OR(A5,A2)|=OR("FALSE",1)|=OR(A2:A3)|=OR(A12,1)
=NOT(1)|=NOT(0)|=NOT(A3)|=NOT(A5)|=NOT(A7)|=NOT("1")|=NOT(2.5)|=NOT(A4)|=NOT(A16)|=NOT("TRUE")|=NOT(A1:A2)
=ISBLANK(A5)|=ISBLANK(A3)|=ISBLANK("")|=ISBLANK(A2)|=ISBLANK(X99)|=ISBLANK(A7)|=ISBLANK(A5+0)|=ISBLANK(IF(1,A5))
=ISNUMBER(A1)|=ISNUMBER(A8)|=ISNUMBER(A4)|=ISNUMBER("3")|=ISNUMBER(A5)|=ISNUMBER(A7)|=ISNUMBER(1/0)|=ISNUMBER(TRUE)|=ISNUMBER(A9)|=ISNUMBER(A8*1)
=ISTEXT(A3)|=ISTEXT(A8)|=ISTEXT(A1)|=ISTEXT(A5)|=ISTEXT(A7)|=ISTEXT("x")|=ISTEXT(A4)|=ISTEXT(A16)|=ISTEXT(1)|=ISTEXT("")
=ISERROR(A7)|=ISERROR(A12)|=ISERROR(1/0)|=ISERROR(A3)|=ISERROR(A5)|=ISERROR("#N/A")|=ISERROR(FOO())|=ISERROR(A3+1)|=ISERROR(Nope!A1)
=IF(ISBLANK(A5),"empty",A5)|=IF(AND(A1>0,A9>2),"both","no")|=IFERROR(IF(A2,1,1/0),"caught")|=IF(OR(ISTEXT(A1),ISNUMBER(A1)),"ok","no")|=NOT(ISERROR(A1))"""
B2 = """=CONCATENATE("a","b")|=CONCATENATE(A1,A3)|=CONCATENATE(A4,"x")|=CONCATENATE(A9,"-",A13)|=CONCATENATE(A5,"x")|=CONCATENATE(A7,"x")|=CONCATENATE(1/3)|=CONCATENATE(TRUE())|=CONCATENATE("x",1/0)|=CONCATENATE(A15,A10)|=CONCATENATE(0.1+0.2)|=CONCATENATE(-0.5)|=CONCATENATE(123456789012)|=CONCATENATE(A17*3)|=CONCATENATE("a",,"b")
=LEFT("hello",2)|=LEFT("hello")|=LEFT("hello",0)|=LEFT("hello",10)|=LEFT("hello",-1)|=LEFT(A13,4)|=LEFT(A4,2)|=LEFT(A5,2)|=LEFT(A7,1)|=LEFT("abc",1.9)|=LEFT(12345,2)|=LEFT(A14,3)|=LEFT("abc",A3)|=LEFT("abc","2")|=LEFT("x",1/0)
=RIGHT("hello",3)|=RIGHT("hello")|=RIGHT("hello",10)|=RIGHT(A9,2)|=RIGHT("x",-1)|=RIGHT(A15,1)|=RIGHT(A10,2)|=RIGHT("hello",0)|=RIGHT(A14,4)
=MID("hello",2,3)|=MID("hello",0,2)|=MID("hello",5,10)|=MID("hello",6,1)|=MID("hello",2,0)|=MID("hello",1,-1)|=MID(A13,3,4)|=MID("hello",1.5,2.9)|=MID(A7,1,1)|=MID("hello",2)|=MID(A14,2,5)|=MID(TRUE,1,1)|=MID("hello",10,1)
=LEN("hello")|=LEN("")|=LEN(A5)|=LEN(A1)|=LEN(A9)|=LEN(A6)|=LEN(A14)|=LEN(A7)|=LEN(1/3)|=LEN(A4)|=LEN(0.1+0.2)|=LEN(A13)|=LEN(-1)|=LEN(A16)
=UPPER("abc")|=UPPER(A14)|=UPPER(A1)|=UPPER(A4)|=UPPER(A5)|=UPPER(A7)|=UPPER("MiXeD 1")|=LOWER("ABC Déf")|=LOWER(A5)|=LOWER(A7)|=LOWER(A10)|=LOWER(A14)|=LOWER(2.50)
=TRIM(A6)|=TRIM("  a  ")|=TRIM(A1)|=TRIM(A5)|=TRIM("a  b   c")|=TRIM(A7)|=TRIM(A4)|=TRIM("   ")|=TRIM(A9)
=LEN(TRIM(A6))|=UPPER(LEFT(A3,1))&MID(A3,2,10)|=CONCATENATE(LEFT(A14,2),RIGHT(A14,2))|=LEN(CONCATENATE(A1,A9))"""
allf = []
for g, txt in {"b1": B1, "b2": B2}.items():
    for line in txt.split("\n"):
        allf += [(g, f) for f in line.split("|")]
json.dump({"groups": allf}, open("/tmp/lo-tools/lt-groups.json", "w"))
json.dump({"sheets": FIX, "formula_sheet": "Sheet1", "formulas": [f for _, f in allf]}, open("/tmp/lo-tools/lt.json", "w"))
print(len(allf))
