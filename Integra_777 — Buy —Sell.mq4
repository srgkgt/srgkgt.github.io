//+------------------------------------------------------------------+
//|                                             Integra_777-Buy-Sell |
//|                                                           Kogut  |
//|                                         https://grandcapital.ru/ |
//+------------------------------------------------------------------+

//INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA
/*
   Советник с динамическим лотом выставления колен сопровождения серии. Т.е. колени выставляются не ранее PipStep по сигналам индикаторов.  
   Лотность колен возрастает с увеличением пройденного расстояния от PipStep до сигнала индикаторов с целью максимально приблизить
   уровень ТП к текущей цене.
   Трал в валюте депозита сделан с целью приближения уровня динамического ТП серии с каждым коленом к текущей цене при больших объемах
   и максимальному извлечению прибыли в начале серии при еще малых объемах ордеров.
   Добавлено перекрытие ордеров.
   Добавлено раздельное закрытие первых ордеров.
   Добавлен промежуточный буфер прибыли.
   Добавлен ТП последних ордеров серии.
*/
#define       EXPERT_NAME       "Integra_777-Buy-Sell"
#property copyright             "Kogut"
#property link                  "https://grandcapital.ru/"
#property version   "1.00"
#property strict                                      // Моя почта srgkgt@gmail.com                                                     
                                                      // Kogut    WebMoney Z541915250642 или PAYEER P31929418
extern bool   SymbolControl     =          TRUE; 
extern string t0 =              "ТП в валюте депозита";
extern double DefaultProfit      =            1;      // Тейк профит в валюте депозита (гарантированная сумма профита)

extern string t1 =              "Установки расстояний";
extern bool   VirtualTral        =         TRUE;
extern int    Tral_Start         =            1;      // Расстояние начала трала от линии Profit в пунктах (классический ТП в пунктах)
extern int    Tral_Size          =            1;      // Величина трала после Tral_Start в пунктах
extern int    PipStep            =           10;      // Шаг открытия колен в пунктах
input  double LotExponent        =          1.0;      // Начальный коэффициент увеличения лота
extern int    TimeStep           =           10;

extern string t2 =              "Установки объемов и MМ";
extern int    Bonus              =            0;      // Средства, не учавствующие в торговле (в валюте депозита)
extern double Risk               =          0.0;      // Первая сделка размером в % от свободных средств, если Risk=0 то первая сделка открывается размером DefaultLot
extern double DefaultLot         =         0.01;      // Начальный лот, работает если Risk=0

extern int    LockPercent        =           40;      // Процент локового ордера от суммарного объема основной серии (пока только инфо)

extern string t3 =              "Переход на фикслот";
extern int    FixLotPercent      =           25;      // Процент просадки для автоперехода на фиксированный лот
extern bool   FixLot             =         TRUE;      // Если TRUE, то фиксированный лот, если FALSE - динамический

extern string t4 =              "Установки LastTP";
extern bool   UseAccBuffer       =        FALSE;      // True - включен накопительный буфер, FALSE - выключен
extern bool   UseTrailingStop    =        FALSE;      // True - включен тейкпрофит последнего ордера, FALSE - выключен
extern double TrailingStop       =            6;      // ТS последнего ордера
extern int    TrailingStep       =            3;      // TS шаг трала 
extern int    StartTS            =            2;      // № колена, с которого начинает работать LastTP(2...5)

extern string t5 =              "Установки перекрытия";
extern int    LeadingOrder       =           10;      // C какого колена работает перекрытие
extern int    ProfitPersent      =           10;      // Процент перекрытия(10...50)
extern int    SecondProfitPersent=           50;      // Процент перекрытия когда подключается предпоследний ордер

extern string t6 =              "Ограничения"  ;
extern int    MaxTrades          =           11;      // Максимальное количество одновременно открытых колен
extern double MaxLot             =            0;      // Ограничение на максимальный лот, если MaxLot=0, то макс возможный лот ДЦ
extern int    CurrencySL         =            0;      // Ограничение по просадке в валюте депозита. Если  CurrencySL=0, то отключено.

extern string t7 =              "Закрыть Всё"  ;
extern bool   Close_All          =        FALSE;      // При вкл - принудительно закрываются все позиции, новый цикл не начинается

extern string t8 =              "Разрешить торговлю";
extern bool   NewCycle_ON        =         TRUE;      // При запрете - цикл дорабатывается до конца, новый цикл не начинается

extern string t9 =              "Установки CCI";
extern bool   Vxod_Lock          =         TRUE;
extern bool   Sopr_Lock          =         TRUE;
extern bool   Vxod_CCI           =         TRUE;      // TRUE\FALSE - вход по CCI\ без индикатора
extern bool   Sopr_CCI           =         TRUE;      // TRUE\FALSE - сопровождение по CCI\ без индикатора
extern int    SignTF1            =            1;      // После какого колена берём сигнал по м1
extern int    SignTF5            =            0;      // После какого колена берём сигнал по м5
extern int    SignTF15           =            0;      // После какого колена берём сигнал по м15
extern int    SignTF30           =            0;      // После какого колена берём сигнал по м30
extern int    SignTFH1           =            0;      // После какого колена берём сигнал по H1
extern int    SignTFH4           =            0;      // После какого колена берём сигнал по H4
extern int    SignTFD1           =            0;      // После какого колена берём сигнал по D1
input  int    StartPipstep1     = 2;                  // Первый уровень после какого колена меняем пипстеп и лотэкспонент
input  double ExponPipstep1     = 1.6;                // Коэффициент увеличения шага открытия колен в пунктах
input  double LotExponent1      = 4.0;                // Коэффициент увеличения лота
input  int    StartPipstep2     = 3;                  // Второй уровень после какого колена меняем пипстеп и лотэкспонент                   
input  double ExponPipstep2     = 1.6;                // Коэффициент увеличения шага открытия колен в пунктах
input  double LotExponent2      = 0.5;                // Коэффициент увеличения лота
input  int    StartPipstep3     = 4;                  // Третий уровень после какого колена меняем пипстеп и лотэкспонент
input  double ExponPipstep3     = 1.6;                // Коэффициент увеличения шага открытия колен в пунктах
input  double LotExponent3      = 0.5;                // Коэффициент увеличения лота    
input  int    StartPipstep4     = 5;                  // Третий уровень после какого колена меняем пипстеп и лотэкспонент
input  double ExponPipstep4     = 1.6;                // Коэффициент увеличения шага открытия колен в пунктах
input  double LotExponent4      = 1.0;                // Коэффициент увеличения лота    
extern int    CCI_TimeFrame      =            0;      // ТФ      CCI  (0-текущий ТФ графика, 1=М1,2=М5,3=М15,4=М30,5=Н1,6=Н4,7=D1,8=W1,9=MN1)
extern int    Level              =          100;
extern int    Period_CCI         =           14;
extern int    CCI_PRICE_TYPE     =            0;      // 0 - PRICE_CLOSE    - цена закрытия 
                                                      // 1 - PRICE_OPEN     - цена открытия
                                                      // 2 - PRICE_HIGH     - макс.цена
                                                      // 3 - PRICE_LOW      - мин.цена
                                                      // 4 - PRICE_MEDIAN   - средняя цена,(high+low)/2
                                                      // 5 - PRICE_TYPICAL  - типичная цена,(high+low+close)/3
                                                      // 6 - PRICE_WEIGHTED - взвешенная цена закрытия,(high+low+close+close)/4
extern double TIME_SOUND         =           60;      //периодичность звуковых сигналов в сек .если = 0 то выкл
extern color  BarLabel_color     =LightSteelBlue;
extern color  CommentLabel_color =LightSteelBlue;
extern color  CL1                =          Lime;
extern color  CL2                =           Red;
extern color  CL3                =     PaleGreen;
extern color  CL4                =     LightPink;
extern int    Shift_UP_DN        =            30; 
                                                         
extern string t10 =             "Фильтры уровней по МА";
extern int    TipMAFilter        =            0;      // Тип фильтра. Если 0-Выкл, если 1-фильтр shvondera, если 2-фильтр Kordana
extern int    Period_МА          =          910;      // Период скользящей средней
extern int    Distance_МА        =           35;      // Если Тип1 - Дистанция в пунктах на сколько цена должна отойти от МА для открытия ордера. Работа в сторону МА.
                                                      // Если Тип2 - Уровень запрета открытия ордеров выше/ниже от скользящей средней в пунктах. Отсечка на краях диапазона.                                                      
extern string t11 =             "Фильтр времени";
extern bool   UseFilterTime      =        FALSE;      // Использовать запрет торговли в пятницу после и в понедельник до указанных времен
extern bool   UseFilterDate      =        FALSE;      // Использовать запрет торговли в конце и начале месяца
extern int    StartHourMonday    =            7;      // Время начала торговли в понедельник
extern int    EndHourFriday      =           19;      // Время конца  торговли в пятницу
extern int    StartMonth         =            1;      // Начать торги после N дней начала  месяца
extern int    EndMonth           =            1;      // Закончит торговлю за N дней до конца месяца включительно

extern string t12 =             "Изменение цвета и размера индикации";
extern color  ColorInd           =       Silver;      // Цвет основной индикации
extern color  ColorTP            =       Silver;      // Цвет линии Profit
extern color  ColTPTrail         =   DarkOrange;      // Цвет линии Profit после срабатывания трала
extern color  ColorZL            =  DeepSkyBlue;      // Цвет линии безубытка
extern int    xDist1             =          300;      // Расстояние по горизонтали блока трала и нехватки средств
extern int    xDist2             =            8;      // Расстояние по горизонтали блока суммарных профитов и объемов
extern int    FontSize           =            9;      // Размер шрифта индикации

extern string t13 =             "Дополнительные параметры";
extern bool   Info               =         TRUE;      // Вкл индикации, звукового сопровождения открытия колен и подробного протоколирования
extern bool   VisualMode         =         TRUE;      // Вкл режима ручного управления
extern int    MagicNumber        =            0;      // Уникальный номер советника (при MagicNumber=0 сов подхватывает ручные ордера)
extern string MagicNumList       =  "111 0 888";      // Список, через пробел, магиков которые советник будет считать своими (не более 10)
extern int    PauseTrade         =            6;      // Время ожидания между торговыми командами в сек 

//********************************************************************************************

#import "mt4gui2.dll"
 string guiVersion() ;
 string guiGetText(int,int) ; 
 bool guiIsClicked(int,int) ; 
 bool guiIsChecked(int,int) ; 
 int guiAdd(int,string,int,int,int,int,string) ; 
 int guiSetBgColor(int,int,int) ; 
 int guiSetTextColor(int,int,int) ; 
 int guiRemove(int,int) ; 
 int guiRemoveAll(int) ; 
 int guiSetText(int,int,string,int,string) ; 
 int guiSetChecked(int,int,bool) ; 
 int guiEnable(int,int,int) ; 
 int guiAddListItem(int,int,string) ; 
 int guiGetListSel(int,int) ; 
 int guiSetListSel(int,int,int) ; 
#import                        


//********************************************************************************************

//INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA 

   int      mper[10]={0,1,5,15,30,60,240,1440,10080,43200},magic[10],TicketB[],TicketS[];
   int      dig,Error,Lpos,Lpos1,Cpos,cmagic,totalord,totalbuy,totalsell,slip,totord,
            buybtn,sellbtn,closebtn,lottxt,lotbtnp,lotbtnm,closesellbtn,closebuybtn,hwnd,btn1,sum,FirstBuyTicket,FirstSellTicket;
   color    col,ZLcolor,TPcolor,ColProf,ColBuy,ColSell,ColBuf;
   double   TPPrice,ZeroLine,L1Cprofit,LCprofit,Cprofit,Lprofit,Lprofit1,CurrentDrawdown,CurrentUrov,Profit,SumProfit,SumLotBuy,SumLotSell,
            Lot,LotR,Sum_lot,Sumlot,minLot,maxLot,delta,delta2,TV,DrawDownRate,FreeMargin,Balance,Sredstva,One_Lot,Step,tp,CCI,LastSLBuy,
            ProfitBuy,ProfitSell,LastLotBuy,LastLotSell,LastPriceBuy,LastPriceSell,ProfitOverlap,FirstPriceBuy,FirstPriceSell,LastSLSell;
   string   comment,Symb,gvTimeStart,gvOrderSelect,Prof,Bezub,tip,txt,tral,Integra;
   datetime TimeStart,TimeL,StartKolenoB,StartKolenoS;
   bool     CloseTrigger,NoTrade,CloseAll,CloseFM,fixlot,InitFail,Global;  
   double   PipstepBuy0,PipstepBuy;
   double   PipstepSell0,PipstepSell;
   double   LotExponentBuy0,LotExponentBuy;
   double   LotExponentSell0,LotExponentSell; 
//=======================================================================

int z,r1,j,io,imi;
int SignCCI,MAS_signal,MAK_signal;
int SeTicket,ticketbuy, ticketsell ; 
int Err, SeErr,levels;
double newlot_1,div;
double spr, freez,stlev,slip_0,newlot, SummPrice, Abs, SummAbs; 
datetime time_coordinate;
string PSD="", PSH4="", PSH1="", PS30="", PS15="", PS5="",PS1="";   
color  PcolD,PcolH4,PcolH1,Pcol30,Pcol15,Pcol5,Pcol1;  
string SD="", SH4="", SH1="", S30="", S15="", S5="",S1="";   
color  colD,colH4,colH1,col30,col15,col5,col1; 
string TSD="", TSH4="", TSH1="", TS30="", TS15="", TS5="",TS1="";   
color  TcolD,TcolH4,TcolH1,Tcol30,Tcol15,Tcol5,Tcol1;  
//INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA  
 //=========================================================================================================================================//
// Qimer . Функция контроля наличия своего магика                                                                                          //
//=========================================================================================================================================//

bool MagicCheck(){
   for(int MagicCh =0; MagicCh<cmagic; MagicCh++){
      if (OrderMagicNumber()==magic[MagicCh]) return(true);
   }
return(false);
}  
//=========================================================================================================================================//
// Kordan . Функция получения информации по открытым ордерам                                                                               //
//=========================================================================================================================================// 

int CurrentCondition(){
//==========================================================  Сбор данных о торговле  ===============================================================
   totalbuy=0; totalsell=0 ;
   int n = OrdersTotal()   ;  
   ArrayResize(TicketB,n)  ;
   ArrayResize(TicketS,n)  ;
//--------------------------  Заполнение массивов тикетов  ------------------------------
   for ( r1=0;r1<n;r1++) {
      if(OrderSelect(r1,SELECT_BY_POS,MODE_TRADES)){
         if (OrderSymbol() == Symb && (OrderMagicNumber()==MagicNumber || MagicCheck())){
            switch(OrderType()){
               case OP_BUY  : TicketB[totalbuy] =OrderTicket(); totalbuy++ ;     break; 
               case OP_SELL : TicketS[totalsell]=OrderTicket(); totalsell++;     break; 
            }
         }
      }         
      else {Print("Сбой, при переборе ордеров, производится новый расчет");  return(0);}
   }

   
//-------------------------  Сортировка массивов тикетов  -------------------------------
   double pr1,pr2,pr3;
//--------------------------------- Для серии BUY ---------------------------------------
   for ( io=0;io<totalbuy-1;io++){
      bool select1=OrderSelect(TicketB[io],SELECT_BY_TICKET); pr1=OrderOpenPrice(); pr3=pr1; r1=io;
         for ( j=io+1;j<totalbuy;j++){
            bool select2=OrderSelect(TicketB[j],SELECT_BY_TICKET); pr2=OrderOpenPrice();
               if (pr2<pr3) {pr3=pr2;r1=j  ;}
         }
   if (r1!=io) {j=TicketB[io];TicketB[io]=TicketB[r1];TicketB[r1]=j;}
   }
//--------------------------------- Для серии SELL --------------------------------------
   for (io=0;io<totalsell-1;io++){
      bool select3=OrderSelect(TicketS[io],SELECT_BY_TICKET); pr1=OrderOpenPrice(); pr3=pr1; r1=io;
         for (j=io+1;j<totalsell;j++){
            bool select4=OrderSelect(TicketS[j],SELECT_BY_TICKET); pr2=OrderOpenPrice();
               if (pr2>pr3) {pr3=pr2;r1=j  ;}
         }
   if (r1!=io) {j=TicketS[io];TicketS[io]=TicketS[r1];TicketS[r1]=j;}
   }
//-----------------  Подсчет профита, объемов и т.д. открытых ордеров  ------------------
   ProfitBuy=0;ProfitSell=0;LastPriceBuy=0;LastLotBuy=0;LastPriceSell=0;LastLotSell=0;FirstPriceSell=0;FirstSellTicket=0;
   SumLotBuy=0;SumLotSell=0;Lprofit1=0;Lpos1=0;Lprofit=0;Lpos=0;Cprofit=0;Cpos=0;FirstPriceBuy=0;FirstBuyTicket=0;LastSLBuy=0;LastSLSell=0;
//--------------------------------- Для серии BUY ---------------------------------------   
   for (io=totalbuy-1;io>=0;io--){
      bool select5=OrderSelect(TicketB[io],SELECT_BY_TICKET)           ;
      SumLotBuy     += OrderLots()                       ;
      ProfitBuy     += OrderProfit()+OrderCommission()+OrderSwap();
      LastPriceBuy   = OrderOpenPrice()                  ; 
      LastLotBuy     = OrderLots()                       ;
      LastSLBuy      = OrderStopLoss()                   ;     
         if(io == totalbuy-1){
            FirstPriceBuy   = OrderOpenPrice()           ;
            FirstBuyTicket  = OrderTicket()              ;//Тикет первого ордера Buy
         }

         if (OrderProfit()>0 && OrderProfit()>Lprofit){
            Lprofit1= Lprofit                            ;
            Lpos1   = Lpos                               ; 
            Lprofit = OrderProfit()                      ; //макс значение
            Lpos    = OrderTicket()                      ;
         }         
         if (OrderProfit()<0 && OrderProfit()<Cprofit){
            Cprofit = OrderProfit()                      ; //мин  значение
            Cpos    = OrderTicket()                      ;
         } 
   }
//--------------------------------- Для серии SELL --------------------------------------      
   for (io=totalsell-1;io>=0;io--){
      bool select6=OrderSelect(TicketS[io],SELECT_BY_TICKET)           ;
      SumLotSell    += OrderLots()                       ;                                  
      ProfitSell    += OrderProfit()+OrderCommission()+OrderSwap();
      LastPriceSell  = OrderOpenPrice()                  ; 
      LastLotSell    = OrderLots()                       ; 
      LastSLSell     = OrderStopLoss()                   ;
         if(io == totalsell-1){
            FirstPriceSell   = OrderOpenPrice()          ;
            FirstSellTicket  = OrderTicket()             ;//Тикет первого ордера Sell
         }

         if (OrderProfit()>0 && OrderProfit()>Lprofit){
            Lprofit1= Lprofit                            ;
            Lpos1   = Lpos                               ; 
            Lprofit = OrderProfit()                      ; //макс значение
            Lpos    = OrderTicket()                      ;
         }       
         if (OrderProfit()<0 && OrderProfit()<Cprofit){
            Cprofit = OrderProfit()                      ; //мин  значение
            Cpos    = OrderTicket()                      ;
         }  
   }
       PipstepBuy0=PipStep;  
       PipstepSell0=PipStep;
       LotExponentBuy0=LotExponent;
       LotExponentSell0 =LotExponent;
        
       if(totalbuy==StartPipstep1&&StartPipstep1!=0){PipstepBuy0=PipStep*ExponPipstep1;LotExponentBuy0 =LotExponent1;}
       if(totalbuy==StartPipstep2&&StartPipstep2!=0){PipstepBuy0=PipStep*ExponPipstep2;LotExponentBuy0 =LotExponent2;}
       if(totalbuy==StartPipstep3&&StartPipstep3!=0){PipstepBuy0=PipStep*ExponPipstep3;LotExponentBuy0 =LotExponent3;}
       if(totalbuy>=StartPipstep4&&StartPipstep4!=0){PipstepBuy0=PipStep*ExponPipstep4;LotExponentBuy0 =LotExponent4;}
       if(totalsell==StartPipstep1&&StartPipstep1!=0){PipstepSell0=PipStep* ExponPipstep1;LotExponentSell0 =LotExponent1;}
       if(totalsell==StartPipstep2&&StartPipstep2!=0){PipstepSell0=PipStep* ExponPipstep2;LotExponentSell0 =LotExponent2;}
       if(totalsell==StartPipstep3&&StartPipstep3!=0){PipstepSell0=PipStep* ExponPipstep3;LotExponentSell0 =LotExponent3;}     
       if(totalsell>=StartPipstep4&&StartPipstep4!=0){PipstepSell0=PipStep* ExponPipstep4;LotExponentSell0 =LotExponent4;}
       PipstepBuy = PipstepBuy0;
       PipstepSell=PipstepSell0;
       LotExponentBuy=LotExponentBuy0;
       LotExponentSell=LotExponentSell0;
       
       int CCI_TimeFrame_ =CCI_TimeFrame;
       
       if(SignTF1 !=0&&(totalbuy>=SignTF1 ||totalsell>=SignTF1 ))    CCI_TimeFrame_ = 1;
       if(SignTF5 !=0&&(totalbuy>=SignTF5 ||totalsell>=SignTF5 ))    CCI_TimeFrame_ = 2;
       if(SignTF15!=0&&(totalbuy>=SignTF15||totalsell>=SignTF15))    CCI_TimeFrame_ = 3;
       if(SignTF30!=0&&(totalbuy>=SignTF30||totalsell>=SignTF30))    CCI_TimeFrame_ = 4;
       if(SignTFH1!=0&&(totalbuy>=SignTFH1||totalsell>=SignTFH1))    CCI_TimeFrame_ = 5;
       if(SignTFH4!=0&&(totalbuy>=SignTFH4||totalsell>=SignTFH4))    CCI_TimeFrame_ = 6;
       if(SignTFD1!=0&&(totalbuy>=SignTFD1||totalsell>=SignTFD1))    CCI_TimeFrame_ = 7;
       CCI_TimeFrame = CCI_TimeFrame_;
       
    totalord        = totalbuy   + totalsell;             
    SumProfit       = ProfitSell + ProfitBuy;
    CurrentDrawdown = NormalizeDouble(MathMax((AccountBalance()+AccountCredit()-AccountEquity())/(AccountBalance()+AccountCredit())*100,0),2);        
    Sum_lot         = NormalizeDouble(SumLotBuy-SumLotSell ,dig);  // Суммарный лот (плюс или минус)        
    Sumlot          = NormalizeDouble(MathAbs(Sum_lot     ),dig);  // Aбсолютное значение суммарного лота (значение по модулю, всегда плюс)
    if (Sumlot ==0) Sumlot = 0.00000001                         ;  // Защита от нулевого значения        
    if (AccountMargin()>0) CurrentUrov = NormalizeDouble(AccountEquity()/AccountMargin()*100,0);
    FreeMargin = NormalizeDouble(AccountFreeMargin()- Bonus, 2) ;
    Balance    = NormalizeDouble(AccountBalance   ()- Bonus, 2) ;
    Sredstva   = NormalizeDouble(AccountEquity    ()       , 2) ;
     return(1);         
} 
 //=========================================================================================================================================//
// super65 + Kordan . Накопительный буфер профита                                                                                          //
//=========================================================================================================================================//

int AccBuffer(){
   if (totalord==0) Global=true;
	if (Global){
		if (totalbuy!=0 && totalsell==0){ 
			bool select7=OrderSelect(TicketB[totalbuy -1],SELECT_BY_TICKET);
			TimeStart = OrderOpenTime();
		} else  
		if (totalsell!=0 && totalbuy==0){
			bool select8=OrderSelect(TicketS[totalsell-1],SELECT_BY_TICKET);
			TimeStart = OrderOpenTime();
		} else 
		if (totalbuy!=0 && totalsell!=0){
			bool select9=OrderSelect(TicketB[totalbuy -1],SELECT_BY_TICKET);
			TimeStart = OrderOpenTime();
			bool select10=OrderSelect(TicketS[totalsell-1],SELECT_BY_TICKET);
			if (TimeStart > OrderOpenTime()) TimeStart = OrderOpenTime(); 
		}else 
			TimeStart = TimeCurrent();
			TimeL     = GlobalVariableSet(gvTimeStart,TimeStart); 
			Global    = false;
	}         
int m = OrdersHistoryTotal();
ProfitOverlap = 0; 
	while(true){
		if (!OrderSelect(m-1,SELECT_BY_POS,MODE_HISTORY))      break;
		if (OrderOpenTime() < GlobalVariableGet(gvTimeStart)) break; 
			if (OrderSymbol()==Symb && (OrderMagicNumber()==MagicNumber || MagicCheck())){ 
				ProfitOverlap +=OrderProfit()+OrderSwap()+OrderCommission();
			}  
	m--;
	}
ProfitOverlap = NormalizeDouble(ProfitOverlap,2); 
return(0);
} 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {       //проверяем, существует ли глобальная переменная gvOrderSelect, в которую заносятся данные
  //о наличии ордеров в рынке на всех валютных парах. Если такой гл переменной нет, создаём её
  //и приравниваем к "0" 
   if (!IsTesting() && !IsOptimization() && SymbolControl){ 
      gvOrderSelect = "GV_"+"Magic_№ "+DoubleToString(MagicNumber,0);
      NoTrade = true;
     if(!GlobalVariableCheck(gvOrderSelect))        //проверяем, сущ. ли Гл переменная
     {
       if(GlobalVariableSet(gvOrderSelect, 0) == 0) //если нет, создаём, в случае неудачи создания вываливаемся
       {
        if (Info) Print("Ошибка инициализации. Невозможно создать глобальную переменную gvOrderSelect.");
        return(0);
       }
       else{
        if (Info)  Print("Успешная инициализация.Создана глобальная переменная gvOrderSelect.Советник начал работу");
       }
     } 
   }
   DeleteObject()                                      ;  // Сброс триггера и очистка экрана
   Symb   = Symbol()                                   ;
   if (iBars(Symb,mper[CCI_TimeFrame]  ) < Period_CCI) {Print("! Недостачно баров в истории для CCI !"             ); InitFail = True  ;}
   if (iBars(Symb,mper[CCI_TimeFrame+1]) < Period_CCI) {Print("! Недостачно баров в истории для свечного анализа !"); InitFail = True  ;}
   if (iBars(Symb,PERIOD_H1)             < Period_МА ) {Print("! Недостачно баров в истории для МА !"              ); InitFail = True  ;}
   if (!IsDllsAllowed()   || !IsLibrariesAllowed()   ) {Print("! Разрешите импорт DLL!Поставьте галочку !"         ); InitFail = True  ;}
   if (InitFail  ) {Print("! Ошибка иницилизации советника !" );    return(0);}
   if ((!IsVisualMode() || IsOptimization()) && IsTesting()) Info=false;
   if (IsTesting()) SymbolControl = false;
   TV      = MarketInfo(Symb,MODE_TICKVALUE          ) ;   
   minLot  = MarketInfo(Symb,MODE_MINLOT             ) ; 
   maxLot  = MarketInfo(Symb,MODE_MAXLOT             ) ;
   One_Lot = MarketInfo(Symb,MODE_MARGINREQUIRED     ) ;  // Размер свободных средств, необходимых для открытия 1 лота на покупку
      Step = MarketInfo(Symb,MODE_LOTSTEP            ) ;  // Шаг изменения размера лота
   if(Step >= 1) dig=0; 
   else if(Step >= 0.1) dig=1;  
   else if(Step >= 0.01) dig=2;

   Global = true;
   totord =0;
//********************************************************************************************* 


if (VisualMode){
   hwnd=WindowHandle(Symbol(),Period());
   guiRemoveAll(hwnd);
   lottxt      = guiAdd(hwnd,"text"  , 77,-39,70,20, DoubleToStr(Lot,2));
   buybtn      = guiAdd(hwnd,"button",149,-39,70,20,"BUY"              );
   sellbtn     = guiAdd(hwnd,"button",  5,-39,70,20,"SELL"             );
   closebtn    = guiAdd(hwnd,"button",221,-39,90,20,"Close ALL"        );
   closesellbtn= guiAdd(hwnd,"button",313,-39,90,20,"Close SELL"       );
   closebuybtn = guiAdd(hwnd,"button",405,-39,90,20,"Close BUY"        );
   guiSetBgColor(hwnd,closebtn,Gold);
   guiSetBgColor(hwnd,buybtn,Chartreuse);
   guiSetBgColor(hwnd,sellbtn,OrangeRed);
   guiSetBgColor(hwnd,closebuybtn,Chartreuse);
   guiSetBgColor(hwnd,closesellbtn,OrangeRed);
} 
   
//***************** Автоматический переход на пятизнак **************************************** 
   int _digits = (int) MarketInfo(Symb, MODE_DIGITS);
      if (_digits == 5 || _digits == 3){
         Tral_Start        *= 10;
         Tral_Size         *= 10;
         PipStep           *= 10;
         TrailingStop      *= 10;
         TrailingStep      *= 10;
         Distance_МА       *= 10;
      }
            
//***************  Защита от неправильного выставления параметров  ****************************

   if(CCI_TimeFrame< 2  || CCI_TimeFrame>4) CCI_TimeFrame = 0;
   if(DefaultProfit<=0  )  DefaultProfit = 0.01  ;
   if(LockPercent  <=0  )  LockPercent=1         ;
   if(DefaultLot   <=0  )  DefaultLot=1.00       ;
   if(LeadingOrder <=2  )  LeadingOrder=2        ;  
   if(Bid==0.0||Ask==0.0) {Print(StringConcatenate("Неправильные цены. Ask: ",Ask," Bid: ",Bid)); return(0);}
   
//********************************************************************************************* 

gvTimeStart = StringConcatenate("GV_","Magic_№ ",MagicNumber," TimeStartOrder ",Symbol());  
   if(!GlobalVariableCheck(gvTimeStart)) {Print("Глобальная переменная gvTimeStart отсутствует. Создаем."); GlobalVariableSet(gvTimeStart, TimeCurrent()==0);}
   if(!GlobalVariableCheck(gvTimeStart)) {Print("Невозможно создать глобальную переменную gvTimeStart."); InitFail = True;}
      else Print("Глобальная переменная gvTimeStart создана успешно.");

//********************************************************************************************* 

cmagic=0; string st; int k=StringLen(MagicNumList);
   for (int a=0; a<k; a++){
      if (StringSubstr(MagicNumList,a,1)!=" "){
         st=st+StringSubstr(MagicNumList,a,1); 
            if(a < k-1) continue;
      }
   if (st!="") {magic[cmagic]=StrToInteger(st); cmagic++; st="";}
   }   

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {          
           if (CurrentCondition() == 0) return     ;
   //************блок обнуления ГП и запрета торговли при наличии ордеров с таким же меджиком на других парах
   //            а так же проверки на корректное значение ГП
   //***  Задаем нужные переменные
   if (!IsTesting() && !IsOptimization() && SymbolControl)      
   { 
     double GlobOrders = NormalizeDouble(GlobalVariableGet(gvOrderSelect), 0);//получили значение ГП
     int SymbOrders = totalord;              //смотрим, есть ли на нашей паре ордера
     bool ExitesOrders  = OrdersOnOtherSymbols(MagicNumber);  //смотрим, есть ли на других парах ордера с нашим меджиком
     string TradeSymbol = GetSymbolByMagic(MagicNumber);      //Получаем имя торгуемого инструмента.

   //***
 
   //***  Запрещаем торговать, если есть ордера на других парах 
   
    
      
       if (GlobOrders > 0 && ExitesOrders)                  //есть ордера на других парах Торговать нельзя!  
       {                                                
           if (Info)Print  (  "Есть ордера на ", TradeSymbol," Торговля запрещена.");
           Indication ("IMulti", 0, 300, 10, "Есть ордера на "+TradeSymbol+" Торговля запрещена.", 15, "Arial", Gold);
            return;                                     //вываливаемся!
           
       }
       //***  Обнуляем ГП, если она!=0, а ордеров с нашим мэджиком в рынке нет       
       if (GlobOrders !=0 && GlobOrders !=100 && SymbOrders == 0 && !ExitesOrders)//и на других парах наших ордеров тоже нет И не ==100(не происходит установка ордера)
       {  
          if(Info) Print ("Наших ордеров в рынке нет, обнуляем ГП");  
          if (GlobalVariableSet(gvOrderSelect,0) == 0)  //обнуляемся и проверяем, получилось ли обнулиться
          {
            if (Info) Print  (  "Ошибка инициализации. Обнулить глобальную переменную gvOrderSelect не получилось.");
            return;
          }
          else                                           
          {
            GlobOrders = NormalizeDouble(GlobalVariableGet(gvOrderSelect), 0);//переинициализировали значение ГП
             if (Info)  {Print  ("ГП=", GlobOrders);
                         Print  ("Наших ордеров в рынке нет. Глобальная переменная gvOrderSelect обнулена.");}
          } 
       }
       if (ObjectFind("IMulti") != -1) ObjectDelete("IMulti");        
       NoTrade = false;
       //***  Проверяем, корректность значения ГП при наличии окрытых ордеров
       if (GlobOrders == 0 && SymbOrders > 0)    //если ГП == 0,а ордера на нашей паре есть
       {  
          if (GlobalVariableSet(gvOrderSelect,SymbOrders) == 0) //обнуляемся и проверяем, получилось ли обнулиться
          {
           if (Info)  Print  (  "Ошибка инициализации. Перезаписать глобальную переменную gvOrderSelect не получилось.");
           return;
          }
          else                                           
          {
           GlobOrders = NormalizeDouble(GlobalVariableGet(gvOrderSelect), 0);//переинициализировали значение ГП
           if (Info)Print  ("Есть ордера в рынке. Глобальная переменная gvOrderSelect презаписана.");
          }    
        }
   }  //***конец блока работы с ГП
   
   spr   = MarketInfo(Symb,MODE_SPREAD     )  ;
   freez = MarketInfo(Symb,MODE_FREEZELEVEL)  ; 
   stlev = MarketInfo(Symb,MODE_STOPLEVEL  )  ;
   Lot   = GetLot()                           ; 
   slip_0  = MarketInfo(Symb,MODE_SPREAD     )*2;
   slip  =  StrToInteger(DoubleToString(slip_0,0)); 
   if (FreeMargin<0 || Balance<0)    return;
   if (Sum_lot >0) sum= 1                     ;  // Суммарный лот серии Buy больше, чем Sell
   if (Sum_lot <0) sum=-1                     ;  // Суммарный лот серии Sell больше, чем Buy
   if (Sum_lot==0) sum= 0                     ;  // Суммарный лот серии Sell равен Buy
   bool   LongTrade = true, ShortTrade =  true;  
   AccBuffer()                                ;
   
//***************  Защита от неправильного выставления стопуровней  ***************************

 string levels_0        =   DoubleToString(spr+freez+stlev,0);
        levels          =   StrToInteger(levels_0);
   if(PipStep    <=levels) PipStep   =levels;
   if(Tral_Start <=levels) Tral_Start=levels; 
   
//=========================================  Режим ручной торговли  ===================================================

if(time() && VisualMode){
bool error  = false;
   if(guiGetText(hwnd,lottxt)!="")LotR=StrToDouble(guiGetText(hwnd,lottxt)         );
   if (guiIsClicked(hwnd,buybtn)){ 
      if (Info) Print("Открываем ордер BUY вручную"                              );
         comment=StringConcatenate("Integra - Pучник, ","Magic : ",MagicNumber   );
            SendOrder(OP_BUY ,LotR,0,0,0,comment,MagicNumber                     );             
   }
   if (guiIsClicked(hwnd,sellbtn)){ 
      if (Info) Print("Открываем ордер SELL вручную"                             );
         comment=StringConcatenate("Integra - Pучник, ","Magic : ",MagicNumber   );
            SendOrder(OP_SELL,LotR,0,0,0,comment,MagicNumber                     );
   }
   if (guiIsClicked(hwnd,closebtn    )) { 
      if (Info) Print("Закрываем BCE ордера вручную"                             );
         error = CloseOrders(                                                    ); 
            if (error && Info) Print ("Ордера BUY и SELL вручную закрыты успешно");
   }
   if (guiIsClicked(hwnd,closesellbtn)) { 
      if (Info) Print("Закрываем SELL ордера вручную"                            ); 
         error = CloseOrders(0,OP_SELL                                           ); 
            if (error && Info) Print ("Ордера SELL вручную закрыты успешно"      ); 
   }    
   if (guiIsClicked(hwnd,closebuybtn )) { 
      if (Info) Print("Закрываем BUY ордера вручную"                             );
         error = CloseOrders(0,OP_BUY                                            ); 
            if (error && Info) Print ("Ордера BUY вручную закрыты успешно"       );
   }   
} 

//===========================================  Управление закрытием ордеров  ==========================================

if (SumProfit<0 && CurrencySL!=0){
   if (MathAbs(SumProfit)>=CurrencySL){
      if (Info) Print("! Просадка превысила заданный уровень !"     );
         CloseFM=true;
   }
} 
     
if (totalord==0)  {CloseAll=false; Close_All=false; CloseFM=false;}


//===============================   Переход на фиксированный лот   ====================================================

if (CurrentDrawdown<=FixLotPercent) fixlot=false; else fixlot=true ;
if (FixLot)  fixlot=true ; 

//=========================================  Расчет динамического профита  ============================================
   
if(Risk!=0) Profit = NormalizeDouble(Lot*DefaultProfit/minLot,2); else Profit = DefaultProfit;  

//============================================  Трейлинг профита  =====================================================

if (UseAccBuffer)    SumProfit+=ProfitOverlap; else SumProfit=SumProfit;
if (SumProfit>(Profit+(Tral_Start+Tral_Size)*TV*Sumlot) && !CloseTrigger && sum != 0) 

   {CloseTrigger=1; TPcolor=ColTPTrail; ZLcolor=ColorZL;}
   
if (!CloseTrigger && totalord>=0 && totord != totalord){
   TPcolor=ColorTP; ZLcolor=ColorZL;
   totord = totalord;
   delta  = (Profit-SumProfit)/TV/Sumlot ; // Число пунктов до профита
   delta2 =  SumProfit/TV/Sumlot         ; // Число пунктов до безубытка 
      switch(sum){
         case  1 : {TPPrice=NormalizeDouble(Bid+delta*Point,Digits); ZeroLine=NormalizeDouble(Bid-delta2*Point,Digits);} break;
         case -1 : {TPPrice=NormalizeDouble(Ask-delta*Point,Digits); ZeroLine=NormalizeDouble(Ask+delta2*Point,Digits);} break;
         case  0 : {TPPrice = 0.0; ZeroLine = 0.0; break;} 
      } 
}
if (IsVisualMode() || !IsOptimization()) {DrawLine("LineTP",TPPrice,TPcolor,2); DrawLine("LineZL",ZeroLine,ZLcolor,0);}
   
//==========================  Триггер трала  ======================================

if (CloseTrigger==1){
bool err  = false;
int to;  
   if (totalbuy >=1 && sum == 1) to=1;
   if (totalsell>=1 && sum == -1) to=2;
   
//=================  Закрытие первых противоположных ордеров серии ================

switch(sum){  
   case -1 : {
      if (totalbuy>=1){
         if (Info) Print("Сработал триггер трала. Закрываем первый ордер BUY." );
            err = CloseOrders(FirstBuyTicket,OP_BUY     );      
               if (err == 1){if (Info) Print ("Первый ордер BUY закрыт успешно. Сопровождаем серию SELL."); Sleep (60);}
            else {Print ("Ошибка закрытия первого ордера BUY");}
            return; 
      }
   }  break;

   case 1 : {
      if (totalsell>=1){
         if (Info) Print("Сработал триггер трала. Закрываем первый ордер SELL.");
            err = CloseOrders(FirstSellTicket,OP_SELL    ); 
               if (err == 1){if (Info) Print ("Первый ордер SELL закрыт успешно. Сопровождаем серию BUY."); Sleep (60);}
            else {Print ("Ошибка закрытия первого ордера SELL");}
            return; 
      }
   }  break;
   default: break;
}
  
//==========================  Buy  ======================================    
      switch(to){    
         case  1 : if (Bid<=NormalizeDouble(TPPrice,Digits) && VirtualTral) {if (Info) Print("Команда трала на закрытие Buy SL" );  CloseAll=true ;}
            else   {if (TPPrice<(Bid-Tral_Size*Point)) TPPrice=NormalizeDouble(Bid-Tral_Size*Point,Digits ); 
                   if (!VirtualTral) {for ( z = 0; z < totalbuy; z++) fTrailing(TicketB[z], Tral_Start, Tral_Size, Symbol(), OP_BUY, MagicNumber, false);}}
                   break;
                   
//==========================  Sell  ======================================             
         case  2 : if (Ask>=NormalizeDouble(TPPrice,Digits) && VirtualTral) {if (Info) Print("Команда трала на закрытие Sell SL");  CloseAll=true ;}
            else   {if (TPPrice>(Ask+Tral_Size*Point)) TPPrice=NormalizeDouble(Ask+Tral_Size*Point,Digits );
                   if (!VirtualTral) {for ( z = 0; z < totalsell; z++) fTrailing(TicketS[z], Tral_Start, Tral_Size, Symbol(), OP_SELL, MagicNumber, false);}}   
                   break;
         default : CloseTrigger = 0; break;   
      } 
}

bool er=false;
   if (Close_All || CloseAll || CloseFM){
      if (Info) Print("<<<<< Закрываем ВСЕ рыночные ордера <<<<<"   ); 
         er = CloseOrders(                                          );
            if (er && Info) Print ("! Все ордера закрыты успешно !" );
            if (er)  DeleteObject(); // Сброс триггера и очистка экрана
            if (Info && Close_All)   Print("Закрыть ВСЁ");
   return;
   }

//********************************************************************************************* 

if (Info){
   MainIndication(); 
   PriceCCI(Level);   
}
if (Vxod_CCI || Sopr_CCI)   SignCCI = Signal_CCI();
if (!Sopr_Lock){
      switch(sum){    
      case  1 : ShortTrade = false;  break;           
      case -1 : LongTrade  = false;  break; 
   }  
}
//============================================================  Начало серии  ===================================================
if (NewCycle_ON && time() && !Close_All && !NoTrade && !CloseTrigger){
double StartLot               ; 
 ticketbuy=0; 
 ticketsell=0 ; 
//=========================================================  Открытие замка  ====================================================



if ((totalbuy == 0) && ((SignCCI == 1 || !Vxod_CCI) || (Vxod_Lock && totalsell ==0))){
    StartKolenoB = TimeCurrent();
    if (totalsell == 0) StartLot = NormalizeDouble(Lot,dig)      ; 
    else  StartLot = NormalizeDouble(LastLotSell,dig)      ;
    if(Info) Print("! Начало новой серии !") ;
    if(Info) Print("Открываем первый ордер - BUY");
    comment=StringConcatenate("1-й ордер Buy, ","Magic : ",MagicNumber)              ;
    ticketbuy  = SendOrder(OP_BUY , StartLot, 0, 0, MagicNumber, comment, Error)  ;
    if (Info &&( !IsTesting() || !IsOptimization())) {PlaySound("alert.wav"); Sleep(60) ;} 
}
if (totalsell == 0 && ((SignCCI == -1 || !Vxod_CCI) || (Vxod_Lock && totalbuy == 0))){
    StartKolenoS = TimeCurrent();
    if (totalbuy == 0) StartLot = NormalizeDouble(Lot,dig)      ; 
    else  StartLot = NormalizeDouble(LastLotBuy,dig)      ;
    if(Info) Print("! Начало новой серии !") ;
    if(Info) Print("Открываем первый ордер - SELL");
    comment=StringConcatenate("1-й ордер Sell, ","Magic : ",MagicNumber)             ;
    ticketsell = SendOrder(OP_SELL, StartLot, 0, 0, MagicNumber, comment, Error)  ;
    if (Info &&( !IsTesting() || !IsOptimization())) {PlaySound("alert.wav"); Sleep(60) ;} 
}                      
    
}      

//=====================================================  Сопровождение серии  ===================================================

if (time() && !Close_All && !NoTrade && !CloseTrigger){  
double NewLot,afmc;
int    tots=0,totb=0;
ObjectDelete("InewLot");

 
      //==========================  Buy  ======================================

   if (UseTrailingStop && totalbuy>=StartTS){
   
       fTrailing(TicketB[0], TrailingStop, TrailingStep, Symbol(), OP_BUY);
       if (IsVisualMode() || !IsOptimization()){
          if (ObjectFind("ILastTPB") != -1 && totb != totalbuy) ObjectDelete("ILastTPB"); 
          DrawLine("ILastTPB",LastPriceBuy+TrailingStop*Point,MediumOrchid,1);
          if (ObjectGet("ILastTPB",OBJPROP_PRICE1) != LastSLBuy-2*Point && LastSLBuy > 0){
              ObjectDelete("ILastTPB");
              DrawLine("ILastTPB",LastSLBuy,Yellow,1);
          }
          totb = totalbuy;
       }                                           
   }
   if (totalbuy < StartTS && ObjectFind("ILastTPB") != -1) ObjectDelete("ILastTPB");
   if (totalbuy>0 && totalbuy<=MaxTrades && LongTrade && TimeCurrent()-StartKolenoB>mper[CCI_TimeFrame]*TimeStep*60){
   
 
//       if ((Ask>(LastPriceBuy+PipstepBuy*Point))||((Ask<(LastPriceBuy-1*PipstepBuy*Point))&& totalsell>=1)){
      if (Ask>(LastPriceBuy+PipstepBuy*Point)){  
         NewLot = NewLot(OP_BUY)                                 ;
            afmc = AccountFreeMarginCheck(Symb, OP_BUY, NewLot)  ;
if(Info) Indication ("InewLot",3,10,115,StringConcatenate("Ожидаем ордер: Buy ",DoubleToStr(NewLot,dig)," / ","Оcтанется : $",DoubleToStr(afmc,0)),FontSize,"Arial",ColorInd);            
           
      if(afmc<=0) return; else
          
         if (GetMASignalS()==1 || TipMAFilter!=1){
            if (GetMASignalK()==1 || TipMAFilter!=2){
               if (SignCCI==1 || !Sopr_CCI){
                  if (Info)  Print("Открываем колено - BUY")                                          ;   
                     comment=StringConcatenate(totalbuy+1,"-й ордер Buy, " ,"Magic : ",MagicNumber)   ;
                        ticketbuy = SendOrder(OP_BUY, NewLot, 0, 0, MagicNumber, comment, Error)      ;
                        StartKolenoB = TimeCurrent();
                  if (Info && (!IsTesting() || !IsOptimization())){ PlaySound("alert.wav"); Sleep(60) ;}     
               }         
            }
         }     
      }         
   }   
      
      //==========================  Sell  =====================================

   if (UseTrailingStop && totalsell>=StartTS){
      
       fTrailing(TicketS[0], TrailingStop, TrailingStep, Symbol(), OP_SELL)                                          ;
       if (IsVisualMode() || !IsOptimization()){
          if (ObjectFind("ILastTPS") != -1 && tots != totalsell) ObjectDelete("ILastTPS"); 
          DrawLine("ILastTPS",LastPriceSell-TrailingStop*Point,MediumOrchid,1);
          if (ObjectGet("ILastTPS",OBJPROP_PRICE1) != LastSLSell-2*Point && LastSLSell > 0){
              ObjectDelete("ILastTPS");
              DrawLine("ILastTPS",LastSLSell,Yellow,1);
          }
          tots = totalsell;
       }                                           
   }
   if (totalsell < StartTS && ObjectFind("ILastTPS") != -1) ObjectDelete("ILastTPS");
   if (totalsell>0 && totalsell<=MaxTrades && ShortTrade && TimeCurrent()-StartKolenoS>mper[CCI_TimeFrame]*TimeStep*60){
      
//      if ((Bid<(LastPriceSell-PipstepSell*Point))||((Bid>(LastPriceSell+1*PipstepSell*Point))&& totalbuy>=1)){
      if (Bid<(LastPriceSell-PipstepSell*Point)){ 
         NewLot = NewLot(OP_SELL)                                ;
            afmc = AccountFreeMarginCheck(Symb, OP_SELL, NewLot) ;
if(Info) Indication ("InewLot",3,10,115,StringConcatenate("Ожидаем ордер: Sell ",DoubleToStr(NewLot,dig)," / ","Оcтанется : $",DoubleToStr(afmc,0)),FontSize,"Arial",ColorInd);            
  
      if(afmc<=0) return; else
         if (GetMASignalS()==-1 || TipMAFilter!=1){
            if (GetMASignalK()==-1 || TipMAFilter!=2){
               if (SignCCI==-1 || !Sopr_CCI){
                  if (Info)  Print("Открываем колено - SELL")                                         ; 
                     comment=StringConcatenate(totalsell+1,"-й ордер Sell, ","Magic : ",MagicNumber)  ;
                        ticketsell = SendOrder(OP_SELL, NewLot, 0, 0, MagicNumber, comment, Error)    ; 
                        StartKolenoS = TimeCurrent();  
                  if (Info &&( !IsTesting() || !IsOptimization())){ PlaySound("alert.wav"); Sleep(60) ;}
               }
            }  
         } 
      }        
   }            
}  
  
//=====================================================  Перекрытие ордеров  ====================================================

if (LeadingOrder>=2 && !CloseTrigger){ 
LCprofit=Lprofit+Cprofit;
L1Cprofit=LCprofit+Lprofit1;

   if (totalbuy>=LeadingOrder){
      if(Lprofit>0 && Cprofit<0){
         if(LCprofit>0 && LCprofit*100/Lprofit>ProfitPersent){
            Lpos1 = 0;
            CloseSelectOrder(OP_BUY);
            return; 
         }
      }  
      if(Lprofit>0 && Lprofit1>0 && totalbuy>LeadingOrder && Cprofit<0){
         if(L1Cprofit> 0 && L1Cprofit*100/(Lprofit + Lprofit1)>SecondProfitPersent) 
            CloseSelectOrder(OP_BUY); 
            return;         
      }
   } 

   if (totalsell>=LeadingOrder){
      if(Lprofit>0 && Cprofit<0){
         if(LCprofit>0 && LCprofit*100/Lprofit>ProfitPersent){
            Lpos1 = 0;
            CloseSelectOrder(OP_SELL);
            return; 
         }
      }  
      if(Lprofit>0 && Lprofit1>0 && totalsell>LeadingOrder && Cprofit<0){
         if(L1Cprofit> 0 && L1Cprofit*100/(Lprofit + Lprofit1)>SecondProfitPersent) 
            CloseSelectOrder(OP_SELL);          
      }
   }   
}        
                                                              
//===============================================================================================================================
   

   
  }
//+------------------------------------------------------------------+
//=========================================================================================================================================//
// Kordan . Функция удаления объектов                                                                                                      //
//=========================================================================================================================================//

int DeleteObject() {
CloseTrigger=0; TPPrice=0; ZeroLine=0     ;
int    ObjTotal = ObjectsTotal()          ;
string ObName                             ;
   for(int i = 0; i < ObjTotal; i++){
   ObName = ObjectName(i)                 ;
      if(StringSubstr(ObName,0,1) == "I" 
      || StringSubstr(ObName,0,1) == "i") { 
         ObjectDelete(ObName)             ;
            Comment("")                   ; 
         i = i - 1                        ;
      }
   }
return(0);      
}


string GetSymbolByMagic(int MagicGetSbM)
{
  string ResultGetSbM = "";
  for(int SbM = 0; SbM < OrdersTotal(); SbM++)
    if(OrderSelect(SbM, SELECT_BY_POS))
      if(OrderMagicNumber() == MagicGetSbM)
      {
        ResultGetSbM = OrderSymbol();
        break;
      }
  return(ResultGetSbM);
}

bool OrdersOnOtherSymbols(int mn=-1) {
int im, k=OrdersTotal();

  for (im=0; im<k; im++) {
    if (OrderSelect(im, SELECT_BY_POS, MODE_TRADES)) {
      if (OrderMagicNumber()==mn && OrderSymbol()!=Symbol()) return(True);
        }
      }
   return(False);
}


//=========================================================================================================================================//
// Kordan . Индикация                                                                                                                      //
//=========================================================================================================================================//   

void Indication (string Indic_name,int Indic_corner,int Indic_Xdist,int Indic_Ydist,string Indic_txt,int Indic_fontsize,string Indic_font,color Indic_col){
   if (ObjectFind(Indic_name)<0)
      ObjectCreate(Indic_name,OBJ_LABEL,0,0,0)             ; 
         ObjectSet(Indic_name, OBJPROP_CORNER, Indic_corner)     ;
            ObjectSet(Indic_name, OBJPROP_XDISTANCE, Indic_Xdist);
         ObjectSet(Indic_name, OBJPROP_YDISTANCE, Indic_Ydist)   ;
      ObjectSetText(Indic_name,Indic_txt,Indic_fontsize,Indic_font,Indic_col)      ; 
} 

//=========================================================================================================================================//
// Kordan . Функция расчета начального лота                                                                                                //
//=========================================================================================================================================//

double GetLot(){  
      double GetLot_lot=0                                              ;
      if(Risk!=0){
         for (int t = 1; t <= MaxTrades; t++)                        // Если кол-во лотов заданно в % от свободных средств,
            div +=MathPow(LotExponent,t-1)                     ; 
      GetLot_lot  =MathAbs(FreeMargin*Risk/100/div/One_Lot/Step)*Step ;
      }                                                              // то считаем стоимость лота
      else GetLot_lot  =MathMax(DefaultLot,minLot)                    ;     // иначе выставляется заданное значение DefaultLot не меньше мин. размерa лота
      if(GetLot_lot<minLot) GetLot_lot=minLot                                ;     // Не меньше минимального  размерa лотa
      if(MaxLot==0 ) GetLot_lot=GetLot_lot; else
                     GetLot_lot=MathMin(MaxLot, GetLot_lot)                  ;     // Не больше максимально установленного размерa лотa                                                                  
      if (GetLot_lot*One_Lot>FreeMargin){                                   // Если лот дороже свободных средств,
         if (IsTesting()){                                           // то выводим сообщение в режиме Тест,
            Indication ("INoMoney",2,xDist1,40,"Недостаточно средств!!!",FontSize+5,"Courier",Red) ;  // Нулевая маржа              
         }
            else{ 
            Indication ("INoMoney",2,xDist1,40,"Недостаточно средств!!! Торговля остановлена!!!",FontSize+5,"Courier",Red); 
               NoTrade=TRUE                                    ;     // останавливаем торговлю
            }          
         return(0)                                             ;     // и выходим из функции start()
      } 
      else  ObjectDelete("INoMoney")                           ;                                          
return(GetLot_lot)                                             ;
}



//=========================================================================================================================================//
// amber631 . Функция фильтра по времени                                                                                                   //
//=========================================================================================================================================// 

bool time(){
bool tresult=false;
   if (((Hour()<StartHourMonday && DayOfWeek()==1) || (Hour()>=EndHourFriday && DayOfWeek()==5)) && UseFilterTime)   tresult=false;
      else tresult=true;   
   if ((Day()<StartMonth+1 || ((Day()<7)&& Month()==1)) && UseFilterDate)                                            tresult=false;
      else tresult=true;   
   if ((Day()>31-EndMonth || ((Day()>28-EndMonth)&& Month()==2) || (Day()>30-EndMonth &&
      ((Month()==4) || (Month()==6) || (Month()==9) || (Month()==11))))&& UseFilterDate)                             tresult=false;
      else tresult=true; 
return(tresult);   
}

//=========================================================================================================================================//
// ir0407 . Функция открытия ордеров                                                                                                       //
//=========================================================================================================================================//   

int SendOrder (int SeType, double SeLots, int SeTP, int SeSL, int Semagic, string SeCmnt, int SeError){


double SePrice, SeTake, SeStop;
int  SeColor; 
bool SeDelay = False;
while(!IsStopped()){  
   if (!IsTesting()){ //Если мы не в режиме тестирования
      if(!IsExpertEnabled()){ SeError = 133; Print ("Эксперту запрещено торговать! Кнопка \"Советники\" отжата."); return(-1); }
         if(!IsConnected() ){ SeError =   6; Print ("Связь отсутствует!")                                        ; return(-1); }
            if(IsTradeContextBusy()){
               Print("Торговый поток занят!");
               Print(StringConcatenate("Ожидаем ",PauseTrade," cek"));
               Sleep(PauseTrade*60);
               SeDelay = True;
               continue;
            }
         if(SeDelay){ if(Info) Print("Обновляем котировки"); RefreshRates(); SeDelay = False; }
      else if (Info) Print("Котировки актуальны");
      }
            switch(SeType){
               case OP_BUY:
                SePrice = NormalizeDouble( Ask, Digits);
                SeTake = IIFd(SeTP == 0, 0, NormalizeDouble( Ask + SeTP * Point, Digits));
                SeStop = IIFd(SeSL == 0, 0, NormalizeDouble( Ask - SeSL * Point, Digits));
                SeColor = Blue;
                break;
             case OP_SELL:
                 SePrice = NormalizeDouble( Bid, Digits);
                 SeTake = IIFd(SeTP == 0, 0, NormalizeDouble( Bid - SeTP * Point, Digits));
                 SeStop = IIFd(SeSL == 0, 0, NormalizeDouble( Bid + SeSL * Point, Digits));
                 SeColor = Red;
                 break; 
             default:
               Print("!Тип ордера не соответствует требованиям!");
               return(-1);
             }   
       string NameOP=GetNameOP(SeType);         
       if (Info) Print(StringConcatenate("Ордер: ",NameOP," / "," Цена=",SePrice," / ","Lot=",SeLots," / ","Slip=",slip," pip"," / ",SeCmnt)); 
       
	if(IsTradeAllowed()){
		if (Info) Print(">>>>>Торговля разрешена, отправляем ордер >>>>>");
			SeTicket = OrderSend(Symb, SeType, SeLots, SePrice, slip, SeStop, SeTake, SeCmnt, Semagic, 0, SeColor);
   
		if(SeTicket < 0){
         Err = GetLastError();
         if(Err == 4   || /* SERVER_BUSY */      
            Err == 129 || /* ERR_INVALID_PRICE */
            Err == 130 || /* INVALID_STOPS */    
            Err == 135 || /* PRICE_CHANGED */     
            Err == 137 || /* BROKER_BUSY */        
            Err == 138 || /* REQUOTE  */          
            Err == 146 || /* TRADE_CONTEXT_BUSY */
            Err == 136 ){ /* OFF_QUOTES   */     
               if (!IsTesting()){
                  Print(StringConcatenate("Ошибка(OrderSend - ",Err,"): ",ErrorDescription(Err), ")"));
                  Print(StringConcatenate("Ожидаем ",PauseTrade," cek"));
                  Sleep (PauseTrade*60);
                  SeDelay = True;
               continue;
               }
               else{
                  Print(StringConcatenate("Критическая ошибка(OrderSend - ",Err,"): ",ErrorDescription(Err), ")"));
                  SeError = Err;
               break;
               }
         }
		}
      break;
	}
      else { if(Info) Print("Эксперту запрещено торговать! Снята галка в свойствах эксперта.");                                    break;}
}
   if(SeTicket>0) {if(Info) Print(StringConcatenate("Ордер отправлен успешно. Тикет = ",SeTicket))                                          ;}
   else         {if(Info) Print(StringConcatenate("Ошибка! Ордер не отправлен. (Код ошибки = ",SeError,": ",ErrorDescription(SeError), ")"));}
   return(SeTicket);
}


//=========================================================================================================================================//
// KimIV . Функция "если-то" для double                                                                                                    //
//=========================================================================================================================================//

double IIFd(bool condition, double ifTrue, double ifFalse) 
{if (condition) return(ifTrue); else return(ifFalse);}
//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Возвращает наименование торговой операции                      |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    op - идентификатор торговой операции                                    |
//+----------------------------------------------------------------------------+
string GetNameOP(int op){
   switch (op) {
      case OP_BUY      : return("BUY"       );
      case OP_SELL     : return("SELL"      );
      case OP_BUYLIMIT : return("BUY LIMIT" );
      case OP_SELLLIMIT: return("SELL LIMIT");
      case OP_BUYSTOP  : return("BUY STOP"  );
      case OP_SELLSTOP : return("SELL STOP" );
      default          : return("Unknown Operation");
   }
}

//+----------------------------------------------------------------------------+
//|  Автор    : Ким Игорь В. aka KimIV,  http://www.kimiv.ru                   |
//+----------------------------------------------------------------------------+
//|  Версия   : 01.09.2005                                                     |
//|  Описание : Возвращает наименование дня недели                             |
//+----------------------------------------------------------------------------+
//|  Параметры:                                                                |
//|    ndw - номер дня недели                                                  |
//+----------------------------------------------------------------------------+
string NameDayOfWeek(int ndw){
   if (ndw==0) return("Воскресенье") ;
   if (ndw==1) return("Понедельник") ;
   if (ndw==2) return("Вторник"    ) ;
   if (ndw==3) return("Среда"      ) ;
   if (ndw==4) return("Четверг"    ) ;
   if (ndw==5) return("Пятница"    ) ;
   if (ndw==6) return("Суббота"    ) ;
   return("0");
}  


//=========================================================================================================================================//
// ir0407 + Kordan + Pyyx. Функция закрытия выбранных ордеров                                                                              //
//=========================================================================================================================================//  

bool CloseOrders(int tick=0, int tipii=-1){
bool Delay = False;
double  ClosePrice;
color   CloseColor;
int  n;
	if (!IsTesting()){ //Если мы не в режиме тестирования
		if(!IsExpertEnabled()) {Error = 133; Print("Эксперту запрещено торговать!"); return(false);}
		if(!IsConnected()) Print("Связь с сервером отсутствует!"   );  else if(Info) Print("Связь с сервером установлена");
	}
	
   for(int trade=OrdersTotal()-1; trade>= 0; trade--){
		if(OrderSelect(trade, SELECT_BY_POS, MODE_TRADES)){
			if(OrderSymbol() == Symb && (OrderMagicNumber()==MagicNumber || MagicCheck()) && (OrderType()==tipii || tipii==-1)){
			n=0;
				if (OrderTicket()==tick || tick==0){
					while(!IsStopped()){
						if(n>10) break;
						if (Info) Print("Закрываем ордер #", OrderTicket());
						else if (Info) {Print(StringConcatenate("Ордер с тикетом #", OrderTicket(), " отсутствует")); break;}   
							if(IsTradeContextBusy()){
								Print("Торговый поток занят!");
								Print(StringConcatenate("Ожидаем ",PauseTrade," cek"));
								Sleep(PauseTrade*60);
								Delay = True;
								continue;
							}
						if (Delay){if (Info) Print("Обновляем котировки"); RefreshRates(); Delay = False;}
						switch(OrderType()){
							case OP_BUY : ClosePrice = NormalizeDouble(Bid, Digits); CloseColor = Blue; break;
							case OP_SELL: ClosePrice = NormalizeDouble(Ask, Digits); CloseColor = Red ; break;
						}
						
				if (Info) Print(StringConcatenate("Ордер: ","Тикет=",OrderTicket()," / ","Цена закрытия=",ClosePrice," / ","Slip = ",slip," pip")); 
					if(!IsTradeAllowed()) {Print("Эксперту запрещено торговать, снята галка в свойствах эксперта!"); return(false);}
						else{
							if(!OrderClose(OrderTicket(), OrderLots(), ClosePrice, slip, CloseColor)){
								Err = GetLastError();
							if(Err == 4   || //* SERVER_BUSY       
								Err == 129 || //* ERR_INVALID_PRICE 
								Err == 130 || //* INVALID_STOPS    
								Err == 135 || //* PRICE_CHANGED     
								Err == 137 || //* BROKER_BUSY       
								Err == 138 || //* REQUOTE           
								Err == 146 || //* TRADE_CONTEXT_BUSY
								Err == 136 ){ //* OFF_QUOTES        
								if (Info){
									Print(StringConcatenate("Ошибка(OrderClose - ",Err,"): ",ErrorDescription(Err), ")"));
									Print(StringConcatenate("Ожидаем ",PauseTrade," cek"));}
									Sleep(PauseTrade*60);
									Delay = True; n++;
									continue;
                        }
							else {Print(StringConcatenate("Критическая ошибка(OrderClose - ",Err,"): ",ErrorDescription(Err), ")")); break;}
							}
                     break;
                  }
                  break;
               }// конец while(!IsStopped())                                 
            } 
         }   
      }
   }
   return(true);
}
//---------------------------------------------------------------+


//=========================================================================================================================================//
// Qimer . Отрисовка линий                                                                                                                 //
//=========================================================================================================================================//

void DrawLine(string DrL_name,double DrL_price, color DrL_col, int DrL_width){
  if (ObjectFind(DrL_name)<0)
      ObjectCreate(DrL_name,OBJ_HLINE,0,0,DrL_price); 
         else 
            ObjectMove(DrL_name,0,Time[1],DrL_price);
         ObjectSet(DrL_name,OBJPROP_COLOR,DrL_col)  ;
      ObjectSet(DrL_name,OBJPROP_WIDTH,DrL_width)   ;
}
//==================================================================================================================
void fTrailing(int tic, double stop, int step, string or_symbol = "", int or_type = -1, int or_magic = -1, bool ProfitTral = true) 
{
   double point;
   double price;

   
   if (or_symbol == "0") or_symbol = Symbol();
   if (TrailingStop < MarketInfo(Symbol(), MODE_STOPLEVEL)) TrailingStop = MarketInfo(Symbol(), MODE_STOPLEVEL);

      if (OrderSelect(tic, SELECT_BY_TICKET)) 
      {
         if ((OrderSymbol() == or_symbol || or_symbol == "") && or_type < OP_BUYLIMIT) 
         {
            point = MarketInfo(OrderSymbol(), MODE_POINT);
            if (or_magic < 0 || OrderMagicNumber() == or_magic) 
            {
               if (OrderType() == OP_BUY && OrderType() == or_type) 
               {
                  price = MarketInfo(OrderSymbol(), MODE_BID);
                  if (!ProfitTral || price - OrderOpenPrice() > (stop+step) * point)
                     if (OrderStopLoss() < price - (stop + step - 1) * point || OrderStopLoss() == 0.0) 
                         fModifyOrder(-1, price - stop * point, -1);
               }
               if (OrderType() == OP_SELL && OrderType() == or_type) 
               {
                  price = MarketInfo(OrderSymbol(), MODE_ASK);
                  if (!ProfitTral || OrderOpenPrice() - price > (stop+step) * point)
                     if (OrderStopLoss() > price + (stop + step - 1) * point || OrderStopLoss() == 0.0) 
                         fModifyOrder(-1, price + stop * point, -1);
               }
            }
         }
      }
 
}
//==================================================================================================================
void fModifyOrder(double order_open_price = -1.0, double order_stoploss = 0.0, double order_takeprofit = 0.0, int date_time = 0) 
{
   bool is_modify;
   double price_ask;
   double price_bid;
   int error;
   
   
   if (order_open_price <= 0.0) order_open_price = OrderOpenPrice();
   if (order_stoploss < 0.0) order_stoploss = OrderStopLoss();
   if (order_takeprofit < 0.0) order_takeprofit = OrderTakeProfit();
   order_open_price = NormalizeDouble(order_open_price, Digits);
   order_stoploss = NormalizeDouble(order_stoploss, Digits);
   order_takeprofit = NormalizeDouble(order_takeprofit, Digits);
   double nd_oop = NormalizeDouble(OrderOpenPrice(), Digits);
   double nd_osl = NormalizeDouble(OrderStopLoss(), Digits);
   double nd_otp = NormalizeDouble(OrderTakeProfit(), Digits);
   if (order_open_price != nd_oop || order_stoploss != nd_osl || order_takeprofit != nd_otp) 
   {
      for (int i = 1; i <= 3; i++) 
      {
         if (!IsTesting() && (!IsExpertEnabled() || IsStopped())) break;
         while (!IsTradeAllowed()) Sleep(60);
         RefreshRates();
         is_modify = OrderModify(OrderTicket(), order_open_price, order_stoploss, order_takeprofit, date_time);
         if (is_modify) break;
         error = GetLastError();
         price_ask = MarketInfo(OrderSymbol(), MODE_ASK);
         price_bid = MarketInfo(OrderSymbol(), MODE_BID);
         Sleep(60);
      }
   }
}


//=========================================================================================================================================//
// Kordan . Функция главной индикации                                                                                                      //
//=========================================================================================================================================//

void MainIndication() {         

//========================================  Oтрисовкa профита и лотов ордеров =============================================================

int TotalBuyOrd  = 1;
int TotalSellOrd = 1;
string ObName;
for( imi = 0; imi < ObjectsTotal(); imi++){
   ObName = ObjectName(imi);
      if(StringSubstr(ObName,0,1) == "imi"){ 
         ObjectDelete(ObName);
      imi = imi - 1;
   }
}

for(imi=totalbuy-1;imi>=0;imi--){
bool select11=OrderSelect(TicketB[imi],SELECT_BY_TICKET)         ; 
ObjectCreate (StringConcatenate("iB",TotalBuyOrd), OBJ_TEXT, 0, Time[40]     ,OrderOpenPrice());
ObjectSetText(StringConcatenate("iB",TotalBuyOrd), StringConcatenate("Lot: " ,DoubleToStr(OrderLots(), 2)," Prof: ",DoubleToStr(OrderProfit(),2)), 8, "Verdana", DeepSkyBlue);
   TotalBuyOrd ++;
}

for(imi=totalsell-1;imi>=0;imi--){
bool select12=OrderSelect(TicketS[imi],SELECT_BY_TICKET)          ; 
ObjectCreate (StringConcatenate("iS",TotalSellOrd), OBJ_TEXT, 0, Time[40]    ,OrderOpenPrice());
ObjectSetText(StringConcatenate("iS",TotalSellOrd), StringConcatenate("Lot: ",DoubleToStr(OrderLots(), 2)," Prof: ",DoubleToStr(OrderProfit(),2)), 8, "Verdana", DarkOrange );
   TotalSellOrd ++;
}

//=========================================================================================================================================

//+------------------------------------------------------------------+
//| Expert initialization function                                   |TimeToString(
//   datetime  value,                           // число
//  int       mode=TIME_DATE|TIME_MINUTES      // формат вывода
//   );
//+------------------------------------------------------------------+

   if(ObjectFind("DrawDown")>=0){
       // time_coordinate=ObjectGet("DrawDown",OBJPROP_TIME1)       ;
        int shift=iBarShift(Symb,0,time_coordinate)                        ;
        double price_coordinate=iHigh(Symb,0,shift)+(WindowPriceMax()-WindowPriceMin())/20 ;
        bool changed=ObjectSet("DrawDown",OBJPROP_PRICE1,price_coordinate) ;
    }
  
    if(DrawDownRate<(AccountBalance()+AccountCredit()-AccountEquity()+AccountCredit())/AccountBalance()+AccountCredit()){
        ObjectDelete("DrawDown")                           ;
        DrawDownRate=(AccountBalance()+AccountCredit()-AccountEquity()+AccountCredit())/AccountBalance()+AccountCredit();
        time_coordinate=Time[0];
        ObjectCreate("DrawDown",OBJ_ARROW,0,Time[0],High[0]+(WindowPriceMax()-WindowPriceMin())/20);
        ObjectSet("DrawDown",OBJPROP_ARROWCODE,117)                                                ;
        ObjectSet("DrawDown",OBJPROP_COLOR,DarkOrange)                                             ;
        ObjectSet("DrawDown",OBJPROP_TIMEFRAMES,0)                                                 ;
        ObjectSetText("DrawDown",StringConcatenate(DoubleToStr(DrawDownRate*100,2)," %"))          ;
    }
 
      if (Sredstva >= Balance/6*5) col = ColorInd          ; 
      if (Sredstva >= Balance/6*4 && Sredstva < Balance/6*5) col = DeepSkyBlue ;
      if (Sredstva >= Balance/6*3 && Sredstva < Balance/6*4) col = Gold        ;
      if (Sredstva >= Balance/6*2 && Sredstva < Balance/6*3) col = OrangeRed   ;
      if (Sredstva >= Balance/6   && Sredstva < Balance/6*2) col = Crimson     ;
      if (Sredstva <  Balance/6                            ) col = Red         ;
     
   //-------------------------
   
   string spips;
   double pips=NormalizeDouble((AccountEquity()-AccountStopoutLevel()*AccountEquity()/ 100.0)/Sumlot/TV,0) ;
   string lock=DoubleToStr(NormalizeDouble(Sumlot/100*LockPercent,dig),dig);
      if (sum !=0){
                Prof  = StringConcatenate("До профита "  ,DoubleToStr(delta+Tral_Start, 0)," пунктов");  // Число пунктов до профита
                Bezub = StringConcatenate("До безубытка ",DoubleToStr(delta2          , 0)," пунктов");  // Число пунктов до безубытка       
            if (sum ==-1){
               spips = StringConcatenate("До слива ",pips," пунктов вверх")  ;
               lock  = StringConcatenate("Ордер для лока: Buy ",lock)        ;
            }
               else{ 
                  spips = StringConcatenate("До слива ",pips," пунктов вниз");
                  lock  = StringConcatenate("Ордер для лока: Sell ",lock)    ;
               }
      }
                  else{
                     if (SumLotBuy==0 && SumLotSell==0){
                        spips="Нет ордеров"; Prof=""; Bezub="" ;
                     }
                        else{
                           spips ="Ждем первое колено"         ;
                           Prof  ="Трал отдыхает"              ;
                           Bezub ="Выставлен замок"            ;
                        }
                        lock = StringConcatenate("Процент локового ордера = ",LockPercent);
                  }                                

//==========================  Левый верхний угол  =====================================
     
if (MaxLot!=0) maxLot=MaxLot                                   ; 
   if (IsDemo())  tip = "Демо"; else tip = "Реал"        ;  
   Comment(  
      "\n", StringConcatenate(" Счет : ",tip," - №: ",AccountNumber()," / ",AccountCompany()), 
      "\n", StringConcatenate(" Серверное время = ", TimeToStr(TimeCurrent(),TIME_SECONDS))," / ",NameDayOfWeek(DayOfWeek()),
      "\n", StringConcatenate(" Макс. лот = ",NormalizeDouble(maxLot,dig)," / "," Мин.  лот = ",NormalizeDouble(minLot,dig)),
      "\n", StringConcatenate(" Плечо = ",AccountLeverage()," : 1  / "," Спред = ",spr),    
      "\n", StringConcatenate(" Уровни : Заморозки = ",freez," / "," Стопов = ",stlev," / "," StopOut = ",AccountStopoutLevel(),"%"), 
      "\n", StringConcatenate(" Свопы : Buy = ",MarketInfo(Symb, MODE_SWAPLONG)," / "," Sell = ",MarketInfo(Symb, MODE_SWAPSHORT)), 
      "\n","====================================",
      "\n"
        );   
            
//==========================  Левый нижний угол и центр ===============================

   if ( fixlot      ) txt="Фиксированный лот"; else txt="Динамический лот"                                         ;
   if (!NewCycle_ON ) Indication ("INewCycleON",2,10,120,"Запрет начала нового цикла",FontSize,"Arial",ColorInd);
   switch (TipMAFilter){
   case 1:{  
         if (GetMASignalS()==-1 || GetMASignalS()==0) Indication ("ILevelBuy" ,2,10,105,"Запрет Buy" ,FontSize,"Arial",ColorInd ); else ObjectDelete("ILevelBuy" );
         if (GetMASignalS()== 1 || GetMASignalS()==0) Indication ("ILevelSell",2,10,90 ,"Запрет Sell",FontSize,"Arial",ColorInd ); else ObjectDelete("ILevelSell");
   }
   break;
   case 2:{  
         if (GetMASignalK()== 1) Indication ("ILevelBuy" ,2,10,105,"Запрет Buy" ,FontSize,"Arial",ColorInd ); else ObjectDelete("ILevelBuy" );
         if (GetMASignalK()==-1) Indication ("ILevelSell",2,10,90 ,"Запрет Sell",FontSize,"Arial",ColorInd ); else ObjectDelete("ILevelSell");
   } 
   break;
}
   if (!time()      ) Indication ("Itime",2,10,75 ,"Включен фильтр выходныx дней",FontSize,"Arial",ColorInd); else ObjectDelete("Itime"     );
   if (!CloseTrigger) tral=""; else tral="Поздравляю! Пошел трал профита!";
Indication ("ITrail",2,xDist1,30,tral,FontSize+5,"Courier",Lime);   
Indication ("IFixLot",2,10,60 ,txt,FontSize,"Arial",ColorInd);   

//==========================  Правый нижний угол  ===================================== 

Indication ("Ispips"   ,3,10,55 ,spips,FontSize,"Arial",col)     ;      
Indication ("Ilock"    ,3,10,10 ,lock ,FontSize,"Arial",ColorInd);
Indication ("IProf"    ,3,10,40 ,Prof ,FontSize,"Arial",col)     ;  
Indication ("IBezub"   ,3,10,25 ,Bezub,FontSize,"Arial",col)     ;  
Indication ("IMaxDrDown",3,10,145,StringConcatenate("Макс. Просадка: ",DoubleToStr(MathMax(DrawDownRate,0)*100,2)," %"),FontSize,"Arial",ColorInd);  
Indication ("IBalance ",3,10,100,StringConcatenate("Баланс   ",DoubleToStr(Balance,        2),"  ",AccountCurrency()),FontSize,"Arial",ColorInd);
Indication ("IEquity  ",3,10,85 ,StringConcatenate("Свободно ",DoubleToStr(FreeMargin     ,2),"  ",AccountCurrency()),FontSize,"Arial",col)     ; 
Indication ("IDrawDown",3,10,70 ,StringConcatenate("Просадка ",DoubleToStr(CurrentDrawdown,2) ,"%"),FontSize,"Arial",col); 

if (totalord!=0) Indication ("ICurUrov" ,3,10,130,StringConcatenate("Уровень: ",DoubleToStr(CurrentUrov,0),"%"),FontSize,"Arial",ColorInd); else ObjectDelete("ICurUrov");

   if (SumProfit    <0)  ColProf= LightCoral  ; else ColProf = Lime;             
   if (ProfitBuy    <0)  ColBuy = LightPink   ; else ColBuy  = LightGreen; 
   if (ProfitSell   <0)  ColSell= LightPink   ; else ColSell = LightGreen; 
   if (ProfitOverlap>0)  ColBuf = DeepSkyBlue ; else ColBuf  = Chocolate; 
   
double       LotsTake = FreeMargin/MarketInfo(Symb, MODE_MARGINREQUIRED)                  ;  //количество лотов которое можно купить 
Indication ("Ilock"      ,3,10    ,10 , lock,FontSize,"Arial",ColorInd)         ;
Indication ("IPrice"  ,1,5 ,10 , StringConcatenate("",  DoubleToStr(MarketInfo(Symbol(), MODE_BID) , Digits  )), 26 ,"Verdana",DodgerBlue); 
Indication ("ISymboll" ,1,250 ,0 , Symbol(), 14 ,"Verdana",DodgerBlue);
Indication ("ILotTake"   ,0,xDist2,235, StringConcatenate("Можно купить: "                ,  DoubleToStr(LotsTake   ,dig) ," лот"),FontSize,"Arial",ColorInd  );
Indication ("ILot"       ,0,xDist2,220, StringConcatenate("Начальный лот: "               ,  DoubleToStr(Lot        ,dig)), FontSize,"Arial",ColorInd         );      
Indication ("IProfit"    ,0,xDist2,205, StringConcatenate("Тейк профит в валюте депо: "   ,  DoubleToStr(Profit     ,  2)), FontSize,"Arial",ColorInd         );  

if (ProfitOverlap!=0 && UseAccBuffer){
Indication ("IBuf"       ,0,xDist2,250, StringConcatenate("Накоплено в буфере: "          ,  DoubleToStr(ProfitOverlap,dig)), FontSize,"Arial",ColBuf         );
} else { ObjectDelete("IBuf"         ); ObjectDelete("ISumLotBuy"); }

if (totalbuy>0){
Indication ("ISumLotBuy" ,0,xDist2,190 , StringConcatenate("Суммарный объем Buy ордеров: " ,  DoubleToStr(SumLotBuy  ,dig)), FontSize,"Arial",ColorInd         );   
Indication ("IProfitBuy" ,0,xDist2,145 , StringConcatenate("Суммарный профит Buy: "        ,  DoubleToStr(ProfitBuy  ,  2)), FontSize,"Arial",ColBuy           );   
} else { ObjectDelete("IProfitBuy"   ); ObjectDelete("ISumLotBuy"); }
  
if (totalsell>0){
Indication ("ISumLotSell",0,xDist2,175 , StringConcatenate("Суммарный объем Sell ордеров: ",  DoubleToStr(SumLotSell ,dig)), FontSize,"Arial",ColorInd         ); 
Indication ("IProfitSell",0,xDist2,130 , StringConcatenate("Суммарный профит Sell: "       ,  DoubleToStr(ProfitSell ,  2)), FontSize,"Arial",ColSell          );  
} else { ObjectDelete("ISumLotSell"  ); ObjectDelete("IProfitSell"); }
    
if (totalbuy>0 && totalsell>0){
Indication ("ISumlot"    ,0,xDist2,160 , StringConcatenate("Разность объемов ордеров: "    ,  DoubleToStr(Sumlot     ,dig)), FontSize,"Arial",ColorInd         ); 
Indication ("ISumProfit" ,0,xDist2,115 , StringConcatenate("Суммарный профит: "            ,  DoubleToStr(SumProfit  ,  2)), FontSize,"Arial",ColProf          );    
} else { ObjectDelete("ISumlot"      ); ObjectDelete("ISumProfit"); }

   //-------------------------                                        
   
   if (totalbuy>MaxTrades || totalsell>MaxTrades) Integra="Ограничение числа колен"; else Integra=EXPERT_NAME;   
      Indication ("IIntegra",2,10,25,Integra,FontSize,"Arial",ColorInd);     
} 


//=========================================================================================================================================//
// Qimer . Отрисовка текста                                                                                                                //
//=========================================================================================================================================//

void DrawText(string DrT_name, string DrT_txt, double DrT_y, color DrT_col){  
   if (ObjectFind(DrT_name)<0) ObjectCreate(DrT_name,OBJ_TEXT,0,Time[WindowFirstVisibleBar()-WindowFirstVisibleBar()/5],DrT_y);
      else ObjectMove(DrT_name,0,Time[WindowFirstVisibleBar()-WindowFirstVisibleBar()/4],DrT_y);
   ObjectSetText(DrT_name,DrT_txt,10,"Arial",DrT_col);
}

//=========================================================================================================================================//
// Функция отрисовки и расчета CCI                                                                                                         //
//=========================================================================================================================================//
 
double PriceCCI(double pricCCI_Level, int pricCCI_CurrentCandle=0){      
double pricCCI_MovBuffer=0;
double pricCCI_Price=0, pricCCI_SummPrice=0, pricCCI_Abs=0, pricCCI_SummAbs=0;
double pricCCI_K = 0.015;
int pricCCI_j,pricCCI_i;
   for( pricCCI_i=Period_CCI-1; pricCCI_i>=0; pricCCI_i--){
      pricCCI_j=pricCCI_i+pricCCI_CurrentCandle;
         pricCCI_Price = (High[pricCCI_j]+Low[pricCCI_j]+Close[pricCCI_j])/3;
            pricCCI_MovBuffer = iMA(NULL,0,Period_CCI,0,MODE_SMA,PRICE_TYPICAL,pricCCI_CurrentCandle);
               pricCCI_Abs    = MathAbs(pricCCI_Price-pricCCI_MovBuffer);
      if(pricCCI_i>0){
         pricCCI_SummPrice += pricCCI_Price;
            pricCCI_SummAbs+= pricCCI_Abs;
      }
   }
   if(Info==true) {        
             CCI = (pricCCI_Price-pricCCI_MovBuffer)/((pricCCI_SummAbs+pricCCI_Abs)*pricCCI_K/Period_CCI);
Indication ("ICCI",2,10,45,StringConcatenate("CCI (",DoubleToStr(pricCCI_Level,0),",",Period_CCI,",",CCI_TimeFrame,") = ",DoubleToStr(CCI,0)),FontSize,"Arial",ColorInd);   
   }
      
double pricCCI_H = High[pricCCI_CurrentCandle];
double pricCCI_L =  Low[pricCCI_CurrentCandle];
pricCCI_i = Period_CCI;
   if(CCI>=0){
      CCI=pricCCI_Level;
         pricCCI_Price = -(pricCCI_H*pricCCI_i-pricCCI_L*pricCCI_i*pricCCI_i-pricCCI_H*pricCCI_i*pricCCI_i+pricCCI_L*pricCCI_i-CCI*pricCCI_H*pricCCI_K-CCI*pricCCI_L*pricCCI_K+3*pricCCI_SummPrice*pricCCI_i-
            CCI*3*pricCCI_K*pricCCI_SummPrice+CCI*pricCCI_H*pricCCI_K*pricCCI_i+CCI*pricCCI_L*pricCCI_K*pricCCI_i+CCI*3*pricCCI_K*pricCCI_SummAbs*pricCCI_i)/(pricCCI_i-pricCCI_i*pricCCI_i-CCI*pricCCI_K+CCI*pricCCI_K*pricCCI_i);
   }
      else{
      CCI=-pricCCI_Level;
         pricCCI_Price = -(pricCCI_H*pricCCI_i-pricCCI_L*pricCCI_i*pricCCI_i-pricCCI_H*pricCCI_i*pricCCI_i+pricCCI_L*pricCCI_i+CCI*pricCCI_H*pricCCI_K+CCI*pricCCI_L*pricCCI_K+3*pricCCI_SummPrice*pricCCI_i+
            CCI*3*pricCCI_K*pricCCI_SummPrice-CCI*pricCCI_H*pricCCI_K*pricCCI_i-CCI*pricCCI_L*pricCCI_K*pricCCI_i+CCI*3*pricCCI_K*pricCCI_SummAbs*pricCCI_i)/(pricCCI_i-pricCCI_i*pricCCI_i+CCI*pricCCI_K-CCI*pricCCI_K*pricCCI_i);
   }
if(ObjectFind("ILineCCI")!=-1) ObjectDelete("ILineCCI"    );
if(ObjectFind("ItxtCCI" )!=-1) ObjectDelete("ItxtCCI"     );
   if(pricCCI_Price>pricCCI_H){
      ObjectCreate("ILineCCI", OBJ_HLINE, 0, 0,pricCCI_Price      );
         ObjectSet("ILineCCI", OBJPROP_COLOR, SteelBlue   );
      DrawText("ItxtCCI",StringConcatenate("CCI < ", DoubleToStr(CCI,0)),pricCCI_Price,SteelBlue );
   }
      else ObjectCreate("ILineCCI", OBJ_HLINE, 0, 0,pricCCI_Price );
   if(pricCCI_Price<pricCCI_L){
      ObjectCreate("ILineCCI", OBJ_HLINE, 0, 0,pricCCI_Price      );
         ObjectSet   ("ILineCCI", OBJPROP_COLOR, Teal     ); 
      DrawText("ItxtCCI",StringConcatenate("CCI > ", DoubleToStr(CCI,0)),pricCCI_Price, Teal     );
   }
      else ObjectCreate("ILineCCI", OBJ_HLINE, 0, 0,pricCCI_Price );
return(pricCCI_Price);       
}


//=========================================================================================================================================//
// Kordan . Сигнал СCI                                                                                                                     //
//=========================================================================================================================================// 

int Signal_CCI(){     
datetime tm =0;
int signal_1=0;

// CCI Signals
      
      
  
      double c1=iCCI(NULL,1,Period_CCI,CCI_PRICE_TYPE,0); 
      double c5=iCCI(NULL,5,Period_CCI,CCI_PRICE_TYPE,0);        
      double c15=iCCI(NULL,15,Period_CCI,CCI_PRICE_TYPE,0);     
      double c30=iCCI(NULL,30,Period_CCI,CCI_PRICE_TYPE,0);  
      double cH1=iCCI(NULL,60,Period_CCI,CCI_PRICE_TYPE,0);  
      double cH4=iCCI(NULL,240,Period_CCI,CCI_PRICE_TYPE,0); 
      double cD =iCCI(NULL,1440,Period_CCI,CCI_PRICE_TYPE,0);
if (Info){     
      if (c1<=0&&c1>-Level){S1 = "-"; col1 = CL3;} 
      if (c1>0&&c1<Level){S1 = "-"; col1 = CL4;}
      if (c1<=-Level){S1 = "-"; col1 = CL1;} 
      if (c1>=Level){S1 = "-"; col1 = CL2;}  
      
      if (c5<=0&&c5>-Level){S5 = "-"; col5 = CL3;} 
      if (c5>0&&c5<Level){S5 = "-"; col5 = CL4;}
      if (c5<=-Level){S5 = "-"; col5 = CL1;} 
      if (c5>=Level){S5 = "-"; col5 = CL2;} 
      
      if (c15<=0&&c15>-Level){S15 = "-"; col15 = CL3;} 
      if (c15>0&&c15<Level){S15 = "-"; col15 = CL4;}
      if (c15<=-Level){S15 = "-"; col15 = CL1;} 
      if (c15>=Level){S15 = "-"; col15 = CL2;} 
          
      if (c30<=0&&c30>-Level){S30 = "-"; col30 = CL3;} 
      if (c30>0&&c30<Level){S30 = "-"; col30 = CL4;}
      if (c30<=-Level){S30 = "-"; col30 = CL1;} 
      if (c30>=Level){S30 = "-"; col30 = CL2;}  
           
      if (cH1<=0&&cH1>-Level){SH1 = "-"; colH1 = CL3;} 
      if (cH1>0&&cH1<Level){SH1 = "-"; colH1 = CL4;}
      if (cH1<=-Level){SH1 = "-"; colH1 = CL1;} 
      if (cH1>=Level){SH1 = "-"; colH1 = CL2;}  
         
      if (cH4<=0&&cH4>-Level){SH4 = "-"; colH4 = CL3;} 
      if (cH4>0&&cH4<Level){SH4 = "-"; colH4 = CL4;}
      if (cH4<=-Level){SH4 = "-"; colH4 = CL1;} 
      if (cH4>=Level){SH4 = "-"; colH4 = CL2;}    
      
      if (cD<=0&&cD>-Level){SD = "-"; colD = CL3;} 
      if (cD>0&&cD<Level){SD = "-"; colD = CL4;}
      if (cD<=-Level){SD = "-"; colD = CL1;} 
      if (cD>=Level){SD = "-"; colD = CL2;}
      
  
 
   Indication ("INumbers", 1, 15, 30+Shift_UP_DN, "M1 M5 M15 M30 H1  H4   D ", 6, "Arial", BarLabel_color);
   Indication ("ISSignal", 1, 120, 43+Shift_UP_DN, "CCI_0", 6, "Arial", BarLabel_color);
   //..................................................................

   Indication ("ICC1", 1, 100, 18+Shift_UP_DN, S1, 35, "Arial", col1);  
   Indication ("ICC5", 1, 85, 18+Shift_UP_DN, S5, 35, "Arial", col5);      
   Indication ("ICC15", 1, 70, 18+Shift_UP_DN, S15, 35, "Arial", col15);   
   Indication ("ICC30", 1, 55, 18+Shift_UP_DN, S30, 35, "Arial", col30);
   Indication ("ICCH1", 1, 40, 18+Shift_UP_DN, SH1, 35, "Arial", colH1);
   Indication ("ICCH4", 1, 25, 18+Shift_UP_DN, SH4, 35, "Arial", colH4);
   Indication ("ICCD", 1, 10, 18+Shift_UP_DN, SD, 35, "Arial", colD);
}   
   
///////////////////////////////////////////////////////////////
   
// CCI1 Signals

      
  
      double cc1=iCCI(NULL,1,Period_CCI,CCI_PRICE_TYPE,1); 
      double cc5=iCCI(NULL,5,Period_CCI,CCI_PRICE_TYPE,1);        
      double cc15=iCCI(NULL,15,Period_CCI,CCI_PRICE_TYPE,1);     
      double cc30=iCCI(NULL,30,Period_CCI,CCI_PRICE_TYPE,1);  
      double ccH1=iCCI(NULL,60,Period_CCI,CCI_PRICE_TYPE,1);  
      double ccH4=iCCI(NULL,240,Period_CCI,CCI_PRICE_TYPE,1); 
      double ccD=iCCI(NULL,1440,Period_CCI,CCI_PRICE_TYPE,1);
if (Info){      
      if (cc1<=0&&cc1>-Level){PS1 = "-"; Pcol1 = CL3;} 
      if (cc1>0&&cc1<Level){PS1 = "-"; Pcol1 = CL4;}
      if (cc1<=-Level){PS1 = "-"; Pcol1 = CL1;} 
      if (cc1>=Level){PS1 = "-"; Pcol1 = CL2;}  
      
      if (cc5<=0&&cc5>-Level){PS5 = "-"; Pcol5 = CL3;} 
      if (cc5>0&&cc5<Level){PS5 = "-"; Pcol5 = CL4;}
      if (cc5<=-Level){PS5 = "-"; Pcol5 = CL1;} 
      if (cc5>=Level){PS5 = "-"; Pcol5 = CL2;} 
      
      if (cc15<=0&&cc15>-Level){PS15 = "-"; Pcol15 = CL3;} 
      if (cc15>0&&cc15<Level){PS15 = "-"; Pcol15 = CL4;}
      if (cc15<=-Level){PS15 = "-"; Pcol15 = CL1;} 
      if (cc15>=Level){PS15 = "-"; Pcol15 = CL2;} 
          
      if (cc30<=0&&cc30>-Level){PS30 = "-"; Pcol30 = CL3;} 
      if (cc30>0&&cc30<Level){PS30 = "-"; Pcol30 = CL4;}
      if (cc30<=-Level){PS30 = "-"; Pcol30 = CL1;} 
      if (cc30>=Level){PS30 = "-"; Pcol30 = CL2;}  
           
      if (ccH1<=0&&ccH1>-Level){PSH1 = "-"; PcolH1 = CL3;} 
      if (ccH1>0&&ccH1<Level){PSH1 = "-"; PcolH1 = CL4;}
      if (ccH1<=-Level){PSH1 = "-"; PcolH1 = CL1;} 
      if (ccH1>=Level){PSH1 = "-"; PcolH1 = CL2;}  
         
      if (ccH4<=0&&ccH4>-Level){PSH4 = "-"; PcolH4 = CL3;} 
      if (ccH4>0&&ccH4<Level){PSH4 = "-"; PcolH4 = CL4;}
      if (ccH4<=-Level){PSH4 = "-"; PcolH4 = CL1;} 
      if (ccH4>=Level){PSH4 = "-"; PcolH4 = CL2;}    
      
      if (ccD<=0&&ccD>-Level){PSD = "-"; PcolD = CL3;} 
      if (ccD>0&&ccD<Level){PSD = "-"; PcolD = CL4;}
      if (ccD<=-Level){PSD = "-"; PcolD = CL1;} 
      if (ccD>=Level){PSD = "-"; PcolD = CL2;} 
  


   Indication ("ISSi", 1, 120, 55+Shift_UP_DN, "CCI_1", 6, "Arial", BarLabel_color);
   //..................................................................

   Indication ("IPC1", 1, 100, 30+Shift_UP_DN, PS1, 35, "Arial", Pcol1);  
   Indication ("IPC5", 1, 85, 30+Shift_UP_DN, PS5, 35, "Arial", Pcol5);      
   Indication ("IPC15", 1, 70, 30+Shift_UP_DN, PS15, 35, "Arial", Pcol15);   
   Indication ("IPC30", 1, 55, 30+Shift_UP_DN, PS30, 35, "Arial", Pcol30);
   Indication ("IPCH1", 1, 40, 30+Shift_UP_DN, PSH1, 35, "Arial", PcolH1);
   Indication ("IPCH4", 1, 25, 30+Shift_UP_DN, PSH4, 35, "Arial", PcolH4);
   Indication ("IPD1", 1, 10, 30+Shift_UP_DN, PSD, 35, "Arial", PcolD);  
}   
    
///////////////////////////////////////////////////////////////
   
// Trend
      
      double ccc1=iCCI(NULL,1,Period_CCI,CCI_PRICE_TYPE,5); 
      double ccc5=iCCI(NULL,5,Period_CCI,CCI_PRICE_TYPE,5);        
      double ccc15=iCCI(NULL,15,Period_CCI,CCI_PRICE_TYPE,5);     
      double ccc30=iCCI(NULL,30,Period_CCI,CCI_PRICE_TYPE,5);  
      double cccH1=iCCI(NULL,60,Period_CCI,CCI_PRICE_TYPE,5);  
      double cccH4=iCCI(NULL,240,Period_CCI,CCI_PRICE_TYPE,5); 
      double cccD=iCCI(NULL,1440,Period_CCI,CCI_PRICE_TYPE,5);
  
if (Info){
      

      if (ccc1<c1){TS1 = "-"; Tcol1 = CL1;} 
      if (ccc1>c1){TS1 = "-"; Tcol1 = CL2;}  
      

      if (ccc5<c5){TS5 = "-"; Tcol5 = CL1;} 
      if (ccc5>c5){TS5 = "-"; Tcol5 = CL2;} 
      

      if (ccc15<c15){TS15 = "-"; Tcol15 = CL1;} 
      if (ccc15>c15){TS15 = "-"; Tcol15 = CL2;} 
          

      if (ccc30<c30){TS30 = "-"; Tcol30 = CL1;} 
      if (ccc30>c30){TS30 = "-"; Tcol30 = CL2;}  
           

      if (cccH1<cH1){TSH1 = "-"; TcolH1 = CL1;} 
      if (cccH1>cH1){TSH1 = "-"; TcolH1 = CL2;}  
         

      if (cccH4<cH4){TSH4 = "-"; TcolH4 = CL1;} 
      if (cccH4>cH4){TSH4 = "-"; TcolH4 = CL2;}    
      

      if (cccD<cD){TSD = "-"; TcolD = CL1;} 
      if (cccD>cD){TSD = "-"; TcolD = CL2;} 
  

 
   Indication ("ITSi", 1, 120, 67+Shift_UP_DN, "Trend", 6, "Arial", BarLabel_color);
   //..................................................................

   Indication ("ITC1", 1, 100, 42+Shift_UP_DN, TS1, 35, "Arial", Tcol1);  
   Indication ("ITC5", 1, 85, 42+Shift_UP_DN, TS5, 35, "Arial", Tcol5);      
   Indication ("ITC15", 1, 70, 42+Shift_UP_DN, TS15, 35, "Arial", Tcol15);   
   Indication ("ITC30", 1, 55, 42+Shift_UP_DN, TS30, 35, "Arial", Tcol30);
   Indication ("ITCH1", 1, 40, 42+Shift_UP_DN, TSH1, 35, "Arial", TcolH1);
   Indication ("ITCH4", 1, 25, 42+Shift_UP_DN, TSH4, 35, "Arial", TcolH4);
   Indication ("ITD1", 1, 10, 42+Shift_UP_DN, TSD, 35, "Arial", TcolD); 
   Indication ("Iuc1", 1, 70, 82+Shift_UP_DN, "M1 = "+DoubleToStr(c1,0), 7, "Arial", col1);
   Indication ("Iuc5", 1, 70, 92+Shift_UP_DN, "M5 = "+DoubleToStr(c5,0), 7, "Arial", col5);
   Indication ("Iuc15", 1, 70, 102+Shift_UP_DN, "M15 = "+DoubleToStr(c15,0), 7, "Arial", col15);
   Indication ("Iuc30", 1, 70, 112+Shift_UP_DN, "M30 = "+DoubleToStr(c30,0), 7, "Arial", col30);
   Indication ("Iuh1", 1, 70, 122+Shift_UP_DN, "H1 = "+DoubleToStr(cH1,0), 7, "Arial", colH1);
   Indication ("Iuh4", 1, 70, 132+Shift_UP_DN, "H4 = "+DoubleToStr(cH4,0), 7, "Arial", colH4);
   Indication ("Iud", 1, 70, 142+Shift_UP_DN, "D1 = "+DoubleToStr(cD,0), 7, "Arial", colD);
   Indication ("Ipuc1", 1, 10, 82+Shift_UP_DN, "1M1 = "+DoubleToStr(cc1,0), 7, "Arial", Pcol1);
   Indication ("Ipuc5", 1, 10, 92+Shift_UP_DN, "1M5 = "+DoubleToStr(cc5,0), 7, "Arial", Pcol5);
   Indication ("Ipuc15", 1, 10, 102+Shift_UP_DN, "1M15 = "+DoubleToStr(cc15,0), 7, "Arial", Pcol15);
   Indication ("Ipuc30", 1, 10, 112+Shift_UP_DN, "1M30 = "+DoubleToStr(cc30,0), 7, "Arial", Pcol30);
   Indication ("Ipuh1", 1, 10, 122+Shift_UP_DN, "1H1 = "+DoubleToStr(ccH1,0), 7, "Arial", PcolH1);
   Indication ("Ipuh4", 1, 10, 132+Shift_UP_DN, "1H4 = "+DoubleToStr(ccH4,0), 7, "Arial", PcolH4);
   Indication ("Ipud", 1, 10, 142+Shift_UP_DN, "1D1 = "+DoubleToStr(ccD,0), 7, "Arial", PcolD);
}   
   
   string SPREAD="",SIG="Нет  сигнала";
   //----------------------------------------------------------- color color_pip,color_av;

   double SPRD = (Ask - Bid)/Point;
   color col_1=Gold;
   SPREAD = (DoubleToStr(SPRD,Digits-5));
   if(c1<Level&&c5<Level&&c15<Level&&c30<-Level&&cH1<Level&&cH4<Level)
//   if(c1>-Level&&c5>-Level&&c15>-Level&&c30>-Level&&cH1>-Level&&cH4>-Level)
   
   {

   SIG="Ожидаем  Sell";
   col_1=Red;
   }
   
   if(c1>-Level&&c5>-Level&&c15>-Level&&cH1>-Level&&cH4>-Level)
//   if(c1<Level&&c5<Level&&c15<Level&&c30<Level&&cH1<Level&&cH4<Level)   
   
   {
  
   SIG="Ожидаем  Buy";
   col_1=Lime;
   }
   
   if(((cc1<Level&&c1<Level&&cc1<c1)||SignTF1==0)
       &&((cc5<Level&&c5<Level&&cc5<c5)||SignTF5==0)
       &&((cc15<Level&&c15<Level&&cc15<c15)||SignTF15==0)
       &&((cc30<Level&&c30<Level&&cc30<c30)||SignTF30==0)
       &&((ccH1<Level&&cH1<Level&&ccH1<cH1)||SignTFH1==0)
       &&((ccH4<Level&&cH4<Level&&ccH4<cH4)||SignTFH4==0))
       
    if(((ccc1<c1)||SignTF1==0)
       &&((ccc5<c5)||SignTF5==0)
       &&((ccc15<c15)||SignTF15==0)
       &&((ccc30<c30)||SignTF30==0)
       &&((cccH1<cH1)||SignTFH1==0)
       &&((cccH4<cH4)||SignTFH4==0))
       
//   if(((cc1>-Level&&c1>-Level&&cc1>c1)||SignTF1==0)
//       &&((cc5>-Level&&c5>-Level&&cc5>c5)||SignTF5==0)
//       &&((cc15>-Level&&c15>-Level&&cc15>c15)||SignTF15==0)
//       &&((cc30>-Level&&c30>-Level&&cc30>c30)||SignTF30==0)
//       &&((ccH1>-Level&&cH1>-Level&&ccH1>cH1)||SignTFH1==0)
//       &&((ccH4>-Level&&cH4>-Level&&ccH4>cH4)||SignTFH4==0)
       
//    if(((ccc1>c1)||SignTF1==0)
//       &&((ccc5>c5)||SignTF5==0)
//       &&((ccc15>c15)||SignTF15==0)
//       &&((ccc30>c30)||SignTF30==0)
//       &&((cccH1>cH1)||SignTFH1==0)
//       &&((cccH4>cH4)||SignTFH4==0))  
                            
   {

   SIG="Сигнал  SELL";
   col_1=Red;
   signal_1 = -1;
   }
   
   if(((cc1>-Level&&c1>-Level&&cc1>c1)||SignTF1==0)
       &&((cc5>-Level&&c5>-Level&&cc5>c5)||SignTF5==0)
       &&((cc15>-Level&&c15>-Level&&cc15>c15)||SignTF15==0)
       &&((cc30>-Level&&c30>-Level&&cc30>c30)||SignTF30==0)
       &&((ccH1>-Level&&cH1>-Level&&ccH1>cH1)||SignTFH1==0)
       &&((ccH4>-Level&&cH4>-Level&&ccH4>cH4)||SignTFH4==0))
       
    if(((ccc1>c1)||SignTF1==0)
       &&((ccc5>c5)||SignTF5==0)
       &&((ccc15>c15)||SignTF15==0)
       &&((ccc30>c30)||SignTF30==0)
       &&((cccH1>cH1)||SignTFH1==0)
       &&((cccH4>cH4)||SignTFH4==0))
       
//   if(((cc1<Level&&c1<Level&&cc1<c1)||SignTF1==0)
//       &&((cc5<Level&&c5<Level&&cc5<c5)||SignTF5==0)
//       &&((cc15<Level&&c15<Level&&cc15<c15)||SignTF15==0)
//       &&((cc30<Level&&c30<Level&&cc30<c30)||SignTF30==0)
//       &&((ccH1<Level&&cH1<Level&&ccH1<cH1)||SignTFH1==0)
//       &&((ccH4<Level&&cH4<Level&&ccH4<cH4)||SignTFH4==0))
       
//    if(((ccc1<c1)||SignTF1==0)
//       &&((ccc5<c5)||SignTF5==0)
//       &&((ccc15<c15)||SignTF15==0)
//       &&((ccc30<c30)||SignTF30==0)
//       &&((cccH1<cH1)||SignTFH1==0)
//       &&((cccH4<cH4)||SignTFH4==0))
        
   {

   SIG="Сигнал  BUY";
   col_1=Lime;
   signal_1 = 1;
   } 
if (Info){   
   if(signal_1!=0&&tm==0&&TIME_SOUND>0)
   {
  // PlaySound("news.wav");
   tm=TimeCurrent();
   }
   if(TimeCurrent()>tm+TIME_SOUND) tm=0;
   Indication ("IMMLEVELS7", 1, 70, 157+Shift_UP_DN, "Spread", 10, "Arial", CommentLabel_color);
   Indication ("IMMLEVELS8", 1, 10, 157+Shift_UP_DN, ""+SPREAD+"", 10, "Arial Bold", Gold);
   Indication ("ISIGNAL", 1, 10, 177+Shift_UP_DN, ""+SIG+"", 10, "Arial Bold", col_1);   
}
 //----
   return(signal_1);
}


//=========================================================================================================================================//
// Kordan . Функция расчета лота для открытия колен                                                                                        //
//=========================================================================================================================================//

double NewLot(int NewLotOrdType){      
double cp                                                                 ;
   switch(NewLotOrdType){
      case OP_BUY :
         if (!fixlot) cp = MathAbs((LastPriceBuy-Ask )/Point/PipstepBuy); else cp=1 ;   
            newlot_1 = NormalizeDouble(LastLotBuy*LotExponentBuy*cp,dig  ); break     ;
      case OP_SELL :
         if (!fixlot) cp = MathAbs((Bid-LastPriceSell)/Point/PipstepSell); else cp=1 ;    
            newlot_1 = NormalizeDouble(LastLotSell*LotExponentSell*cp,dig ); break     ;
   }  
   if (MaxLot ==0     ) newlot_1 = newlot_1; else 
   if (newlot_1 > MaxLot) newlot_1 = NormalizeDouble(MaxLot,dig)                     ;   
   if (newlot_1 < minLot) newlot_1 = minLot                                          ;          
return(newlot_1)                                                                   ;
} 


//=========================================================================================================================================//
// shvonder . Фильтр уровней по МА S                                                                                                       //
//=========================================================================================================================================//  

int GetMASignalS(){        
   if (TipMAFilter==1){
   MAS_signal = 0;
double iMA_Signal = iMA(Symb, PERIOD_H1, Period_МА, 0, MODE_SMMA, PRICE_CLOSE, 1);
double Ma_Bid_Diff = MathAbs(iMA_Signal - Bid)/Point;
   if(Ma_Bid_Diff > Distance_МА && Bid > iMA_Signal) MAS_signal = -1; //Sell
   if(Ma_Bid_Diff > Distance_МА && Bid < iMA_Signal) MAS_signal =  1; //Buy   
double LevelNoBuy =iMA_Signal-Distance_МА*Point;
double LevelNoSell=iMA_Signal+Distance_МА*Point; 
      if (IsVisualMode() || !IsOptimization()){
         DrawLine("ILevelNoBuy  ", LevelNoBuy  , RoyalBlue, 3); 
         DrawLine("ILevelNoSell ", LevelNoSell , Crimson  , 3);  
         DrawText("ItxtLevelBuy ","Filter shvonder - запрет Buy" , LevelNoBuy , RoyalBlue);
         DrawText("ItxtLevelSell","Filter shvonder - запрет Sell", LevelNoSell, Crimson  );
      }
   }
return(MAS_signal);    
}

//=========================================================================================================================================//
// Kordan . Фильтр уровней по МА K                                                                                                         //
//=========================================================================================================================================//  

int    GetMASignalK(){   
   if (TipMAFilter==2){
    MAK_signal = 0;
double iMA_Signal  = iMA(Symb, PERIOD_H1, Period_МА, 0, MODE_SMMA, PRICE_CLOSE, 1);
double    Ma_Bid_Diff = MathAbs(iMA_Signal - Bid)/Point;
double LevelNoBuy =iMA_Signal+Distance_МА*Point;
double LevelNoSell=iMA_Signal-Distance_МА*Point;
      if(Ma_Bid_Diff > Distance_МА){ 
         if(Bid > iMA_Signal) MAK_signal = 1; //Запрет Buy
         if(Bid < iMA_Signal) MAK_signal =-1; //Запрет Sell  
      }   
      if (IsVisualMode() || !IsOptimization()){
         DrawLine("ILevelNoBuy  ", LevelNoBuy  , RoyalBlue, 3); 
         DrawLine("ILevelNoSell ", LevelNoSell , Crimson  , 3);
         DrawText("ItxtLevelBuy ","Filter Kordan - запрет Buy" , LevelNoBuy , RoyalBlue);  
         DrawText("ItxtLevelSell","Filter Kordan - запрет Sell", LevelNoSell, Crimson  ); 
      }  
   } 
return(MAK_signal);                     
}


//=========================================================================================================================================//
// shvonder + Kordan . Функция управления закрытием перекрытых ордеров                                                                     //
//=========================================================================================================================================//

void CloseSelectOrder(int tipii){
if (Info) Print("<<<<< Перекрываем ордера <<<<<");
int i;
bool error  = false;
bool error1 = false;
bool error2 = false;    
if (OrderSymbol() == Symb && (OrderMagicNumber()==MagicNumber || MagicCheck())){   
 
//                       ---------------------- последний  -----------------------  
switch(tipii){
   case OP_BUY :
      i = OrderSelect(Lpos, SELECT_BY_TICKET, MODE_TRADES);
         if (i != 1){Print ("Ошибка! Невозможно выбрать ордер с наибольшим профитом. Выполнение перекрытия отменено."); return ;}
            error1 = CloseOrders(Lpos,OP_BUY); break;
   case OP_SELL:
      i = OrderSelect(Lpos, SELECT_BY_TICKET, MODE_TRADES);
         if (i != 1){Print ("Ошибка! Невозможно выбрать ордер с наибольшим профитом. Выполнение перекрытия отменено."); return ;}
            error1 = CloseOrders(Lpos,OP_SELL); break;
} 
   if (error1 != 1) {if (Info) Print ("Ошибка закрытия лидирующего ордера, повторяем операцию.");} 
      else {if (Info && (!IsTesting() || !IsOptimization())) Print ("Лидирующий ордер закрыт успешно."); Sleep (60);}    
                                               
//                       ---------------------- пред последний  -----------------------      
if(Lpos1 != 0){
   switch(tipii){
      case OP_BUY :
         i = OrderSelect(Lpos1, SELECT_BY_TICKET, MODE_TRADES);
            if (i != 1){Print ("Ошибка! Невозможно выбрать Пред Лидирующий ордер с наибольшим профитом. Выполнение перекрытия отменено." ); return ;}
               error2 = CloseOrders(Lpos1,OP_BUY); break;
      case OP_SELL:
         i = OrderSelect(Lpos1, SELECT_BY_TICKET, MODE_TRADES);
            if (i != 1){Print ("Ошибка! Невозможно выбрать Пред Лидирующий ордер с наибольшим профитом. Выполнение перекрытия отменено." ); return ;}
               error2 = CloseOrders(Lpos1,OP_SELL); break;
   }           
   if (error2 != 1) {if (Info) Print ("Ошибка закрытия Пред лидирующего ордера, повторяем операцию.");} 
      else {if (Info &&( !IsTesting() || !IsOptimization())) Print ("Пред Лидирующий ордер закрыт успешно."); Sleep (60);}    
} 

//                      ----------- выбранный (обычно с наименьшим профитом ) -----------
switch(tipii){
   case OP_BUY :
      i = OrderSelect(Cpos, SELECT_BY_TICKET, MODE_TRADES);
         if (i != 1){Print ("Ошибка! Невозможно выбрать ордер с наименьшим профитом. Выполнение перекрытия отменено."); return ;}
            error = CloseOrders(Cpos,OP_BUY); break;
   case OP_SELL:
      i = OrderSelect(Lpos, SELECT_BY_TICKET, MODE_TRADES);
         if (i != 1){Print ("Ошибка! Невозможно выбрать ордер с наименьшим профитом. Выполнение перекрытия отменено."); return ;}
            error = CloseOrders(Cpos,OP_SELL); break;
}
   if (error != 1) if (Info) Print ("Ошибка закрытия перекрываемого ордера, повторяем операцию."); 
      else {if (Info && (!IsTesting() || !IsOptimization())) Print ("Перекрываемый ордер закрыт успешно."); Sleep (60);}          
}                     
	return;             
}


//+--------------------------------------------------------------------------------------------------------------+
//| ErrorDescription. Возвращает описание ошибки по её номеру.
//+--------------------------------------------------------------------------------------------------------------+

string ErrorDescription(int Er_De_error) {
//+--------------------------------------------------------------------------------------------------------------+

   string ErrorNumber;
   //---
   switch (Er_De_error) {
   case 0:
   case 1:     ErrorNumber = "Нет ошибки, но результат неизвестен";                        break;
   case 2:     ErrorNumber = "Общая ошибка";                                               break;
   case 3:     ErrorNumber = "Неправильные параметры";                                     break;
   case 4:     ErrorNumber = "Торговый сервер занят";                                      break;
   case 5:     ErrorNumber = "Старая версия клиентского терминала";                        break;
   case 6:     ErrorNumber = "Нет связи с торговым сервером";                              break;
   case 7:     ErrorNumber = "Недостаточно прав";                                          break;
   case 8:     ErrorNumber = "Слишком частые запросы";                                     break;
   case 9:     ErrorNumber = "Недопустимая операция нарушающая функционирование сервера";  break;
   case 64:    ErrorNumber = "Счет заблокирован";                                          break;
   case 65:    ErrorNumber = "Неправильный номер счета";                                   break;
   case 128:   ErrorNumber = "Истек срок ожидания совершения сделки";                      break;
   case 129:   ErrorNumber = "Неправильная цена";                                          break;
   case 130:   ErrorNumber = "Неправильные стопы";                                         break;
   case 131:   ErrorNumber = "Неправильный объем";                                         break;
   case 132:   ErrorNumber = "Рынок закрыт";                                               break;
   case 133:   ErrorNumber = "Торговля запрещена";                                         break;
   case 134:   ErrorNumber = "Недостаточно денег для совершения операции";                 break;
   case 135:   ErrorNumber = "Цена изменилась";                                            break;
   case 136:   ErrorNumber = "Нет цен";                                                    break;
   case 137:   ErrorNumber = "Брокер занят";                                               break;
   case 138:   ErrorNumber = "Новые цены - Реквот";                                        break;
   case 139:   ErrorNumber = "Ордер заблокирован и уже обрабатывается";                    break;
   case 140:   ErrorNumber = "Разрешена только покупка";                                   break;
   case 141:   ErrorNumber = "Слишком много запросов";                                     break;
   case 145:   ErrorNumber = "Модификация запрещена, так как ордер слишком близок к рынку";break;
   case 146:   ErrorNumber = "Подсистема торговли занята";                                 break;
   case 147:   ErrorNumber = "Использование даты истечения ордера запрещено брокером";     break;
   case 148:   ErrorNumber = "Количество открытых и отложенных ордеров достигло предела "; break;
   //---- 
   case 4000:  ErrorNumber = "Нет ошибки";                                                 break;
   case 4001:  ErrorNumber = "Неправильный указатель функции";                             break;
   case 4002:  ErrorNumber = "Индекс массива - вне диапазона";                             break;
   case 4003:  ErrorNumber = "Нет памяти для стека функций";                               break;
   case 4004:  ErrorNumber = "Переполнение стека после рекурсивного вызова";               break;
   case 4005:  ErrorNumber = "На стеке нет памяти для передачи параметров";                break;
   case 4006:  ErrorNumber = "Нет памяти для строкового параметра";                        break;
   case 4007:  ErrorNumber = "Нет памяти для временной строки";                            break;
   case 4008:  ErrorNumber = "Неинициализированная строка";                                break;
   case 4009:  ErrorNumber = "Неинициализированная строка в массиве";                      break;
   case 4010:  ErrorNumber = "Нет памяти для строкового массива";                          break;
   case 4011:  ErrorNumber = "Слишком длинная строка";                                     break;
   case 4012:  ErrorNumber = "Остаток от деления на ноль";                                 break;
   case 4013:  ErrorNumber = "Деление на ноль";                                            break;
   case 4014:  ErrorNumber = "Неизвестная команда";                                        break;
   case 4015:  ErrorNumber = "Неправильный переход";                                       break;
   case 4016:  ErrorNumber = "Неинициализированный массив";                                break;
   case 4017:  ErrorNumber = "Вызовы DLL не разрешены";                                    break;
   case 4018:  ErrorNumber = "Невозможно загрузить библиотеку";                            break;
   case 4019:  ErrorNumber = "Невозможно вызвать функцию";                                 break;
   case 4020:  ErrorNumber = "Вызовы внешних библиотечных функций не разрешены";           break;
   case 4021:  ErrorNumber = "Недостаточно памяти для строки, возвращаемой из функции";    break;
   case 4022:  ErrorNumber = "Система занята";                                             break;
   case 4050:  ErrorNumber = "Неправильное количество параметров функции";                 break;
   case 4051:  ErrorNumber = "Недопустимое значение параметра функции";                    break;
   case 4052:  ErrorNumber = "Внутренняя ошибка строковой функции";                        break;
   case 4053:  ErrorNumber = "Ошибка массива";                                             break;
   case 4054:  ErrorNumber = "Неправильное использование массива-таймсерии";               break;
   case 4055:  ErrorNumber = "Ошибка пользовательского индикатора";                        break;
   case 4056:  ErrorNumber = "Массивы несовместимы";                                       break;
   case 4057:  ErrorNumber = "Ошибка обработки глобальныех переменных";                    break;
   case 4058:  ErrorNumber = "Глобальная переменная не обнаружена";                        break;
   case 4059:  ErrorNumber = "Функция не разрешена в тестовом режиме";                     break;
   case 4060:  ErrorNumber = "Функция не подтверждена";                                    break;
   case 4061:  ErrorNumber = "Ошибка отправки почты";                                      break;
   case 4062:  ErrorNumber = "Ожидается параметр типа string";                             break;
   case 4063:  ErrorNumber = "Ожидается параметр типа integer";                            break;
   case 4064:  ErrorNumber = "Ожидается параметр типа double";                             break;
   case 4065:  ErrorNumber = "В качестве параметра ожидается массив";                      break;
   case 4066:  ErrorNumber = "Запрошенные исторические данные в состоянии обновления";     break;
   case 4067:  ErrorNumber = "Ошибка при выполнении торговой операции";                    break;
   case 4099:  ErrorNumber = "Конец файла";                                                break;
   case 4100:  ErrorNumber = "Ошибка при работе с файлом";                                 break;
   case 4101:  ErrorNumber = "Неправильное имя файла";                                     break;
   case 4102:  ErrorNumber = "Слишком много открытых файлов";                              break;
   case 4103:  ErrorNumber = "Невозможно открыть файл";                                    break;
   case 4104:  ErrorNumber = "Несовместимый режим доступа к файлу";                        break;
   case 4105:  ErrorNumber = "Ни один ордер не выбран";                                    break;
   case 4106:  ErrorNumber = "Неизвестный символ";                                         break;
   case 4107:  ErrorNumber = "Неправильный параметр цены для торговой функции";            break;
   case 4108:  ErrorNumber = "Неверный номер тикета";                                      break;
   case 4109:  ErrorNumber = "Торговля не разрешена";                                      break;
   case 4110:  ErrorNumber = "Длинные позиции не разрешены";                               break;
   case 4111:  ErrorNumber = "Короткие позиции не разрешены";                              break;
   case 4200:  ErrorNumber = "Объект уже существует";                                      break;
   case 4201:  ErrorNumber = "Запрошено неизвестное свойство объекта";                     break;
   case 4202:  ErrorNumber = "Объект не существует";                                       break;
   case 4203:  ErrorNumber = "Неизвестный тип объекта";                                    break;
   case 4204:  ErrorNumber = "Нет имени объекта";                                          break;
   case 4205:  ErrorNumber = "Ошибка координат объекта";                                   break;
   case 4206:  ErrorNumber = "Не найдено указанное подокно";                               break;
   case 4207:  ErrorNumber = "Ошибка при работе с объектом";                               break;
   default:    ErrorNumber = "Неизвестная ошибка";
   }
   //---
   return (ErrorNumber);
}

//INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA=INTEGRA