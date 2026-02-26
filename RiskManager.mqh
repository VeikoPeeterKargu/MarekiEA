//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh  |
//|                         MarekiEA - Riskijuhtimise moodul         |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "MarekiEA"
#property link      ""
#property version   "1.00"

#ifndef RISKMANAGER_MQH
#define RISKMANAGER_MQH

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| Riskijuhtimise klass                                              |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   string            m_symbol;             // Kauplemissümbol
   double            m_riskPercent;         // Risk % kontost
   double            m_fixedLot;           // Fikseeritud lot-suurus
   ENUM_LOT_MODE     m_lotMode;           // Lot-suuruse arvutamise meetod
   int               m_stopLossPoints;     // Stop Loss punktides
   int               m_takeProfitPoints;   // Take Profit punktides
   double            m_maxDrawdownPercent; // Max lubatud drawdown %
   double            m_startBalance;       // Algne konto saldo
   ENUM_EA_STATE     m_state;             // EA olek
   
public:
                     CRiskManager();
                    ~CRiskManager();
   
   //--- Initsialiseerimine
   bool              Init(string symbol,
                          double riskPct, double fixedLot,
                          int slPoints, int tpPoints,
                          double maxDrawdownPct);
   
   //--- Lot-suuruse arvutamine
   double            CalculateLotSize(double entryPrice, double slPrice);
   double            CalculateLotSizeByPoints(int slPoints);
   
   //--- SL/TP arvutamine
   double            GetStopLoss(ENUM_SIGNAL signal, double entryPrice);
   double            GetTakeProfit(ENUM_SIGNAL signal, double entryPrice);
   
   //--- Drawdown kontroll
   bool              CheckDrawdown();
   double            GetCurrentDrawdown();
   
   //--- Oleku kontroll
   ENUM_EA_STATE     GetState() const { return m_state; }
   void              ResetState()     { m_state = EA_STATE_ACTIVE; m_startBalance = AccountInfoDouble(ACCOUNT_BALANCE); }
   
   //--- Getterid
   int               GetSLPoints()  const { return m_stopLossPoints; }
   int               GetTPPoints()  const { return m_takeProfitPoints; }
   
private:
   //--- Abifunktsioonid
   double            NormalizeLot(double lot);
   double            GetMinLot();
   double            GetMaxLot();
   double            GetLotStep();
};

//+------------------------------------------------------------------+
//| Konstruktor                                                       |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
   m_riskPercent         = 1.0;
   m_fixedLot            = 0.01;
   m_lotMode             = LOT_MODE_RISK;
   m_stopLossPoints      = 500;
   m_takeProfitPoints    = 1000;
   m_maxDrawdownPercent  = 10.0;
   m_startBalance        = 0;
   m_state               = EA_STATE_ACTIVE;
}

//+------------------------------------------------------------------+
//| Destruktor                                                        |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager() {}

//+------------------------------------------------------------------+
//| Initsialiseerimine                                                |
//+------------------------------------------------------------------+
bool CRiskManager::Init(string symbol,
                        double riskPct, double fixedLot,
                        int slPoints, int tpPoints,
                        double maxDrawdownPct)
{
   m_symbol              = symbol;
   m_riskPercent         = riskPct;
   m_fixedLot            = fixedLot;
   m_stopLossPoints      = slPoints;
   m_takeProfitPoints    = tpPoints;
   m_maxDrawdownPercent  = maxDrawdownPct;
   m_startBalance        = AccountInfoDouble(ACCOUNT_BALANCE);
   m_state               = EA_STATE_ACTIVE;
   
   //--- Määra lot-meetod
   if(fixedLot > 0)
      m_lotMode = LOT_MODE_FIXED;
   else
      m_lotMode = LOT_MODE_RISK;
   
   PrintFormat("[RiskManager] Initsialiseerimine: Meetod=%s | Risk=%.1f%% | SL=%d pts | TP=%d pts | MaxDD=%.1f%%",
               (m_lotMode == LOT_MODE_FIXED) ? "Fikseeritud" : "Risk %",
               m_riskPercent, m_stopLossPoints, m_takeProfitPoints, m_maxDrawdownPercent);
   
   return true;
}

//+------------------------------------------------------------------+
//| Arvutab lot-suuruse vastavalt SL hinnale                          |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double entryPrice, double slPrice)
{
   //--- Kui fikseeritud lot-meetod
   if(m_lotMode == LOT_MODE_FIXED)
      return NormalizeLot(m_fixedLot);
   
   //--- Risk-põhine arvutamine
   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney  = balance * m_riskPercent / 100.0;
   
   double slDistance  = MathAbs(entryPrice - slPrice);
   if(slDistance <= 0)
   {
      Print("[RiskManager] HOIATUS: SL kaugus on 0, kasutan min loti.");
      return GetMinLot();
   }
   
   double tickValue  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize   = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   
   if(tickValue <= 0 || tickSize <= 0)
   {
      Print("[RiskManager] HOIATUS: Tick väärtus/suurus on 0, kasutan min loti.");
      return GetMinLot();
   }
   
   double lot = riskMoney / (slDistance / tickSize * tickValue);
   lot = NormalizeLot(lot);
   
   PrintFormat("[RiskManager] Lot arvutus: Saldo=%.2f | Risk=%.2f | SL kaugus=%.5f | Lot=%.2f",
               balance, riskMoney, slDistance, lot);
   
   return lot;
}

//+------------------------------------------------------------------+
//| Arvutab lot-suuruse vastavalt SL punktidele                       |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSizeByPoints(int slPoints)
{
   //--- Kui fikseeritud lot-meetod
   if(m_lotMode == LOT_MODE_FIXED)
      return NormalizeLot(m_fixedLot);
   
   double balance    = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney  = balance * m_riskPercent / 100.0;
   
   double tickValue  = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
   double point      = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   
   if(tickValue <= 0 || point <= 0 || slPoints <= 0)
   {
      Print("[RiskManager] HOIATUS: Vigased parameetrid, kasutan min loti.");
      return GetMinLot();
   }
   
   double slValue    = slPoints * tickValue * point / SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   double lot        = riskMoney / slValue;
   
   return NormalizeLot(lot);
}

//+------------------------------------------------------------------+
//| Arvutab Stop Loss hinna                                           |
//+------------------------------------------------------------------+
double CRiskManager::GetStopLoss(ENUM_SIGNAL signal, double entryPrice)
{
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   
   double sl = 0;
   if(signal == SIGNAL_BUY)
      sl = entryPrice - m_stopLossPoints * point;
   else if(signal == SIGNAL_SELL)
      sl = entryPrice + m_stopLossPoints * point;
   
   return NormalizeDouble(sl, digits);
}

//+------------------------------------------------------------------+
//| Arvutab Take Profit hinna                                         |
//+------------------------------------------------------------------+
double CRiskManager::GetTakeProfit(ENUM_SIGNAL signal, double entryPrice)
{
   double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   int    digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   
   double tp = 0;
   if(signal == SIGNAL_BUY)
      tp = entryPrice + m_takeProfitPoints * point;
   else if(signal == SIGNAL_SELL)
      tp = entryPrice - m_takeProfitPoints * point;
   
   return NormalizeDouble(tp, digits);
}

//+------------------------------------------------------------------+
//| Kontrollib, kas drawdown on lubatud piirides                      |
//+------------------------------------------------------------------+
bool CRiskManager::CheckDrawdown()
{
   double dd = GetCurrentDrawdown();
   
   if(dd >= m_maxDrawdownPercent)
   {
      if(m_state != EA_STATE_PAUSED)
      {
         m_state = EA_STATE_PAUSED;
         PrintFormat("[RiskManager] !!! KAUPLEMINE PEATATUD! Drawdown %.1f%% ületas max piiri %.1f%%",
                     dd, m_maxDrawdownPercent);
      }
      return false; // Kauplemine ei ole lubatud
   }
   
   return true; // Kauplemine on lubatud
}

//+------------------------------------------------------------------+
//| Arvutab praeguse drawdown'i protsentides                          |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdown()
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if(balance <= 0)
      return 0;
   
   // Drawdown = (Saldo - Equity) / Saldo * 100
   // Kui equity > saldo, siis drawdown on 0
   double dd = (balance - equity) / balance * 100.0;
   return MathMax(dd, 0);
}

//+------------------------------------------------------------------+
//| Normaliseerib lot-suuruse vastavalt sümboli nõuetele              |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeLot(double lot)
{
   double minLot  = GetMinLot();
   double maxLot  = GetMaxLot();
   double step    = GetLotStep();
   
   //--- Ümarda lot-sammu järgi
   lot = MathFloor(lot / step) * step;
   
   //--- Piira min/max vahele
   lot = MathMax(lot, minLot);
   lot = MathMin(lot, maxLot);
   
   //--- Ümarda 2 kohani
   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Min/Max lot ja sammu getterid                                     |
//+------------------------------------------------------------------+
double CRiskManager::GetMinLot()  { return SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN); }
double CRiskManager::GetMaxLot()  { return SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX); }
double CRiskManager::GetLotStep() { return SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP); }

#endif // RISKMANAGER_MQH
//+------------------------------------------------------------------+
