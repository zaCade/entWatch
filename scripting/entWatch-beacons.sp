//====================================================================================================
//
// Name: [entWatch] Beacon
// Author: zaCade & Prometheum
// Description: Handle the beacons of [entWatch]
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

/* CONVARS */
ConVar g_hCVar_EnableSpawnedBeacon = null;
ConVar g_hCVar_EnableDroppedBeacon = null;

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name         = "[entWatch] Beacons",
	author       = "zaCade & Prometheum",
	description  = "Handle the beacons of [entWatch]",
	version      = EW_VERSION
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	g_hCVar_EnableSpawnedBeacon = CreateConVar("sm_ebeacons_spawnedbeacons", "1", "Enable beacons on not yet equipped items.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVar_EnableDroppedBeacon = CreateConVar("sm_ebeacons_droppedbeacons", "1", "Enable beacons on dropped items.",          FCVAR_NONE, true, 0.0, true, 1.0);

	AutoExecConfig();
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnMapStart()
{
	LoadGameConfig();

	CreateTimer(1.0, OnBeacons, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
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
stock Action OnBeacons(Handle hTimer)
{
	bool bSpawnedBeacons = g_hCVar_EnableSpawnedBeacon.BoolValue;
	bool bDroppedBeacons = g_hCVar_EnableDroppedBeacon.BoolValue;

	ArrayList hItems = EW_GetItemsArray();

	for (int iItemID; iItemID < hItems.Length; iItemID++)
	{
		CItem hItem = hItems.Get(iItemID);

		if (!IsValidEntity(hItem.iWeapon))
			continue;

		if ((hItem.iState == EW_ENTITY_STATE_SPAWNED && bSpawnedBeacons) ||
			(hItem.iState == EW_ENTITY_STATE_DROPPED && bDroppedBeacons))
		{
			float flOrigin[3];
			GetEntPropVector(hItem.iWeapon, Prop_Data, "m_vecOrigin", flOrigin);

			flOrigin[2] += 2;

			char sColor[8];
			hItem.hConfig.GetColor(sColor, sizeof(sColor));

			int iColorDecimal;
			StringToIntEx(sColor, iColorDecimal, 16);

			int iColor[4];
			iColor[0] = iColorDecimal >> 16 & 0xFF;
			iColor[1] = iColorDecimal >> 8  & 0xFF;
			iColor[2] = iColorDecimal >> 0  & 0xFF;
			iColor[3] = 0xFF;

			TE_SetupBeamRingPoint(flOrigin, 10.0, 50.0, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.6, 4.0, 0.5, iColor, 10, 0);
			TE_SendToAll();
		}
	}

	return Plugin_Continue;
}
