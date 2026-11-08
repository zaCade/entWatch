//====================================================================================================
//
// Name: [entWatch] Debug
// Author: zaCade & Prometheum
// Description: Handle the debug functions of [entWatch]
//
//====================================================================================================
// Requires Sourcemod Version: 1.10.0.6531 or above
//====================================================================================================
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <entWatch_core>

/* INTERGERS */
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name         = "[entWatch] Debug",
	author       = "zaCade & Prometheum",
	description  = "Handle the debug functions of [entWatch]",
	version      = EW_VERSION
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	RegAdminCmd("sm_edebug_printitems",   Command_PrintItems,   ADMFLAG_CONFIG);
	RegAdminCmd("sm_edebug_printconfigs", Command_PrintConfigs, ADMFLAG_CONFIG);

	RegAdminCmd("sm_edebug_loadconfig",   Command_LoadConfig,   ADMFLAG_CONFIG);
	RegAdminCmd("sm_edebug_traceitems",   Command_TraceItems,   ADMFLAG_CONFIG);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnMapStart()
{
	LoadGameConfig();
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void LoadGameConfig()
{
	GameData hGameConf;
	if ((hGameConf = new GameData("funcommands.games")) == null)
	{
		SetFailState("Couldn't load \"funcommands.games\" game config!");
		return;
	}

	char sBuffer[PLATFORM_MAX_PATH];
	if (hGameConf.GetKeyValue("SpriteBeam", sBuffer, sizeof(sBuffer)) && sBuffer[0])
		g_iBeamSprite = PrecacheModel(sBuffer);

	if (hGameConf.GetKeyValue("SpriteHalo", sBuffer, sizeof(sBuffer)) && sBuffer[0])
		g_iHaloSprite = PrecacheModel(sBuffer);

	delete hGameConf;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_PrintItems(int iClient, int iArgs)
{
	int iArgConfigID = -1;

	if (iArgs >= 1)
	{
		char sArgConfigID[4];
		GetCmdArg(1, sArgConfigID, sizeof(sArgConfigID));

		iArgConfigID = StringToInt(sArgConfigID);
	}

	ArrayList hItems = EW_GetItemsArray();

	for (int iItemID; iItemID < hItems.Length; iItemID++)
	{
		CItem hItem = hItems.Get(iItemID);

		if (iArgConfigID != -1 && hItem.hConfig.iConfigID != iArgConfigID)
			continue;

		char sClientName[32];
		if (IsValidClient(hItem.iClient))
			GetClientName(hItem.iClient, sClientName, sizeof(sClientName));

		char sWeaponClass[32];
		if (IsValidEntity(hItem.iWeapon))
			GetEntityClassname(hItem.iWeapon, sWeaponClass, sizeof(sWeaponClass));

		PrintToConsole(iClient, "Item [%d|%d]\n\tiClient: %d <%s>\n\tiWeapon: %d <%s>\n\tiState: %d\n\tflReadyTime: %f",
			hItem.hConfig.iConfigID,
			hItem.iCreateID,
			hItem.iClient,
			sClientName,
			hItem.iWeapon,
			sWeaponClass,
			hItem.iState,
			hItem.flReadyTime
		);

		for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
		{
			CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

			char sButtonClass[32];
			if (IsValidEntity(hItemButton.iButton))
				GetEntityClassname(hItemButton.iButton, sButtonClass, sizeof(sButtonClass));

			PrintToConsole(iClient, "\tButton [%d]\n\t\tiButton: %d <%s>\n\t\tiState: %d\n\t\tiCurrentUses: %d\n\t\tflWaitTime: %f\n\t\tflReadyTime: %f",
				hItemButton.hConfigButton.iConfigID,
				hItemButton.iButton,
				sButtonClass,
				hItemButton.iState,
				hItemButton.iCurrentUses,
				hItemButton.flWaitTime,
				hItemButton.flReadyTime
			);
		}

		for (int iItemTriggerID; iItemTriggerID < hItem.hTriggers.Length; iItemTriggerID++)
		{
			CItemTrigger hItemTrigger = hItem.hTriggers.Get(iItemTriggerID);

			char sTriggerClass[32];
			if (IsValidEntity(hItemTrigger.iTrigger))
				GetEntityClassname(hItemTrigger.iTrigger, sTriggerClass, sizeof(sTriggerClass));

			PrintToConsole(iClient, "\tTrigger [%d]\n\t\tiTrigger: %d <%s>\n\t\tiState: %d",
				hItemTrigger.hConfigTrigger.iConfigID,
				hItemTrigger.iTrigger,
				sTriggerClass,
				hItemTrigger.iState
			);
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_PrintConfigs(int iClient, int iArgs)
{
	int iArgConfigID = -1;

	if (iArgs >= 1)
	{
		char sArgConfigID[4];
		GetCmdArg(1, sArgConfigID, sizeof(sArgConfigID));

		iArgConfigID = StringToInt(sArgConfigID);
	}

	ArrayList hConfigs = EW_GetConfigsArray();

	for (int iConfigID; iConfigID < hConfigs.Length; iConfigID++)
	{
		CConfig hConfig = hConfigs.Get(iConfigID);

		if (iArgConfigID != -1 && hConfig.iConfigID != iArgConfigID)
			continue;

		char sName[32];
		hConfig.GetName(sName, sizeof(sName));

		char sShort[16];
		hConfig.GetShort(sShort, sizeof(sShort));

		char sColor[8];
		hConfig.GetColor(sColor, sizeof(sColor));

		PrintToConsole(iClient, "Config\n\tsName: %s\n\tsShort: %s\n\tsColor: %s\n\tiConfigID: %d\n\tiHammerID: %d\n\tbShowMessages: %d\n\tbShowInterface: %d",
			sName,
			sShort,
			sColor,
			hConfig.iConfigID,
			hConfig.iHammerID,
			view_as<int>(hConfig.bShowMessages),
			view_as<int>(hConfig.bShowInterface)
		);

		for (int iConfigButtonID; iConfigButtonID < hConfig.hButtons.Length; iConfigButtonID++)
		{
			CConfigButton hConfigButton = hConfig.hButtons.Get(iConfigButtonID);

			char sName2[32];
			hConfigButton.GetName(sName2, sizeof(sName2));

			char sOutput[32];
			hConfigButton.GetOutput(sOutput, sizeof(sOutput));

			PrintToConsole(iClient, "\tButton\n\t\tsName: %s\n\t\tsOutput: %s\n\t\tiConfigID: %d\n\t\tiHammerID: %d\n\t\tiType: %d\n\t\tiMode: %d\n\t\tiMaxUses: %d\n\t\tflButtonCooldown: %f\n\t\tflItemCooldown: %f\n\t\tbShowActivate: %d\n\t\tbShowCooldown: %d",
				sName2,
				sOutput,
				hConfigButton.iConfigID,
				hConfigButton.iHammerID,
				hConfigButton.iType,
				hConfigButton.iMode,
				hConfigButton.iMaxUses,
				hConfigButton.flButtonCooldown,
				hConfigButton.flItemCooldown,
				view_as<int>(hConfigButton.bShowActivate),
				view_as<int>(hConfigButton.bShowCooldown)
			);
		}

		for (int iConfigTriggerID; iConfigTriggerID < hConfig.hTriggers.Length; iConfigTriggerID++)
		{
			CConfigTrigger hConfigTrigger = hConfig.hTriggers.Get(iConfigTriggerID);

			PrintToConsole(iClient, "\tTrigger\n\t\tiConfigID: %d\n\t\tiHammerID: %d\n\t\tiType: %d",
				hConfigTrigger.iConfigID,
				hConfigTrigger.iHammerID,
				hConfigTrigger.iType
			);
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_LoadConfig(int iClient, int iArgs)
{
	bool bSuccessful = EW_LoadConfig(true);

	ReplyToCommand(iClient, "\x04[entWatch] \x01loaded map config. (Status: %s)", bSuccessful ? "Successful" : "Failed");
	LogAction(iClient, -1, "\"%L\" loaded map config.", iClient);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_TraceItems(int iClient, int iArgs)
{
	if (!IsValidClient(iClient))
		return Plugin_Handled;

	ArrayList hItems = EW_GetItemsArray();

	for (int iItemID; iItemID < hItems.Length; iItemID++)
	{
		CItem hItem = hItems.Get(iItemID);

		if (!IsValidEntity(hItem.iWeapon))
			continue;

		if (hItem.iState != EW_ENTITY_STATE_SPAWNED && hItem.iState != EW_ENTITY_STATE_DROPPED)
			continue;

		float flOriginStart[3];
		GetClientAbsOrigin(iClient, flOriginStart);

		float flOriginEnd[3];
		GetEntPropVector(hItem.iWeapon, Prop_Data, "m_vecOrigin", flOriginEnd);

		flOriginStart[2] += 2;
		flOriginEnd[2] += 2;

		char sColor[8];
		hItem.hConfig.GetColor(sColor, sizeof(sColor));

		int iColorDecimal;
		StringToIntEx(sColor, iColorDecimal, 16);

		int iColor[4];
		iColor[0] = iColorDecimal >> 16 & 0xFF;
		iColor[1] = iColorDecimal >> 8  & 0xFF;
		iColor[2] = iColorDecimal >> 0  & 0xFF;
		iColor[3] = 0xFF;

		TE_SetupBeamPoints(flOriginStart, flOriginEnd, g_iBeamSprite, g_iHaloSprite, 0, 10, 5.0, 2.0, 2.0, 0, 0.5, iColor, 10);
		TE_SendToClient(iClient);
	}

	ReplyToCommand(iClient, "\x04[entWatch] \x01items traced.");
	LogAction(iClient, -1, "\"%L\" traced items.", iClient);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool IsValidClient(int iClient)
{
	return ((1 <= iClient <= MaxClients) && IsClientConnected(iClient));
}
