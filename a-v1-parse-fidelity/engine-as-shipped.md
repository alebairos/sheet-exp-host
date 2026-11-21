Landed exp-a main aa2fd48, ./engine as shipped. Data: Sheet1 A1=1 A2=2; 'My Sheet' A1=5 A2=6; S2 A1=3 A2=4. Each formula alone in Sheet1!C1.

| formula | ./engine gives |
| --- | --- |
| `= SUM( A1 : A2 )` | `3` |
| `=SUM( 'My Sheet'!A1 : A2 )` | `11` |
| `=SUM(S2!A1:S2!A2)` | `7` |
| `=SUM(1,2` | `3` |
| `=(1+2` | `3` |
| `=(1+` | `{"error": "Err:511"}` |
| `=1+` | `{"error": "Err:520"}` |
| `=1+*2` | `{"error": "Err:510"}` |
| `=1 2` | `{"error": "Err:509"}` |
| `=1+2)` | `{"error": "Err:508"}` |
| `=1E400` | `{"error": "Err:502"}` |
| `=MAX()` | `{"error": "Err:511"}` |
| `=SUM()` | `0` |
| `=ROUND()` | `{"error": "Err:511"}` |
| `=MEDIAN()` | `{"error": "Err:511"}` |
| `=SUM(A1:+` | `{"error": "Err:520"}` |
