#if defined entWatch_core_included
	#endinput
#endif

#define entWatch_core_included

#define EW_VERSION                          "4.1.0.2"   /**< The current version of entWatch */
#define EW_VERSION_CONFIG                   1           /**< The current configuration version of entWatch */

/**
 *
 */
#define EW_ENTITY_STATE_INITIAL             0   /**< Intial state of an entity */
#define EW_ENTITY_STATE_SPAWNED             1   /**< Entity has spawned and is processed */
#define EW_ENTITY_STATE_EQUIPPED            2   /**< Entity is equipped */
#define EW_ENTITY_STATE_DROPPED             3   /**< Entity is dropped */
#define EW_ENTITY_STATE_DESTROYED           4   /**< Entity is destroyed */

/**
 *
 */
#define EW_WEAPON_INTERACTION_DROP          1   /**< Item was dropped */
#define EW_WEAPON_INTERACTION_DEATH         2   /**< Item owner died */
#define EW_WEAPON_INTERACTION_PICKUP        3   /**< Item was picked up */
#define EW_WEAPON_INTERACTION_DISCONNECT    4   /**< Item owner disconnected */

/**
 *
 */
#define EW_BUTTON_TYPE_NONE                 0   /**< Button has no type */
#define EW_BUTTON_TYPE_USE                  1   /**< Button is +use activated */
#define EW_BUTTON_TYPE_OUTPUT               2   /**< Button is activated by outputs */

/**
 *
 */
#define EW_BUTTON_MODE_NONE                 0   /**< Button has no mode */
#define EW_BUTTON_MODE_COOLDOWN             1   /**< Standard cooldown */
#define EW_BUTTON_MODE_MAXUSES              2   /**< Standard max uses */
#define EW_BUTTON_MODE_COOLDOWN_MAXUSES     3   /**< Cooldown after each use, max uses */
#define EW_BUTTON_MODE_COOLDOWN_CHARGES     4   /**< Cooldown after multiple uses */

/**
 *
 */
#define EW_TRIGGER_TYPE_NONE                0   /**< Trigger has no type */
#define EW_TRIGGER_TYPE_STRIP               1   /**< Trigger is made to strip clients */
#define EW_TRIGGER_TYPE_BUTTON              2   /**< Not yet implemented: Trigger is made to activate the item */
#define EW_TRIGGER_TYPE_HURT                3   /**< Not yet implemented: Trigger is made to hurt clients */

/**
 *
 */
#include "../classes/CConfig.inc"
#include "../classes/CConfigButton.inc"
#include "../classes/CConfigTrigger.inc"

/**
 *
 */
#include "../classes/CItem.inc"
#include "../classes/CItemButton.inc"
#include "../classes/CItemTrigger.inc"

/**
 *
 */
forward void EW_OnClientItemWeaponInteract(int iClient, CItem hItem, int iInteractionType);

/**
 *
 */
forward void EW_OnClientItemButtonInteract(int iClient, CItemButton hItemButton);

/**
 *
 */
forward void EW_OnClientItemTriggerInteract(int iClient, CItemTrigger hItemTrigger);

/**
 *
 */
forward bool EW_OnClientItemWeaponCanInteract(int iClient, CItem hItem);

/**
 *
 */
forward bool EW_OnClientItemButtonCanInteract(int iClient, CItemButton hItemButton);

/**
 *
 */
forward bool EW_OnClientItemTriggerCanInteract(int iClient, CItemTrigger hItemTrigger);

/**
 *
 */
native bool EW_LoadConfig(bool bLoopEntities = false);

/**
 *
 */
native ArrayList EW_GetItemsArray();

/**
 *
 */
native ArrayList EW_GetConfigsArray();

/**
 *
 */
native bool EW_IsEntityItem(int iEntity);

/**
 *
 */
native bool EW_ClientHasItem(int iClient);

/**
 *
 */
public SharedPlugin __pl_entWatch_core =
{
	name = "entWatch-core",
	file = "entWatch-core.smx",

	#if defined REQUIRE_PLUGIN
		required = 1
	#else
		required = 0
	#endif
};

#if !defined REQUIRE_PLUGIN
	public void __pl_entWatch_core_SetNTVOptional()
	{
		MarkNativeAsOptional("EW_LoadConfig");

		MarkNativeAsOptional("EW_GetItemsArray");
		MarkNativeAsOptional("EW_GetConfigsArray");

		MarkNativeAsOptional("EW_IsEntityItem");
		MarkNativeAsOptional("EW_ClientHasItem");
	}
#endif
