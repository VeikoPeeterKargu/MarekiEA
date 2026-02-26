# MarekiEA – Antigravity juhend

## Kiire alustamine

### 1. Paki lahti

Paki `MarekiEA.zip` oma Antigravity kausta, nt:

```
~/Documents/Antigravity/MarekiEA/
```

### 2. Ava Antigravitys

Ava Antigravity ja lisa see kaust workspace'ina (File → Open Folder).

### 3. Käivita Dashboard

Terminalis projekti kaustas:

```bash
python3 -m http.server 8765
```

Ava brauseris: **<http://localhost:8765/dashboard.html>**

Sisselogimine:

- **Kasutaja:** `marek` | **Parool:** `Marek123`
- **Kasutaja:** `peeter` | **Parool:** `Peeter123`

### 4. MQL5 failide paigaldamine (MetaTrader 5)

1. Kopeeri `.mq5` ja `.mqh` failid → `MT5 Data Folder/MQL5/Experts/MarekiEA/`
2. Ava MetaEditor → `MarekiEA.mq5` → Kompileeri (F7)
3. Lisa EA graafikule

---

## Failide struktuur

| Fail | Mis see teeb |
|------|-------------|
| `MarekiEA.mq5` | Peamine kauplemisrobot |
| `Strategy.mqh` | MA Crossover + RSI strateegia |
| `RiskManager.mqh` | Riskijuhtimine (lot, SL/TP, drawdown) |
| `TradeManager.mqh` | Tehingute haldus + trailing stop |
| `InfoPanel.mqh` | Info paneel MT5 graafikul |
| `Defines.mqh` | Konstandid ja seaded |
| `dashboard.html` | Veebi dashboard (brauser) |

## Arendamine Antigravitys

### Strateegia muutmine

Redigeeri `Strategy.mqh` – seal on signaalide loogika.

### Dashboardi muutmine

Redigeeri `dashboard.html` – kõik on ühes failis (HTML + CSS + JS).

### Git

```bash
git add -A
git commit -m "Kirjeldus muudatustest"
git push origin main
```

GitHub repo: <https://github.com/VeikoPeeterKargu/MarekiEA>
