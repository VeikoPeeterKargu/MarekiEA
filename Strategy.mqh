//+------------------------------------------------------------------+
//|                                                    Strategy.mqh  |
//|                         MarekiEA - Strateegia moodul             |
//|                  MA Crossover + RSI filter strateegia             |
//+------------------------------------------------------------------+
#property copyright "MarekiEA"
#property link      ""
#property version   "1.00"

#ifndef STRATEGY_MQH
#define STRATEGY_MQH

#include "Defines.mqh"

//+------------------------------------------------------------------+
//| Strateegia klass                                                  |
//+------------------------------------------------------------------+
class CStrategy
{
private:
   //--- Indikaatorite handle'id
   int               m_handleFastMA;     // Kiire MA handle
   int               m_handleSlowMA;     // Aeglane MA handle
   int               m_handleRSI;        // RSI handle
   
   //--- Parameetrid
   int               m_fastMAPeriod;     // Kiire MA periood
   int               m_slowMAPeriod;     // Aeglane MA periood
   ENUM_MA_METHOD    m_maMethod;         // MA meetod
   int               m_rsiPeriod;        // RSI periood
   double            m_rsiOverbought;    // RSI üleostetud tase
   double            m_rsiOversold;      // RSI ülemüüdud tase
   ENUM_TIMEFRAMES   m_timeframe;        // Ajakava
   string            m_symbol;           // Sümbol
   
   //--- Indikaatorite väärtused
   double            m_fastMA[3];        // Kiire MA väärtused (0=praegune, 1=eelmine, 2=kaks tagasi)
   double            m_slowMA[3];        // Aeglane MA väärtused
   double            m_rsi[2];           // RSI väärtused
   
   //--- Viimane signaal
   ENUM_SIGNAL       m_lastSignal;       // Viimane genereeritud signaal
   
public:
                     CStrategy();
                    ~CStrategy();
   
   //--- Initsialiseerimine ja deinitsialiseerimine
   bool              Init(string symbol, ENUM_TIMEFRAMES tf,
                          int fastMA, int slowMA, ENUM_MA_METHOD method,
                          int rsiPeriod, double rsiOB, double rsiOS);
   void              Deinit();
   
   //--- Signaalide genereerimine
   ENUM_SIGNAL       CheckSignal();
   ENUM_SIGNAL       GetLastSignal()    const { return m_lastSignal; }
   
   //--- Indikaatorite väärtuste getterid
   double            GetFastMA(int idx) const { return (idx >= 0 && idx < 3) ? m_fastMA[idx] : 0; }
   double            GetSlowMA(int idx) const { return (idx >= 0 && idx < 3) ? m_slowMA[idx] : 0; }
   double            GetRSI(int idx)    const { return (idx >= 0 && idx < 2) ? m_rsi[idx] : 0; }
   
private:
   //--- Abifunktsioonid
   bool              UpdateIndicators();
   bool              IsBuyCrossover();
   bool              IsSellCrossover();
};

//+------------------------------------------------------------------+
//| Konstruktor                                                       |
//+------------------------------------------------------------------+
CStrategy::CStrategy()
{
   m_handleFastMA = INVALID_HANDLE;
   m_handleSlowMA = INVALID_HANDLE;
   m_handleRSI    = INVALID_HANDLE;
   m_lastSignal   = SIGNAL_NONE;
   
   ArraySetAsSeries(m_fastMA, true);
   ArraySetAsSeries(m_slowMA, true);
   ArraySetAsSeries(m_rsi, true);
}

//+------------------------------------------------------------------+
//| Destruktor                                                        |
//+------------------------------------------------------------------+
CStrategy::~CStrategy()
{
   Deinit();
}

//+------------------------------------------------------------------+
//| Initsialiseerimine – loob indikaatorite handle'id                 |
//+------------------------------------------------------------------+
bool CStrategy::Init(string symbol, ENUM_TIMEFRAMES tf,
                     int fastMA, int slowMA, ENUM_MA_METHOD method,
                     int rsiPeriod, double rsiOB, double rsiOS)
{
   m_symbol        = symbol;
   m_timeframe     = tf;
   m_fastMAPeriod  = fastMA;
   m_slowMAPeriod  = slowMA;
   m_maMethod      = method;
   m_rsiPeriod     = rsiPeriod;
   m_rsiOverbought = rsiOB;
   m_rsiOversold   = rsiOS;
   
   //--- Kiire MA loomine
   m_handleFastMA = iMA(m_symbol, m_timeframe, m_fastMAPeriod, 0, m_maMethod, PRICE_CLOSE);
   if(m_handleFastMA == INVALID_HANDLE)
   {
      PrintFormat("[Strategy] VIGA: Kiire MA (periood %d) loomine ebaõnnestus! Kood: %d",
                  m_fastMAPeriod, GetLastError());
      return false;
   }
   
   //--- Aeglane MA loomine
   m_handleSlowMA = iMA(m_symbol, m_timeframe, m_slowMAPeriod, 0, m_maMethod, PRICE_CLOSE);
   if(m_handleSlowMA == INVALID_HANDLE)
   {
      PrintFormat("[Strategy] VIGA: Aeglane MA (periood %d) loomine ebaõnnestus! Kood: %d",
                  m_slowMAPeriod, GetLastError());
      return false;
   }
   
   //--- RSI loomine
   m_handleRSI = iRSI(m_symbol, m_timeframe, m_rsiPeriod, PRICE_CLOSE);
   if(m_handleRSI == INVALID_HANDLE)
   {
      PrintFormat("[Strategy] VIGA: RSI (periood %d) loomine ebaõnnestus! Kood: %d",
                  m_rsiPeriod, GetLastError());
      return false;
   }
   
   PrintFormat("[Strategy] Initsialiseerimine õnnestus: Fast MA(%d) + Slow MA(%d) + RSI(%d) | TF: %s",
               m_fastMAPeriod, m_slowMAPeriod, m_rsiPeriod, EnumToString(m_timeframe));
   return true;
}

//+------------------------------------------------------------------+
//| Deinitsialiseerimine – vabastab handle'id                         |
//+------------------------------------------------------------------+
void CStrategy::Deinit()
{
   if(m_handleFastMA != INVALID_HANDLE) { IndicatorRelease(m_handleFastMA); m_handleFastMA = INVALID_HANDLE; }
   if(m_handleSlowMA != INVALID_HANDLE) { IndicatorRelease(m_handleSlowMA); m_handleSlowMA = INVALID_HANDLE; }
   if(m_handleRSI    != INVALID_HANDLE) { IndicatorRelease(m_handleRSI);    m_handleRSI    = INVALID_HANDLE; }
   
   Print("[Strategy] Deinitsialiseerimine lõpetatud.");
}

//+------------------------------------------------------------------+
//| Uuendab indikaatorite väärtusi                                    |
//+------------------------------------------------------------------+
bool CStrategy::UpdateIndicators()
{
   //--- Kopeeri kiire MA väärtused (3 küünalt: praegune, eelmine, kaks tagasi)
   if(CopyBuffer(m_handleFastMA, 0, 0, 3, m_fastMA) != 3)
   {
      Print("[Strategy] HOIATUS: Kiire MA andmete kopeerimine ebaõnnestus.");
      return false;
   }
   
   //--- Kopeeri aeglane MA väärtused
   if(CopyBuffer(m_handleSlowMA, 0, 0, 3, m_slowMA) != 3)
   {
      Print("[Strategy] HOIATUS: Aeglase MA andmete kopeerimine ebaõnnestus.");
      return false;
   }
   
   //--- Kopeeri RSI väärtused (2 küünalt)
   if(CopyBuffer(m_handleRSI, 0, 0, 2, m_rsi) != 2)
   {
      Print("[Strategy] HOIATUS: RSI andmete kopeerimine ebaõnnestus.");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Kontrollib, kas toimus ostu-ristumine (bullish crossover)         |
//| Kiire MA ristub aeglase MA kohale                                 |
//+------------------------------------------------------------------+
bool CStrategy::IsBuyCrossover()
{
   // Eelmisel küünlal: kiire MA oli aeglasest allpool (või võrdne)
   // Praegusel küünlal: kiire MA on aeglasest ülalpool
   return (m_fastMA[2] <= m_slowMA[2] && m_fastMA[1] > m_slowMA[1]);
}

//+------------------------------------------------------------------+
//| Kontrollib, kas toimus müügi-ristumine (bearish crossover)        |
//| Kiire MA ristub aeglase MA alla                                   |
//+------------------------------------------------------------------+
bool CStrategy::IsSellCrossover()
{
   // Eelmisel küünlal: kiire MA oli aeglasest ülalpool (või võrdne)
   // Praegusel küünlal: kiire MA on aeglasest allpool
   return (m_fastMA[2] >= m_slowMA[2] && m_fastMA[1] < m_slowMA[1]);
}

//+------------------------------------------------------------------+
//| Peamine signaalide kontrollimine                                  |
//| Tagastab: SIGNAL_BUY, SIGNAL_SELL või SIGNAL_NONE                |
//+------------------------------------------------------------------+
ENUM_SIGNAL CStrategy::CheckSignal()
{
   m_lastSignal = SIGNAL_NONE;
   
   //--- Uuenda indikaatorid
   if(!UpdateIndicators())
      return SIGNAL_NONE;
   
   //--- Kontrolli ostu-ristumist + RSI filter
   if(IsBuyCrossover())
   {
      // RSI peab olema alla üleostetud taseme (turg ei tohi olla üleostetud)
      if(m_rsi[1] < m_rsiOverbought)
      {
         m_lastSignal = SIGNAL_BUY;
         PrintFormat("[Strategy] >>> OST signaal! Fast MA(%.5f) ristus üle Slow MA(%.5f) | RSI: %.1f",
                     m_fastMA[1], m_slowMA[1], m_rsi[1]);
      }
      else
      {
         PrintFormat("[Strategy] Ostu-ristumine tuvastatud, aga RSI(%.1f) >= %.1f – signaal filtreeritud välja.",
                     m_rsi[1], m_rsiOverbought);
      }
   }
   //--- Kontrolli müügi-ristumist + RSI filter
   else if(IsSellCrossover())
   {
      // RSI peab olema üle ülemüüdud taseme (turg ei tohi olla ülemüüdud)
      if(m_rsi[1] > m_rsiOversold)
      {
         m_lastSignal = SIGNAL_SELL;
         PrintFormat("[Strategy] >>> MÜÜK signaal! Fast MA(%.5f) ristus alla Slow MA(%.5f) | RSI: %.1f",
                     m_fastMA[1], m_slowMA[1], m_rsi[1]);
      }
      else
      {
         PrintFormat("[Strategy] Müügi-ristumine tuvastatud, aga RSI(%.1f) <= %.1f – signaal filtreeritud välja.",
                     m_rsi[1], m_rsiOversold);
      }
   }
   
   return m_lastSignal;
}

#endif // STRATEGY_MQH
//+------------------------------------------------------------------+
