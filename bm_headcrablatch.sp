// =================================
// BLACK MESA HEADCRAB LATCH FIX
// =================================

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name =			"[Black Mesa] Headcrab Latch",
	author =		"1/4 Life",
	description =	"Adds a custom SourceMod-based command to allow the chance for headcrabs to latch to the player once more. Big thanks to KyuuGryphon for inspiring this plugin.",
	version =		PLUGIN_VERSION,
	url =			""
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


// ==================================

new Handle:h_EnableOutput

new Handle:h_HeadcrabRemoveDamage
new Handle:h_HeadcrabLatchChanceEasy
new Handle:h_HeadcrabLatchChanceNormal
new Handle:h_HeadcrabLatchChanceHard

ConVar h_cvSkill;

// ==================================

public void OnPluginStart()
{
	if (MaxClients > 1)
	{
		PrintToServer("[BM Headcrab Latch] This plugin has not been tested in multiplayer! There may be unexpected issues.");
	}

	h_EnableOutput = CreateConVar("bm_headcrablatch_enableprint", "0", "Enable printing information to the console.");
	h_HeadcrabRemoveDamage = CreateConVar("bm_headcrablatch_cancel_damage", "1", "If enabled, in the event of a latched headcrab the melee damage is canceled.");
	h_HeadcrabLatchChanceEasy = CreateConVar("bm_headcrablatch_chance_easy", "3", "Chance for headcrabs to latch to the player's head on easy difficulty.", FCVAR_GAMEDLL, true, 0.0, true, 100.0);
	h_HeadcrabLatchChanceNormal = CreateConVar("bm_headcrablatch_chance_normal", "5", "Chance for headcrabs to latch to the player's head on normal difficulty.", FCVAR_GAMEDLL, true, 0.0, true, 100.0);
	h_HeadcrabLatchChanceHard = CreateConVar("bm_headcrablatch_chance_hard", "8", "Chance for headcrabs to latch to the player's head on hard difficulty.", FCVAR_GAMEDLL, true, 0.0, true, 100.0);

	h_cvSkill = FindConVar("skill");

	/*for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}*/

	HookEvent("player_activate", PlayerActivate);
}

public OnMapStart()
{
	// Fix the headcrab texture no longer being preloaded in BM: Definitive
	PrecacheDecal("dev/hc_blur", true);

	AutoExecConfig(true, "bm_headcrablatch");
}

/*public OnClientPutInServer(client)
{
	// Hook into the player damage event so we can handle giving them the weapon_headcrab item when applicable.
	SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive)
}*/

public PlayerActivate(Handle:Event, const String:Name[], bool:Broadcast)
{
	decl client;
	client = GetClientOfUserId(GetEventInt(Event, "userid"));

	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageAlive)
}

public Action:OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	decl String:inflictorClass[35];
	decl String:playerWeaponClass[35];
	GetEdictClassname(inflictor, inflictorClass, sizeof(inflictorClass));
	GetClientWeapon(victim, playerWeaponClass, sizeof(playerWeaponClass));

	if (GetConVarBool(h_EnableOutput))
	{
		PrintToServer("[BM Headcrab Latch] Player damaged by entity with class: %s | Current Weapon: %s", inflictorClass, playerWeaponClass);
	}

	// Only do our logic if we're damaged by a headcrab and aren't already latched onto.
	if (!StrEqual(playerWeaponClass, "weapon_headcrab") && StrEqual(inflictorClass, "npc_headcrab"))
	{
		// Check our chance value. Optionally cancel the damage and latch the headcrab on.
		if(GetRandomInt(1, 100) <= GetHeadcrabLatchChance())
		{
			// Remove the Headcrab NPC and give the player the latched headcrab weapon.
			AcceptEntityInput(inflictor, "kill");
			GivePlayerItem(victim, "weapon_headcrab");

			// Cancel the normal damage this attack would have done if desired.
			if(GetConVarBool(h_HeadcrabRemoveDamage))
			{
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue; 
}

GetHeadcrabLatchChance()
{
	switch(GetConVarInt(h_cvSkill))
	{
		case 1:
		{
			return GetConVarInt(h_HeadcrabLatchChanceEasy);
		}
		case 2:
		{
			return GetConVarInt(h_HeadcrabLatchChanceNormal);
		}
		case 3:
		{
			return GetConVarInt(h_HeadcrabLatchChanceHard);
		}
	}
}
