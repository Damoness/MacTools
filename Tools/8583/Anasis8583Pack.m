#include <stdarg.h>
#include "Anasis8583Pack.h"

//char gSaveBuf[1000];
//FILE *gFile = NULL;

u8 gRecvBuffer[500];
u8 gRecvStep = 0;
u8 gTPDU[5];
u8 gAppType[1];
u8 gTerminalStatusReq[1];
u8 gBmp[8];
u8 gMsgType[2];
u8 gPriAccount[20]; //卡号
u16 gPriAccountLen;
u8 gTransacCode[3];
u8 gTransacAmount[6];   //交易金额
u8 gSysTraceAudit[3];      //凭证号
u8 gLocalTime[3];  //时间
u8 gLocalDate[2]; //日期
u8 gValidity[2];
u8 gSettleDate[2];
u8 gSerEntryMode[2];
u8 gCardSequence[2];
u8 gSerCondition[1];
u8 gPinCapMode[1];
u8 *gAcqIdenCode = gRecvBuffer;
u16 gAcqIdenCodeLen;
u8 gTrack2[100];
u16 gTrack2Len;
u8 gTrack3[100];
u16 gTrack3Len;
u8 gRetrieval[12];   //参考号
u8 gAuthIdentiRespon[6];
u8 gResponCode[2];
u8 gTerminalCode[8]; //终端号
u8 gMerchantCode[15]; //商户号
u8 *gAdditionRespon = gRecvBuffer;
u16 gAdditionResponLen;
u8 *gAdditionPrivate = gRecvBuffer;
u16 gAdditionPrivateLen;
u8 gCurrencyCode[3];
u8 gPinData[8];
u8 gSecurityInfo[8];
u8 *gBalanceAmount = gRecvBuffer;
u16 gBalanceAmountLen;
u8 *gICData = gRecvBuffer;
u16 gICDataLen;
u8 *gPBOCData = gRecvBuffer;
u16 gPBOCDataLen;
u8 *gOtherTermParam = gRecvBuffer;
u16 gOtherTermParamLen;
u8 *gUserArea59 = gRecvBuffer;
u16 gUserArea59Len;
u8 gUserArea60[20];  //批次号
u16 gUserArea60Len;
u8 *gOrgMsg = gRecvBuffer;
u16 gOrgMsgLen;
u8 *gUserArea62 = gRecvBuffer;
u16 gUserArea62Len;
u8 *gUserArea63 = gRecvBuffer;
u16 gUserArea63Len;
u8 gMac[8];
NSMutableString *output ;

//CString gShowEdit;

void my_printf(char *fmt,...)
{
	//printf(fmt);

	int length = 0;
	va_list ap;
	char string[1024];
	char *pt;
	va_start(ap,fmt);
	vsprintf((char *)string,(const char *)fmt,ap);
	pt = &string[0];
	while(*pt!='\0') 
	{
		length++;
		pt++;
	}
	//printf((char*)string);
	//fwrite(string, 1, length, gFile);
	va_end(ap);
	//gShowEdit += CString(string);
}


void PrintFormat(char*buf, int len)
{
	int i = 0;

	for(i = 0; i < len; i++)
	{
		my_printf("%.2X ", (unsigned char)buf[i]);
	}
	my_printf("\r\n");
}

void ClearBitmap(void)
{
	memset(gBmp, 0x00, sizeof(gBmp));
}

void SetBitmap(u8 area)
{
	if(area < 1 || area > 64)
	{
		return;
	}

	area--;
	gBmp[area / 8] |=  (0x80 >> ( area % 8));
}

void ResetBitmap(u8 area)
{
	if(area < 1 || area > 64)
	{
		return;
	}

	area--;
	gBmp[area / 8] &=  (~(0x80 >> ( area % 8)));
}

void IntToBCD(int dataIn, u8 *dataOut, u8 outDataLen)
{
	s8 Len = (s8)outDataLen;

	memset(dataOut, 0x00, outDataLen);

	Len--;
	for(; Len >= 0 && dataIn; Len--)
	{
		dataOut[Len] = (u8)(dataIn % 10);
		dataIn = dataIn / 10;
		dataOut[Len] &= 0x0F;
		dataOut[Len] |= ((u8)(dataIn % 10) << 4);
		dataIn = dataIn / 10;
	}
}

u8 GetNextBmpArea(u8 index)
{
	while(index < 64)
	{
		if((gBmp[index / 8] << ( index % 8)) & 0x80)
		{
			return index + 1;
		}
		index++;
	}

	return 0;
}

void ClearRecvFlag(void)
{
	gRecvStep = 0xFF;
	//gShowEdit = "";
    gPriAccountLen = 0;
    gAcqIdenCodeLen = 0;
    gTrack2Len = 0;
    gTrack3Len = 0;
    gAdditionResponLen = 0;
    gBalanceAmountLen = 0;
    gICDataLen = 0;
    gPBOCDataLen = 0;
    gOtherTermParamLen = 0;
    gUserArea59Len = 0;
    gUserArea60Len = 0;
    gOrgMsgLen = 0;
    gUserArea62Len = 0;
    gUserArea63Len = 0;
    output = [NSMutableString string];
}

int BCDToInt(u8 *dataIn, u8 InDataLen)
{
	int outlen;
	u8 i;

	outlen = 0;
	for(i = 0; i < InDataLen; i++)
	{
		outlen = outlen * 10 + ((dataIn[i] >> 4) & 0x0F);
		outlen = outlen * 10 + (dataIn[i] & 0x0F);
	}

	return outlen;
}

void AddStr(unsigned char*buf, int len){
    
    for(int i = 0; i < len; i++)
    {
        [output appendFormat:@"%.2X ",buf[i]];
    }
    
    [output appendString:@"\n"];
}

int HexToStr(unsigned char*hex, unsigned char*str, int hexlen)
{
    int i;
    unsigned char tmp;
    
    for(i = 0; i < hexlen; i++)
    {
        tmp = (i % 2 == 0)? (hex[i / 2] >> 4) : hex[i / 2];
        tmp = tmp & 0x0F;
        str[i] = tmp > 0x09 ? (tmp - 0x0A + 'A') : (tmp + '0');
    }
    str[i] = 0x00;
    
    return hexlen;
}

int BreakupRecvPack(u8 recvchar)
{
	static int recvindex = 0;
	static s8 recvlenmark = 0;
	static char lenbuf[10];//≥§∂»ª∫¥Ê
//    printf("______0x%x step=%x\n",recvchar,gRecvStep);
	if(gRecvStep == 0xFF)
	{
		recvindex = 0;
		recvlenmark = 0;
		gRecvStep = 0;
	}
	switch(gRecvStep)
	{
	case 0: //TPDU
		if(recvindex == 0 && recvchar != 0x60)
		{
			recvindex = 0;
			gRecvStep = 0;
			return -1;
		}
		gTPDU[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gTPDU))
		{
			recvindex = 0;
			gRecvStep++;
			my_printf("TPDU：");
			PrintFormat((char*)gTPDU, sizeof(gTPDU));
            
            [output appendString:@"TPDU："];
            AddStr((unsigned char*)gTPDU, sizeof(gTPDU));
            
		}
		break;
	case 1: // 60
		gAppType[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gAppType))
		{
			recvindex = 0;
			my_printf("报文头:");
			my_printf("%.2X ", gAppType[0]);
            
            [output appendString:@"报文头："];
            [output appendFormat:@"%.2X ", gAppType[0]];
            
            
			gRecvStep++;
		}
		break;
	case 2: // 22
		if(recvchar != 0x22)
		{
			//
		}
		recvindex = 0;
		gRecvStep++;
		my_printf("%.2X ", recvchar);
        [output appendFormat:@"%.2X ", recvchar];
		break;
	case 3: // 00
		gTerminalStatusReq[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gTerminalStatusReq))
		{
			recvindex = 0;
			my_printf("%.2X ", gTerminalStatusReq[0]);
            [output appendFormat:@"%.2X ", gTerminalStatusReq[0]];
			gRecvStep++;
		}
		break;
	case 4: // 00 00 00
		recvindex++;
		my_printf("%.2X ", recvchar);
        [output appendFormat:@"%.2X ", recvchar];
		if(recvindex >= 3)
		{
			recvindex = 0;
			gRecvStep++;
			my_printf("\r\n");
            [output appendFormat:@"\n"];
		}
		break;
	case 5: //消息类型：
            //08 10 签到
		gMsgType[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gMsgType))
		{
			my_printf("消息类型：");
			PrintFormat((char*)gMsgType, recvindex);
            [output appendString:@"消息类型："];
            AddStr((unsigned char*)gMsgType, recvindex);
			recvindex = 0;
			gRecvStep++;
		}
		break;
	case 6: //位图：
		gBmp[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gBmp))
		{
			recvindex = 0;
			gRecvStep++;
			gRecvStep = GetNextBmpArea(0) + 7;
			recvlenmark = 0;
			my_printf("位图：");
			PrintFormat((char*)gBmp, sizeof(gBmp));
            [output appendString:@"位图："];
            AddStr((unsigned char*)gBmp, sizeof(gBmp));
			return 1;
		}
		break;
	default:
		break;
	}

	if(gRecvStep <= 6)
	{
		return 1;
	}

	switch(gRecvStep - 7)
	{
	case 1:
		// ¿©’π”Ú£¨128∏ˆ”Ú£¨≤ª÷ß≥÷
		recvindex = 0;
		gRecvStep = 0;
		return -1;
		break;
	case 2:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 1)
			{
				recvindex = 0;
				recvlenmark = 1;
				gPriAccountLen = BCDToInt((u8*)lenbuf, 1);
			}
			break;
		}
		gPriAccount[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gPriAccountLen + 1) / 2)
		{
			my_printf("2域\n主账户：");
			PrintFormat((char*)gPriAccount, recvindex);
            [output appendString:@"2域\n主账户："];
            AddStr((unsigned char*)gPriAccount, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 3:
		gTransacCode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gTransacCode))
		{
			my_printf("3域\n交易处理码：");
			PrintFormat((char*)gTransacCode, recvindex);
            [output appendString:@"3域\n交易处理码："];
            AddStr((unsigned char*)gTransacCode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 4:
		gTransacAmount[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gTransacAmount))
		{
			my_printf("4域\n交易金额：");
			PrintFormat((char*)gTransacAmount, recvindex);
            [output appendString:@"4域\n交易金额："];
            AddStr((unsigned char*)gTransacAmount, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 11:
		gSysTraceAudit[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gSysTraceAudit))
		{
			my_printf("11域\n终端流水号：");
			PrintFormat((char*)gSysTraceAudit, recvindex);
            [output appendString:@"11域\n终端流水号："];
            AddStr((unsigned char*)gSysTraceAudit, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 12:
		gLocalTime[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gLocalTime))
		{
			my_printf("12域\n本地时间：");
			PrintFormat((char*)gLocalTime, recvindex);
            [output appendString:@"12域\n本地时间："];
            AddStr((unsigned char*)gLocalTime, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 13:
		gLocalDate[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gLocalDate))
		{
			my_printf("13域\n本地日期：");
			PrintFormat((char*)gLocalDate, recvindex);
            [output appendString:@"13域\n本地日期："];
            AddStr((unsigned char*)gLocalDate, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 14:
		gValidity[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gValidity))
		{
			my_printf("14域\n卡有效期：");
			PrintFormat((char*)gValidity, recvindex);
            [output appendString:@"14域\n卡有效期："];
            AddStr((unsigned char*)gValidity, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 15:
		gSettleDate[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gSettleDate))
		{
			my_printf("15域\n清算日期：");
			PrintFormat((char*)gSettleDate, recvindex);
            [output appendString:@"15域\n清算日期："];
            AddStr((unsigned char*)gSettleDate, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 22:
		gSerEntryMode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gSerEntryMode))
		{
			my_printf("22域\n服务点输入方式码：");
			PrintFormat((char*)gSerEntryMode, recvindex);
            [output appendString:@"22域\n服务点输入方式码："];
            AddStr((unsigned char*)gSerEntryMode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 23:
		gCardSequence[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gCardSequence))
		{
			my_printf("23域\n卡序列号：");
			PrintFormat((char*)gCardSequence, recvindex);
            [output appendString:@"23域\n卡序列号："];
            AddStr((unsigned char*)gCardSequence, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 25:
		gSerCondition[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gSerCondition))
		{
			my_printf("25域\n服务点条件码：");
			PrintFormat((char*)gSerCondition, recvindex);
            [output appendString:@"25域\n服务点条件码："];
            AddStr((unsigned char*)gSerCondition, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 26:
		gPinCapMode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gPinCapMode))
		{
			my_printf("26域\n服务点PIN获取码：");
			PrintFormat((char*)gPinCapMode, recvindex);
            [output appendString:@"26域\n服务点PIN获取码："];
            AddStr((unsigned char*)gPinCapMode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 32:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 1)
			{
				recvindex = 0;
				recvlenmark = 1;
				gAcqIdenCodeLen = BCDToInt((u8*)lenbuf, 1);
			}
			break;
		}
		gAcqIdenCode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gAcqIdenCodeLen + 1) / 2)
		{
			my_printf("32域\n受理方识码:");
			PrintFormat((char*)gAcqIdenCode, recvindex);
            [output appendString:@"32域\n受理方识码："];
            AddStr((unsigned char*)gAcqIdenCode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 35:
       if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 1)
			{
				recvindex = 0;
				recvlenmark = 1;
				gTrack2Len = BCDToInt((u8*)lenbuf, 1);
			}
			break;
		}
       //        NSString *str111 = [NSString stringWithUTF8String:recvchar];
		gTrack2[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gTrack2Len + 1) / 2)
		{
            my_printf("35域\n二磁道数据:");
			PrintFormat((char*)gTrack2, recvindex);
            [output appendString:@"35域\n二磁道数据："];
            AddStr((unsigned char*)gTrack2, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 36:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gTrack3Len = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gTrack3[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gTrack3Len + 1) / 2)
		{
            my_printf("36域\n三磁道数据:");
			PrintFormat((char*)gTrack3, recvindex);
            [output appendString:@"36域\n三磁道数据："];
            AddStr((unsigned char*)gTrack3, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 37:
		gRetrieval[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gRetrieval))
		{
			my_printf("37域\nPOS中心流水号:");
			PrintFormat((char*)gRetrieval, recvindex);
            [output appendString:@"37域\nPOS中心流水号："];
            AddStr((unsigned char*)gRetrieval, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 38:
		gAuthIdentiRespon[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gAuthIdentiRespon))
		{
			my_printf("38域\n授权标识应答码:");
			PrintFormat((char*)gAuthIdentiRespon, recvindex);
            [output appendString:@"38域\n授权标识应答码："];
            AddStr((unsigned char*)gAuthIdentiRespon, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 39:
		gResponCode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gResponCode))
		{
			my_printf("39域\n响应码:");
			PrintFormat((char*)gResponCode, recvindex);
            [output appendString:@"39域\n响应码："];
            AddStr((unsigned char*)gResponCode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 41:
		gTerminalCode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gTerminalCode))
		{
			my_printf("41域\n终端号:");
			PrintFormat((char*)gTerminalCode, recvindex);
            [output appendString:@"41域\n终端号："];
            AddStr((unsigned char*)gTerminalCode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 42:
		gMerchantCode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gMerchantCode))
		{
			my_printf("42域\n商户号:");
			PrintFormat((char*)gMerchantCode, recvindex);
            [output appendString:@"42域\n商户号："];
            AddStr((unsigned char*)gMerchantCode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 44:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 1)
			{
				recvindex = 0;
				recvlenmark = 1;
				gAdditionResponLen = BCDToInt((u8*)lenbuf, 1);
			}
			break;
		}
		gAdditionRespon[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gAdditionResponLen)
		{
			my_printf("44域\n发卡行收单行标识码:");
			PrintFormat((char*)gAdditionRespon, recvindex);
            [output appendString:@"44域\n发卡行收单行标识码："];
            AddStr((unsigned char*)gAdditionRespon, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 48:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gAdditionPrivateLen = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gAdditionPrivate[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gAdditionPrivateLen + 1) / 2)
		{
			my_printf("48域:\n私有域");
			PrintFormat((char*)gAdditionPrivate, recvindex);
            [output appendString:@"48域:\n私有域："];
            AddStr((unsigned char*)gAdditionPrivate, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 49:
		gCurrencyCode[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gCurrencyCode))
		{
			my_printf("49域\n交易货币代码:");
			PrintFormat((char*)gCurrencyCode, recvindex);
            [output appendString:@"49域\n交易货币代码："];
            AddStr((unsigned char*)gCurrencyCode, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 52:
		gPinData[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gPinData))
		{
			my_printf("52域\nPIN码:");
			PrintFormat((char*)gPinData, recvindex);
            [output appendString:@"52域\nPIN码："];
            AddStr((unsigned char*)gPinData, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 53:
		gSecurityInfo[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gSecurityInfo))
		{
			my_printf("53域\n安全相关控制信息:");
			PrintFormat((char*)gSecurityInfo, recvindex);
            [output appendString:@"53域\n安全相关控制信息："];
            AddStr((unsigned char*)gSecurityInfo, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 54:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gBalanceAmountLen = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gBalanceAmount[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gBalanceAmountLen)
		{
			my_printf("54域\n余额:");
			PrintFormat((char*)gBalanceAmount, recvindex);
            [output appendString:@"54域\n余额："];
            AddStr((unsigned char*)gBalanceAmount, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 55:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gICDataLen = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gICData[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gICDataLen)
		{
			my_printf("55域\nIC卡数据:");
			PrintFormat((char*)gICData, recvindex);
            [output appendString:@"55域\nIC卡数据："];
            AddStr((unsigned char*)gICData, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 57:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gOtherTermParamLen = BCDToInt((u8*)lenbuf, 2);
			}
			else
			{
				break;
			}
			if(gOtherTermParamLen)break;
		}
		gOtherTermParam[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gOtherTermParamLen)
		{
			my_printf("57域\n其他终端参数:");
			PrintFormat((char*)gOtherTermParam, recvindex);
            [output appendString:@"57域\n其他终端参数："];
            AddStr((unsigned char*)gOtherTermParam, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 58:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gPBOCDataLen = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gPBOCData[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gPBOCDataLen)
		{
			my_printf("58域\n电子钱包交易信息:");
			PrintFormat((char*)gPBOCData, recvindex);
            [output appendString:@"58域\n电子钱包交易信息："];
            AddStr((unsigned char*)gPBOCData, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 59:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gUserArea59Len = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gUserArea59[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gUserArea59Len)
		{
			my_printf("59域\n自定义:");
			PrintFormat((char*)gUserArea59, recvindex);
            [output appendString:@"59域\n自定义："];
            AddStr((unsigned char*)gUserArea59, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 60:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gUserArea60Len = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gUserArea60[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gUserArea60Len + 1) / 2)
		{
			my_printf("60域\n自定义:");
			PrintFormat((char*)gUserArea60, recvindex);
            [output appendString:@"60域\n自定义："];
            AddStr((unsigned char*)gUserArea60, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 61:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gOrgMsgLen = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gOrgMsg[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= (gOrgMsgLen + 1) / 2)
		{
			my_printf("61域\n自定义:");
			PrintFormat((char*)gOrgMsg, recvindex);
            [output appendString:@"61域\n自定义："];
            AddStr((unsigned char*)gOrgMsg, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 62:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gUserArea62Len = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gUserArea62[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gUserArea62Len)
		{
			my_printf("62域\n自定义:");
			PrintFormat((char*)gUserArea62, recvindex);
            [output appendString:@"62域\n自定义："];
            AddStr((unsigned char*)gUserArea62, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 63:
		if(recvlenmark == 0)
		{
			lenbuf[recvindex] = recvchar;
			recvindex++;
			if(recvindex >= 2)
			{
				recvindex = 0;
				recvlenmark = 1;
				gUserArea63Len = BCDToInt((u8*)lenbuf, 2);
			}
			break;
		}
		gUserArea63[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= gUserArea63Len)
		{
			my_printf("63域\n自定义:");
			PrintFormat((char*)gUserArea63, recvindex);
            [output appendString:@"63域\n自定义："];
            AddStr((unsigned char*)gUserArea63, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	case 64:
		gMac[recvindex] = recvchar;
		recvindex++;
		if(recvindex >= sizeof(gMac))
		{
			my_printf("64域\n校验和:");
			PrintFormat((char*)gMac, recvindex);
            [output appendString:@"64域\n校验和："];
            AddStr((unsigned char*)gMac, recvindex);
			recvindex = 0;
			gRecvStep = GetNextBmpArea(gRecvStep - 7) + 7;
			recvlenmark = 0;
		}
		break;
	default:
		break;
	}

	if(gRecvStep == 7)
	{
		/*data recv complete*/
		gRecvStep = 0;
		return 0;
	}

	return 1;
}


int getBankCardNo(char str[22]){
    char gTrack2Str[gTrack2Len];
    char gTrack3Str[gTrack3Len];
    
    int len=gPriAccountLen>22?22:gPriAccountLen;
    if (len>0) {
        char str0[len];
        HexToStr((void *)gPriAccount, (void *)str0, len);
        strcpy(str, str0);
    }
    
    if(strlen(str)<1){
        if (gTrack2Len>0) {
            
            HexToStr((void *)gTrack2, (void *)gTrack2Str, gTrack2Len);
            
            printf("2~~~~~%s",gTrack2Str);
            
            for(int i=0;i<gTrack2Len;i++){
                
                if(gTrack2Str[i]>=48&&gTrack2Str[i]<=57){
                    str[i]=gTrack2Str[i];
                }else{
//                    str[i]='Q';
                    break;
                }
            }
        }
    }
    
    if(strlen(str)<1){
        if (gTrack3Len>0) {
            HexToStr((void *)gTrack3, (void *)gTrack3Str, gTrack3Len);
            printf("~~~~~%s",gTrack3Str);
            
            for(int i=2;i<gTrack3Len;i++){
                
                if(gTrack3Str[i]>=48&&gTrack3Str[i]<=57){
                    printf("^^^^^^^^^^%x",gTrack3Str[i]);
                    str[i]=gTrack3Str[i];
                }else{
//                    str[i]='Q';
//                    printf("_____________%s",str);
                    break;
                }
            }
        }
    }
    return 0;

}