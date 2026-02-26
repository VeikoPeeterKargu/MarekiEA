//+------------------------------------------------------------------+
//|                                                     Defines.mqh  |
//|                         MarekiEA - Ühised definitsioonid          |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "MarekiEA"
#property link      ""
#property version   "1.00"

#ifndef DEFINES_MQH
#define DEFINES_MQH

//--- Signaalide tüübid
enum ENUM_SIGNAL
{
   SIGNAL_NONE = 0,    // Signaal puudub
   SIGNAL_BUY  = 1,    // Ostu signaal
   SIGNAL_SELL = -1    // Müügi signaal
};

//--- EA olekud
enum ENUM_EA_STATE
{
   EA_STATE_ACTIVE   = 0,   // Aktiivne – kaupleb
   EA_STATE_PAUSED   = 1,   // Peatatud – max drawdown saavutatud
   EA_STATE_ERROR    = 2    // Viga – ei saa kauplemist jätkata
};

//--- Lot-suuruse meetodid
enum ENUM_LOT_MODE
{
   LOT_MODE_FIXED    = 0,   // Fikseeritud lot
   LOT_MODE_RISK     = 1    // Risk % kontost
};

//--- Värvid info paneelile
#define CLR_PANEL_BG       C'30,30,40'       // Paneeli taust
#define CLR_PANEL_BORDER   C'60,60,80'       // Paneeli ääris
#define CLR_TEXT_HEADER    clrGold            // Päise tekst
#define CLR_TEXT_NORMAL    clrWhiteSmoke      // Tavaline tekst
#define CLR_TEXT_PROFIT    clrLime            // Kasumi tekst
#define CLR_TEXT_LOSS      clrTomato          // Kahjumi tekst
#define CLR_SIGNAL_BUY     clrDodgerBlue     // Ostu signaali värv
#define CLR_SIGNAL_SELL    clrOrangeRed      // Müügi signaali värv
#define CLR_SIGNAL_NONE    clrGray           // Signaali puudumine

//--- Paneeli mõõtmed
#define PANEL_X            10     // Paneeli X positsioon
#define PANEL_Y            30     // Paneeli Y positsioon
#define PANEL_WIDTH        280    // Paneeli laius
#define PANEL_ROW_HEIGHT   20     // Rea kõrgus
#define PANEL_FONT_SIZE    9      // Fondi suurus
#define PANEL_FONT_NAME    "Consolas"  // Fondi nimi

//--- Üldised konstandid
#define EA_PREFIX          "MarekiEA_"   // EA objektide prefiks
#define MAX_SLIPPAGE       10            // Max libisemine punktides
#define MAX_RETRY          3             // Max korduskatsete arv

#endif // DEFINES_MQH
//+------------------------------------------------------------------+
