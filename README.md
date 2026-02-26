# MarekiEA - Kauplemisrobot MetaTrader 5 jaoks

**MarekiEA** on modulaarne MQL5 Expert Advisor, mis kaupleb MetaTrader 5 platvormil MA Crossover + RSI filter strateegia järgi.

## Omadused

- 📊 **MA Crossover + RSI strateegia** – kohandatavad perioodid ja tasemed
- 🛡️ **Riskijuhtimine** – risk % kontost, SL/TP, max drawdown kaitse
- 📈 **Trailing Stop** – dünaamiline kasumi kaitsmine
- 📋 **Info paneel** – reaalajas info graafikul
- 🖥️ **Web Dashboard** – strateegia seadistamine ja jälgimine brauseris
- 📤 **MQL5 eksport** – dashboardist seadete eksportimine

## Failide struktuur

| Fail | Kirjeldus |
|------|-----------|
| `MarekiEA.mq5` | Peamine Expert Advisor |
| `Strategy.mqh` | Strateegia signaalid |
| `RiskManager.mqh` | Riskijuhtimine |
| `TradeManager.mqh` | Orderite haldus |
| `InfoPanel.mqh` | Visuaalne info paneel |
| `Defines.mqh` | Konstandid ja enumid |
| `dashboard.html` | Strateegia dashboard (brauser) |

## Paigaldamine

1. Kopeeri `.mq5` ja `.mqh` failid → `MT5 Data Folder/MQL5/Experts/MarekiEA/`
2. Ava `MarekiEA.mq5` MetaEditoris
3. Kompileeri (F7)
4. Lisa EA graafikule ja alusta kauplemist

## Dashboard

Ava `dashboard.html` brauseris strateegia seadistamiseks ja jälgimiseks.

## Litsents

MIT License
