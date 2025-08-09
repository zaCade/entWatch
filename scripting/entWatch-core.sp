//====================================================================================================
//
// Name: [entWatch] Core
// Author: zaCade & Prometheum
// Description: Handle the core functions of [entWatch]
//
//====================================================================================================
// Requires Sourcemod Version: 1.10.0.6531 or above
//====================================================================================================
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools_entoutput>
#include <sdktools_functions>
#include <entWatch_core>

/* BOOLS */
bool g_bLate;
bool g_bIntermission;

/* FLOATS */
float g_flGameFrameTime;

/* ARRAYS */
ArrayList g_hArray_Items;
ArrayList g_hArray_Configs;

/* FORWARDS */
GlobalForward g_hFwd_OnClientItemWeaponInteract;
GlobalForward g_hFwd_OnClientItemButtonInteract;
GlobalForward g_hFwd_OnClientItemTriggerInteract;

GlobalForward g_hFwd_OnClientItemWeaponCanInteract;
GlobalForward g_hFwd_OnClientItemButtonCanInteract;
GlobalForward g_hFwd_OnClientItemTriggerCanInteract;

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name         = "[entWatch] Core",
	author       = "zaCade & Prometheum",
	description  = "Handle the core functions of [entWatch]",
	version      = EW_VERSION
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorSize)
{
	g_bLate = bLate;

	CreateNative("EW_LoadConfig",      Native_LoadConfig);

	CreateNative("EW_GetItemsArray",   Native_GetItemsArray);
	CreateNative("EW_GetConfigsArray", Native_GetConfigsArray);

	CreateNative("EW_IsEntityItem",    Native_IsEntityItem);
	CreateNative("EW_ClientHasItem",   Native_ClientHasItem);

	RegPluginLibrary("entWatch-core");
	return APLRes_Success;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	g_hFwd_OnClientItemWeaponInteract  = new GlobalForward("EW_OnClientItemWeaponInteract", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hFwd_OnClientItemButtonInteract  = new GlobalForward("EW_OnClientItemButtonInteract", ET_Ignore, Param_Cell, Param_Cell);
	g_hFwd_OnClientItemTriggerInteract = new GlobalForward("EW_OnClientItemTriggerInteract", ET_Ignore, Param_Cell, Param_Cell);

	g_hFwd_OnClientItemWeaponCanInteract  = new GlobalForward("EW_OnClientItemWeaponCanInteract",  ET_Hook, Param_Cell, Param_Cell);
	g_hFwd_OnClientItemButtonCanInteract  = new GlobalForward("EW_OnClientItemButtonCanInteract",  ET_Hook, Param_Cell, Param_Cell);
	g_hFwd_OnClientItemTriggerCanInteract = new GlobalForward("EW_OnClientItemTriggerCanInteract", ET_Hook, Param_Cell, Param_Cell);

	g_hArray_Items   = new ArrayList();
	g_hArray_Configs = new ArrayList();

	HookEvent("player_death", OnClientDeath);
	HookEvent("round_start",  OnRoundStart);
	HookEvent("round_end",    OnRoundEnd);

	if (g_bLate)
	{
		for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (!IsClientConnected(iClient))
				continue;

			SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponPickup);
			SDKHook(iClient, SDKHook_WeaponDropPost, OnWeaponDrop);
			SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponTouch);
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginEnd()
{
	CleanupItems();
	CleanupConfigs();
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnMapStart()
{
	LoadConfig(g_bLate);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnMapEnd()
{
	CleanupItems();
	CleanupConfigs();
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool LoadConfig(bool bLoopEntities = false)
{
	CleanupItems();
	CleanupConfigs();

	char sGameDirectory[128];
	GetGameFolderName(sGameDirectory, sizeof(sGameDirectory));

	char sCurrentMap[128];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));

	int iChar;
	while (sCurrentMap[iChar] != EOS && iChar < sizeof(sCurrentMap))
	{
		sCurrentMap[iChar] = CharToLower(sCurrentMap[iChar]);
		iChar++;
	}

	char sFilePathDefault[PLATFORM_MAX_PATH];
	char sFilePathOverride[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, sFilePathDefault, sizeof(sFilePathDefault), "configs/entwatch/%s/%s.cfg", sGameDirectory, sCurrentMap);
	BuildPath(Path_SM, sFilePathOverride, sizeof(sFilePathOverride), "configs/entwatch/%s/%s.override.cfg", sGameDirectory, sCurrentMap);

	KeyValues hConfigFile = new KeyValues("items");

	if (FileExists(sFilePathOverride))
	{
		if (!hConfigFile.ImportFromFile(sFilePathOverride))
		{
			LogMessage("Unable to load config \"%s\"!", sFilePathOverride);

			delete hConfigFile;
			return false;
		}
		else LogMessage("Loaded config \"%s\"", sFilePathOverride);
	}
	else
	{
		if (!hConfigFile.ImportFromFile(sFilePathDefault))
		{
			LogMessage("Unable to load config \"%s\"!", sFilePathDefault);

			delete hConfigFile;
			return false;
		}
		else LogMessage("Loaded config \"%s\"", sFilePathDefault);
	}

	int iConfigVersion = -1;
	if ((iConfigVersion = hConfigFile.GetNum("configversion", -1)) < EW_VERSION_CONFIG)
	{
		LogMessage("Config version unsupported or not specified! (version: [%d] | required: [%d])", iConfigVersion, EW_VERSION_CONFIG);
		delete hConfigFile;
		return false;
	}

	if (hConfigFile.GotoFirstSubKey())
	{
		int iConfigID;

		do
		{
			CConfig hConfig = new CConfig();

			char sName[32], sShort[16], sColor[8];
			hConfigFile.GetString("name",   sName,   sizeof(sName));
			hConfigFile.GetString("short",  sShort,  sizeof(sShort));
			hConfigFile.GetString("color",  sColor,  sizeof(sColor));

			hConfig.SetName(sName);
			hConfig.SetShort(sShort);
			hConfig.SetColor(sColor);

			hConfig.iConfigID      = iConfigID++;
			hConfig.iHammerID      = hConfigFile.GetNum("hammerid");

			hConfig.bShowMessages  = view_as<bool>(hConfigFile.GetNum("showmessages", 1));
			hConfig.bShowInterface = view_as<bool>(hConfigFile.GetNum("showinterface", 1));

			if (hConfigFile.JumpToKey("buttons"))
			{
				if (hConfigFile.GotoFirstSubKey())
				{
					int iConfigButtonID;

					do
					{
						CConfigButton hConfigButton = new CConfigButton(hConfig);

						char sOutput[32];
						hConfigFile.GetString("output", sOutput, sizeof(sOutput));

						hConfigButton.SetOutput(sOutput);

						hConfigButton.iConfigID = iConfigButtonID++;
						hConfigButton.iHammerID = hConfigFile.GetNum("hammerid");
						hConfigButton.iType     = hConfigFile.GetNum("type");
						hConfigButton.iMode     = hConfigFile.GetNum("mode");
						hConfigButton.iMaxUses  = hConfigFile.GetNum("maxuses");

						hConfigButton.flButtonCooldown = hConfigFile.GetFloat("cooldown");
						hConfigButton.flItemCooldown   = hConfigFile.GetFloat("itemcooldown");

						hConfigButton.bShowActivate = view_as<bool>(hConfigFile.GetNum("showactivate", 1));
						hConfigButton.bShowCooldown = view_as<bool>(hConfigFile.GetNum("showcooldown", 1));

						hConfig.hButtons.Push(hConfigButton);
					}
					while (hConfigFile.GotoNextKey());

					hConfigFile.GoBack();
				}

				hConfigFile.GoBack();
			}

			if (hConfigFile.JumpToKey("triggers"))
			{
				if (hConfigFile.GotoFirstSubKey())
				{
					int iConfigTriggerID;

					do
					{
						CConfigTrigger hConfigTrigger = new CConfigTrigger(hConfig);

						hConfigTrigger.iConfigID = iConfigTriggerID++;
						hConfigTrigger.iHammerID = hConfigFile.GetNum("hammerid");
						hConfigTrigger.iType     = hConfigFile.GetNum("type");

						hConfig.hTriggers.Push(hConfigTrigger);
					}
					while (hConfigFile.GotoNextKey());

					hConfigFile.GoBack();
				}

				hConfigFile.GoBack();
			}

			g_hArray_Configs.Push(hConfig);
		}
		while (hConfigFile.GotoNextKey());
	}

	if (bLoopEntities)
	{
		int iEntity = INVALID_ENT_REFERENCE;
		while ((iEntity = FindEntityByClassname(iEntity, "*")) != INVALID_ENT_REFERENCE)
		{
			OnEntitySpawnPost(iEntity);
		}
	}

	delete hConfigFile;
	return true;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void CleanupConfigs()
{
	if (g_hArray_Configs.Length)
	{
		for (int iConfigID; iConfigID < g_hArray_Configs.Length; iConfigID++)
		{
			CConfig hConfig = g_hArray_Configs.Get(iConfigID);

			for (int iConfigButtonID; iConfigButtonID < hConfig.hButtons.Length; iConfigButtonID++)
			{
				CConfigButton hConfigButton = hConfig.hButtons.Get(iConfigButtonID);

				delete hConfigButton;
			}

			for (int iConfigTriggerID; iConfigTriggerID < hConfig.hTriggers.Length; iConfigTriggerID++)
			{
				CConfigTrigger hConfigTrigger = hConfig.hTriggers.Get(iConfigTriggerID);

				delete hConfigTrigger;
			}

			delete hConfig;
		}

		g_hArray_Configs.Clear();
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void CleanupItems()
{
	if (g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
			{
				CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

				if (IsValidEntity(hItemButton.iButton))
				{
					switch (hItemButton.hConfigButton.iType)
					{
						case (EW_BUTTON_TYPE_USE):
						{
							SDKUnhook(hItemButton.iButton, SDKHook_Use, OnButtonPress);
						}
						case (EW_BUTTON_TYPE_OUTPUT):
						{
							char sButtonOutput[32];
							hItemButton.hConfigButton.GetOutput(sButtonOutput, sizeof(sButtonOutput));

							UnhookSingleEntityOutput(hItemButton.iButton, sButtonOutput, OnButtonOutput);
						}
					}
				}

				delete hItemButton;
			}

			for (int iItemTriggerID; iItemTriggerID < hItem.hTriggers.Length; iItemTriggerID++)
			{
				CItemTrigger hItemTrigger = hItem.hTriggers.Get(iItemTriggerID);

				if (IsValidEntity(hItemTrigger.iTrigger))
				{
					switch (hItemTrigger.hConfigTrigger.iType)
					{
						case (EW_TRIGGER_TYPE_STRIP):
						{
							SDKUnhook(hItemTrigger.iTrigger, SDKHook_StartTouch, OnTriggerTouch);
							SDKUnhook(hItemTrigger.iTrigger, SDKHook_EndTouch, OnTriggerTouch);
							SDKUnhook(hItemTrigger.iTrigger, SDKHook_Touch, OnTriggerTouch);
						}
					}
				}

				delete hItemTrigger;
			}

			delete hItem;
		}

		g_hArray_Items.Clear();
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void OnRoundStart(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	g_bIntermission = false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void OnRoundEnd(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	CleanupItems();

	g_bIntermission = true;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnEntityCreated(int iEntity, const char[] sClassname)
{
	if (IsValidEntity(iEntity) && g_hArray_Configs.Length)
	{
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawnPost);
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void OnEntitySpawnPost(int iEntity)
{
	if (IsValidEntity(iEntity) && g_hArray_Configs.Length)
	{
		int iHammerID = GetEntProp(iEntity, Prop_Data, "m_iHammerID");

		for (int iConfigID; iConfigID < g_hArray_Configs.Length; iConfigID++)
		{
			CConfig hConfig = g_hArray_Configs.Get(iConfigID);

			if (hConfig.iHammerID && hConfig.iHammerID == iHammerID)
			{
				bool bRegistered;

				for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
				{
					CItem hItem = g_hArray_Items.Get(iItemID);

					if (hItem.hConfig == hConfig)
					{
						if (RegisterItemWeapon(hItem, iEntity))
						{
							bRegistered = true;
							break;
						}
					}
				}

				if (!bRegistered)
				{
					CItem hItem = new CItem(hConfig, g_hArray_Items.Length);

					if (RegisterItemWeapon(hItem, iEntity))
					{
						InsertItemSorted(g_hArray_Items, hItem);
						break;
					}
					else delete hItem;
				}
			}

			for (int iConfigButtonID; iConfigButtonID < hConfig.hButtons.Length; iConfigButtonID++)
			{
				CConfigButton hConfigButton = hConfig.hButtons.Get(iConfigButtonID);

				if (hConfigButton.iHammerID && hConfigButton.iHammerID == iHammerID)
				{
					bool bRegistered;

					for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
					{
						CItem hItem = g_hArray_Items.Get(iItemID);

						if (hItem.hConfig == hConfig)
						{
							if (RegisterItemButton(hConfigButton, hItem, iEntity))
							{
								bRegistered = true;
								break;
							}
						}
					}

					if (!bRegistered)
					{
						CItem hItem = new CItem(hConfig, g_hArray_Items.Length);

						if (RegisterItemButton(hConfigButton, hItem, iEntity))
						{
							InsertItemSorted(g_hArray_Items, hItem);
							break;
						}
						else delete hItem;
					}
				}
			}

			for (int iConfigTriggerID; iConfigTriggerID < hConfig.hTriggers.Length; iConfigTriggerID++)
			{
				CConfigTrigger hConfigTrigger = hConfig.hTriggers.Get(iConfigTriggerID);

				if (hConfigTrigger.iHammerID && hConfigTrigger.iHammerID == iHammerID)
				{
					bool bRegistered;

					for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
					{
						CItem hItem = g_hArray_Items.Get(iItemID);

						if (hItem.hConfig == hConfig)
						{
							if (RegisterItemTrigger(hConfigTrigger, hItem, iEntity))
							{
								bRegistered = true;
								break;
							}
						}
					}

					if (!bRegistered)
					{
						CItem hItem = new CItem(hConfig, g_hArray_Items.Length);

						if (RegisterItemTrigger(hConfigTrigger, hItem, iEntity))
						{
							InsertItemSorted(g_hArray_Items, hItem);
							break;
						}
						else delete hItem;
					}
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void InsertItemSorted(ArrayList hArray, CItem hItem)
{
	bool bShifted;

	for (int iShiftItemID; iShiftItemID < hArray.Length; iShiftItemID++)
	{
		CItem hShiftItem = hArray.Get(iShiftItemID);

		if (hItem.hConfig.iConfigID < hShiftItem.hConfig.iConfigID)
		{
			hArray.ShiftUp(iShiftItemID);
			hArray.Set(iShiftItemID, hItem);

			bShifted = true;
			break;
		}
	}

	if (!bShifted)
		hArray.Push(hItem);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool RegisterItemWeapon(CItem hItem, int iWeapon)
{
	if (IsValidEntity(iWeapon))
	{
		if (hItem.iWeapon == INVALID_ENT_REFERENCE && hItem.iState == EW_ENTITY_STATE_INITIAL)
		{
			hItem.iWeapon = iWeapon;
			hItem.iState  = EW_ENTITY_STATE_SPAWNED;

			int iOwner = INVALID_ENT_REFERENCE;
			if ((iOwner = GetEntPropEnt(iWeapon, Prop_Data, "m_hOwnerEntity")) != INVALID_ENT_REFERENCE && IsValidClient(iOwner))
			{
				hItem.iClient = iOwner;
				hItem.iState  = EW_ENTITY_STATE_EQUIPPED;
			}

			return true;
		}
	}

	return false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool RegisterItemButton(CConfigButton hConfigButton, CItem hItem, int iButton)
{
	if (IsValidEntity(iButton) && !HasDuplicateItemButton(hConfigButton, hItem))
	{
		switch (hConfigButton.iType)
		{
			case (EW_BUTTON_TYPE_USE):
			{
				SDKHook(iButton, SDKHook_Use, OnButtonPress);
			}
			case (EW_BUTTON_TYPE_OUTPUT):
			{
				char sButtonOutput[32];
				hConfigButton.GetOutput(sButtonOutput, sizeof(sButtonOutput));

				HookSingleEntityOutput(iButton, sButtonOutput, OnButtonOutput);
			}
		}

		CItemButton hItemButton = new CItemButton(hConfigButton, hItem);
		hItemButton.iButton = iButton;
		hItemButton.iState  = EW_ENTITY_STATE_SPAWNED;

		bool bShifted;

		for (int iShiftItemButtonID; iShiftItemButtonID < hItem.hButtons.Length; iShiftItemButtonID++)
		{
			CItemButton hShiftItemButton = hItem.hButtons.Get(iShiftItemButtonID);

			if (hConfigButton.iConfigID < hShiftItemButton.hConfigButton.iConfigID)
			{
				hItem.hButtons.ShiftUp(iShiftItemButtonID);
				hItem.hButtons.Set(iShiftItemButtonID, hItemButton);

				bShifted = true;
				break;
			}
		}

		if (!bShifted)
			hItem.hButtons.Push(hItemButton);

		return true;
	}

	return false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool HasDuplicateItemButton(CConfigButton hConfigButton, CItem hItem)
{
	if (hItem.hButtons.Length)
	{
		for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
		{
			CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

			if (hItemButton.hConfigButton == hConfigButton)
				return true;
		}
	}

	return false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool RegisterItemTrigger(CConfigTrigger hConfigTrigger, CItem hItem, int iTrigger)
{
	if (IsValidEntity(iTrigger) && !HasDuplicateItemTrigger(hConfigTrigger, hItem))
	{
		switch (hConfigTrigger.iType)
		{
			case (EW_TRIGGER_TYPE_STRIP):
			{
				SDKHook(iTrigger, SDKHook_StartTouch, OnTriggerTouch);
				SDKHook(iTrigger, SDKHook_EndTouch, OnTriggerTouch);
				SDKHook(iTrigger, SDKHook_Touch, OnTriggerTouch);
			}
		}

		CItemTrigger hItemTrigger = new CItemTrigger(hConfigTrigger, hItem);
		hItemTrigger.iTrigger = iTrigger;
		hItemTrigger.iState   = EW_ENTITY_STATE_SPAWNED;

		bool bShifted;

		for (int iShiftItemTriggerID; iShiftItemTriggerID < hItem.hTriggers.Length; iShiftItemTriggerID++)
		{
			CItemTrigger hShiftItemTrigger = hItem.hTriggers.Get(iShiftItemTriggerID);

			if (hConfigTrigger.iConfigID < hShiftItemTrigger.hConfigTrigger.iConfigID)
			{
				hItem.hTriggers.ShiftUp(iShiftItemTriggerID);
				hItem.hTriggers.Set(iShiftItemTriggerID, hItemTrigger);

				bShifted = true;
				break;
			}
		}

		if (!bShifted)
			hItem.hTriggers.Push(hItemTrigger);

		return true;
	}

	return false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool HasDuplicateItemTrigger(CConfigTrigger hConfigTrigger, CItem hItem)
{
	if (hItem.hTriggers.Length)
	{
		for (int iItemTriggerID; iItemTriggerID < hItem.hTriggers.Length; iItemTriggerID++)
		{
			CItemTrigger hItemTrigger = hItem.hTriggers.Get(iItemTriggerID);

			if (hItemTrigger.hConfigTrigger == hConfigTrigger)
				return true;
		}
	}

	return false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnEntityDestroyed(int iEntity)
{
	if (IsValidEntity(iEntity) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iWeapon != INVALID_ENT_REFERENCE && hItem.iWeapon == iEntity)
			{
				hItem.iClient = INVALID_ENT_REFERENCE;
				hItem.iWeapon = INVALID_ENT_REFERENCE;
				hItem.iState  = EW_ENTITY_STATE_DESTROYED;
			}

			for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
			{
				CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

				if (hItemButton.iButton != INVALID_ENT_REFERENCE && hItemButton.iButton == iEntity)
				{
					hItemButton.iButton = INVALID_ENT_REFERENCE;
					hItemButton.iState  = EW_ENTITY_STATE_DESTROYED;
				}
			}

			for (int iItemTriggerID; iItemTriggerID < hItem.hTriggers.Length; iItemTriggerID++)
			{
				CItemTrigger hItemTrigger = hItem.hTriggers.Get(iItemTriggerID);

				if (hItemTrigger.iTrigger != INVALID_ENT_REFERENCE && hItemTrigger.iTrigger == iEntity)
				{
					hItemTrigger.iTrigger = INVALID_ENT_REFERENCE;
					hItemTrigger.iState   = EW_ENTITY_STATE_DESTROYED;
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnClientPutInServer(int iClient)
{
	SDKHook(iClient, SDKHook_WeaponEquipPost, OnWeaponPickup);
	SDKHook(iClient, SDKHook_WeaponDropPost, OnWeaponDrop);
	SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponTouch);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnClientDisconnect(int iClient)
{
	if (g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iClient != INVALID_ENT_REFERENCE && hItem.iClient == iClient)
			{
				hItem.iClient = INVALID_ENT_REFERENCE;
				hItem.iState = EW_ENTITY_STATE_DROPPED;

				Call_StartForward(g_hFwd_OnClientItemWeaponInteract);
				Call_PushCell(iClient);
				Call_PushCell(hItem);
				Call_PushCell(EW_WEAPON_INTERACTION_DISCONNECT);
				Call_Finish();
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void OnClientDeath(Event hEvent, const char[] sEvent, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));

	if (IsValidClient(iClient) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iClient != INVALID_ENT_REFERENCE && hItem.iClient == iClient)
			{
				hItem.iClient = INVALID_ENT_REFERENCE;
				hItem.iState = EW_ENTITY_STATE_DROPPED;

				Call_StartForward(g_hFwd_OnClientItemWeaponInteract);
				Call_PushCell(iClient);
				Call_PushCell(hItem);
				Call_PushCell(EW_WEAPON_INTERACTION_DEATH);
				Call_Finish();
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void OnWeaponPickup(int iClient, int iWeapon)
{
	if (IsValidClient(iClient) && IsValidEntity(iWeapon) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iWeapon != INVALID_ENT_REFERENCE && hItem.iWeapon == iWeapon)
			{
				hItem.iClient = iClient;
				hItem.iState = EW_ENTITY_STATE_EQUIPPED;

				Call_StartForward(g_hFwd_OnClientItemWeaponInteract);
				Call_PushCell(iClient);
				Call_PushCell(hItem);
				Call_PushCell(EW_WEAPON_INTERACTION_PICKUP);
				Call_Finish();

				return;
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock void OnWeaponDrop(int iClient, int iWeapon)
{
	if (IsValidClient(iClient) && IsValidEntity(iWeapon) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iWeapon != INVALID_ENT_REFERENCE && hItem.iWeapon == iWeapon)
			{
				hItem.iClient = INVALID_ENT_REFERENCE;
				hItem.iState = EW_ENTITY_STATE_DROPPED;

				Call_StartForward(g_hFwd_OnClientItemWeaponInteract);
				Call_PushCell(iClient);
				Call_PushCell(hItem);
				Call_PushCell(EW_WEAPON_INTERACTION_DROP);
				Call_Finish();

				return;
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnGameFrame()
{
	g_flGameFrameTime = GetGameTime();
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock Action OnButtonPress(int iButton, int iClient)
{
	if (IsValidClient(iClient) && IsValidEntity(iButton) && g_hArray_Items.Length)
	{
		if (HasEntProp(iButton, Prop_Data, "m_bLocked") &&
			GetEntProp(iButton, Prop_Data, "m_bLocked"))
			return Plugin_Handled;

		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iClient != INVALID_ENT_REFERENCE && hItem.iClient == iClient)
			{
				for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
				{
					CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

					if (hItemButton.iButton != INVALID_ENT_REFERENCE && hItemButton.iButton == iButton)
					{
						if (hItemButton.hConfigButton.iType == EW_BUTTON_TYPE_USE)
						{
							if (HasEntProp(iButton, Prop_Data, "m_flWaitTime"))
							{
								if (hItemButton.flWaitTime < g_flGameFrameTime)
								{
									hItemButton.flWaitTime = g_flGameFrameTime + GetEntPropFloat(iButton, Prop_Data, "m_flWaitTime");
								}
								else return Plugin_Handled;
							}

							return ProcessButtonPress(iClient, hItem, hItemButton);
						}
					}
				}
			}
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock Action OnButtonOutput(const char[] sOutput, int iButton, int iClient, float flDelay)
{
	if (IsValidClient(iClient) && IsValidEntity(iButton) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iClient != INVALID_ENT_REFERENCE && hItem.iClient == iClient)
			{
				for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
				{
					CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

					if (hItemButton.iButton != INVALID_ENT_REFERENCE && hItemButton.iButton == iButton)
					{
						if (hItemButton.hConfigButton.iType == EW_BUTTON_TYPE_OUTPUT)
						{
							char sButtonOutput[32];
							hItemButton.hConfigButton.GetOutput(sButtonOutput, sizeof(sButtonOutput));

							if (StrEqual(sOutput, sButtonOutput, false))
							{
								return ProcessButtonPress(iClient, hItem, hItemButton);
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock Action ProcessButtonPress(int iClient, CItem hItem, CItemButton hItemButton)
{
	if (hItem.flReadyTime <= g_flGameFrameTime)
	{
		bool bResult = true;
		Call_StartForward(g_hFwd_OnClientItemButtonCanInteract);
		Call_PushCell(iClient);
		Call_PushCell(hItemButton);
		Call_Finish(bResult);

		if (bResult)
		{
			switch (hItemButton.hConfigButton.iMode)
			{
				case (EW_BUTTON_MODE_COOLDOWN):
				{
					if (hItemButton.flReadyTime < g_flGameFrameTime)
					{
						hItemButton.flReadyTime = g_flGameFrameTime + hItemButton.hConfigButton.flButtonCooldown;
					}
					else return Plugin_Handled;
				}
				case (EW_BUTTON_MODE_MAXUSES):
				{
					if (hItemButton.iCurrentUses < hItemButton.hConfigButton.iMaxUses)
					{
						hItemButton.iCurrentUses++;
					}
					else return Plugin_Handled;
				}
				case (EW_BUTTON_MODE_COOLDOWN_MAXUSES):
				{
					if (hItemButton.flReadyTime < g_flGameFrameTime && hItemButton.iCurrentUses < hItemButton.hConfigButton.iMaxUses)
					{
						hItemButton.flReadyTime = g_flGameFrameTime + hItemButton.hConfigButton.flButtonCooldown;
						hItemButton.iCurrentUses++;
					}
					else return Plugin_Handled;
				}
				case (EW_BUTTON_MODE_COOLDOWN_CHARGES):
				{
					if (hItemButton.flReadyTime < g_flGameFrameTime)
					{
						hItemButton.iCurrentUses++;

						if (hItemButton.iCurrentUses >= hItemButton.hConfigButton.iMaxUses)
						{
							hItemButton.flReadyTime = g_flGameFrameTime + hItemButton.hConfigButton.flButtonCooldown;
							hItemButton.iCurrentUses = 0;
						}
					}
					else return Plugin_Handled;
				}
			}

			hItem.flReadyTime = g_flGameFrameTime + hItemButton.hConfigButton.flItemCooldown;

			Call_StartForward(g_hFwd_OnClientItemButtonInteract);
			Call_PushCell(iClient);
			Call_PushCell(hItemButton);
			Call_Finish();

			return Plugin_Continue;
		}
		else return Plugin_Handled;
	}
	else return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock Action OnTriggerTouch(int iTrigger, int iClient)
{
	if (IsValidClient(iClient) && IsValidEntity(iTrigger) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			for (int iItemTriggerID; iItemTriggerID < hItem.hTriggers.Length; iItemTriggerID++)
			{
				CItemTrigger hItemTrigger = hItem.hTriggers.Get(iItemTriggerID);

				if (hItemTrigger.iTrigger != INVALID_ENT_REFERENCE && hItemTrigger.iTrigger == iTrigger)
				{
					if (hItemTrigger.hConfigTrigger.iType == EW_TRIGGER_TYPE_STRIP)
					{
						if (g_bIntermission)
							return Plugin_Handled;

						bool bResult = true;
						Call_StartForward(g_hFwd_OnClientItemTriggerCanInteract);
						Call_PushCell(iClient);
						Call_PushCell(hItemTrigger);
						Call_Finish(bResult);

						if (bResult)
						{
							Call_StartForward(g_hFwd_OnClientItemTriggerInteract);
							Call_PushCell(iClient);
							Call_PushCell(hItemTrigger);
							Call_Finish();

							return Plugin_Continue;
						}
						else return Plugin_Handled;
					}
				}
			}
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock Action OnWeaponTouch(int iClient, int iWeapon)
{
	if (IsValidClient(iClient) && IsValidEntity(iWeapon) && g_hArray_Items.Length)
	{
		for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
		{
			CItem hItem = g_hArray_Items.Get(iItemID);

			if (hItem.iWeapon != INVALID_ENT_REFERENCE && hItem.iWeapon == iWeapon)
			{
				if (g_bIntermission)
					return Plugin_Handled;

				bool bResult = true;
				Call_StartForward(g_hFwd_OnClientItemWeaponCanInteract);
				Call_PushCell(iClient);
				Call_PushCell(hItem);
				Call_Finish(bResult);

				if (bResult)
					return Plugin_Continue;
				else
					return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
stock bool IsValidClient(int iClient)
{
	return ((1 <= iClient <= MaxClients) && IsClientConnected(iClient));
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public any Native_LoadConfig(Handle hPlugin, int iNumParams)
{
	bool bLoopEntities = GetNativeCell(1);

	return LoadConfig(bLoopEntities);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public any Native_GetItemsArray(Handle hPlugin, int iNumParams)
{
	return g_hArray_Items;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public any Native_GetConfigsArray(Handle hPlugin, int iNumParams)
{
	return g_hArray_Configs;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public any Native_IsEntityItem(Handle hPlugin, int iNumParams)
{
	if (!g_hArray_Items.Length)
		return false;

	int iEntity = GetNativeCell(1);
	if (!IsValidEdict(iEntity) && IsValidEntity(iEntity) && g_hArray_Items.Length)
		return false;

	for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
	{
		CItem hItem = g_hArray_Items.Get(iItemID);

		if (hItem.iWeapon != INVALID_ENT_REFERENCE && hItem.iWeapon == iEntity)
			return true;

		for (int iItemButtonID; iItemButtonID < hItem.hButtons.Length; iItemButtonID++)
		{
			CItemButton hItemButton = hItem.hButtons.Get(iItemButtonID);

			if (hItemButton.iButton != INVALID_ENT_REFERENCE && hItemButton.iButton == iEntity)
				return true;
		}

		for (int iItemTriggerID; iItemTriggerID < hItem.hTriggers.Length; iItemTriggerID++)
		{
			CItemTrigger hItemTrigger = hItem.hTriggers.Get(iItemTriggerID);

			if (hItemTrigger.iTrigger != INVALID_ENT_REFERENCE && hItemTrigger.iTrigger == iEntity)
				return true;
		}
	}

	return false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public any Native_ClientHasItem(Handle hPlugin, int iNumParams)
{
	if (!g_hArray_Items.Length)
		return false;

	int iClient = GetNativeCell(1);
	if (!IsValidClient(iClient))
		return false;

	for (int iItemID; iItemID < g_hArray_Items.Length; iItemID++)
	{
		CItem hItem = g_hArray_Items.Get(iItemID);

		if (hItem.iClient != INVALID_ENT_REFERENCE && hItem.iClient == iClient)
			return true;
	}

	return false;
}
