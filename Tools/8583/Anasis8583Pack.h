#ifndef ANASIS8583PACK
#define ANASIS8583PACK
#import <Cocoa/Cocoa.h>

typedef unsigned long  u32;
typedef unsigned short u16;
typedef unsigned char  u8;

typedef signed long  s32;
typedef signed short s16;
typedef signed char  s8;

extern u8 gRecvBuffer[500];
extern u8 gRecvStep;
extern u8 gTPDU[5];
extern u8 gAppType[1];
extern u8 gTerminalStatusReq[1];
extern u8 gBmp[8];
extern u8 gMsgType[2];
extern u8 gPriAccount[20];
extern u16 gPriAccountLen;
extern u8 gTransacCode[3];
extern u8 gTransacAmount[6];
extern u8 gSysTraceAudit[3];
extern u8 gLocalTime[3];
extern u8 gLocalDate[2];
extern u8 gValidity[2];
extern u8 gSettleDate[2];
extern u8 gSerEntryMode[2];
extern u8 gCardSequence[2];
extern u8 gSerCondition[1];
extern u8 gPinCapMode[1];
extern u8 *gAcqIdenCode;
extern u16 gAcqIdenCodeLen;
extern u8 gTrack2[100];
extern u16 gTrack2Len;
extern u8 gTrack3[100];
extern u16 gTrack3Len;
extern u8 gRetrieval[12];
extern u8 gAuthIdentiRespon[6];
extern u8 gResponCode[2];
extern u8 gTerminalCode[8];
extern u8 gMerchantCode[15];
extern u8 *gAdditionRespon;
extern u16 gAdditionResponLen;
extern u8 *gAdditionPrivate;
extern u16 gAdditionPrivateLen;
extern u8 gCurrencyCode[3];
extern u8 gPinData[8];
extern u8 gSecurityInfo[8];
extern u8 *gBalanceAmount;
extern u16 gBalanceAmountLen;
extern u8 *gICData;
extern u16 gICDataLen;
extern u8 *gPBOCData;
extern u16 gPBOCDataLen;
extern u8 *gOtherTermParam;
extern u16 gOtherTermParamLen;
extern u8 *gUserArea59;
extern u16 gUserArea59Len;
extern u8 gUserArea60[20];
extern u16 gUserArea60Len;
extern u8 *gOrgMsg;
extern u16 gOrgMsgLen;
extern u8 *gUserArea62;
extern u16 gUserArea62Len;
extern u8 *gUserArea63;
extern u16 gUserArea63Len;
extern u8 gMac[8];


extern NSMutableString *output;



extern int BreakupRecvPack(unsigned char recvchar);
extern void ClearRecvFlag(void);

extern int BCDToInt(u8 *dataIn, u8 InDataLen);
extern int HexToStr(unsigned char*hex, unsigned char*str, int hexlen);
int getBankCardNo(char str[22]);
#endif