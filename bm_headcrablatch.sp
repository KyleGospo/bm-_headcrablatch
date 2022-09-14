// =================================
// BLACK MESA HEADCRAB LATCH RESTORATION
// =================================

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name =			"[Black Mesa] Headcrab Latch Restoration",
	author =		"1/4 Life",
	description =	"Adds a custom SourceMod-based command to restore headcrabs latching to the player and make the chance of it happening customizable via ConVars. Big thanks to KyuuGryphon for inspiring this plugin.",
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
	h_EnableOutput = CreateConVar("bm_headcrablatch_enableprint", "0", "Enable printing information to the console.");
	h_HeadcrabRemoveDamage = CreateConVar("bm_headcrablatch_cancel_damage", "1", "If enabled, in the event of a latched headcrab the melee damage is canceled.");
	h_HeadcrabLatchChanceEasy = CreateConVar("bm_headcrablatch_chance_easy", "3", "Chance for headcrabs to latch to the player's head on easy difficulty.", FCVAR_GAMEDLL, true, 0.0, true, 100.0);
	h_HeadcrabLatchChanceNormal = CreateConVar("bm_headcrablatch_chance_normal", "5", "Chance for headcrabs to latch to the player's head on normal difficulty.", FCVAR_GAMEDLL, true, 0.0, true, 100.0);
	h_HeadcrabLatchChanceHard = CreateConVar("bm_headcrablatch_chance_hard", "8", "Chance for headcrabs to latch to the player's head on hard difficulty.", FCVAR_GAMEDLL, true, 0.0, true, 100.0);

	h_cvSkill = FindConVar("skill");

	HookEvent("player_activate", PlayerActivate, EventHookMode_Post);
	AddNormalSoundHook(NormalSoundHook);
}

public OnMapStart()
{
	// Downloads table for servers
	AddFileToDownloadsTable("materials/dev/hc_blur.vmt");
	AddFileToDownloadsTable("materials/dev/hc_blur.vtf");
	AddFileToDownloadsTable("sound/weapons/headcrab/latch_attack2.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/latch_attack3.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/latch_pain3.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/latch1.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/latch2.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/body_medium_impact_hard1.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/body_medium_impact_hard2.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/body_medium_impact_hard3.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/body_medium_impact_hard4.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/body_medium_impact_hard5.wav");
	AddFileToDownloadsTable("sound/weapons/headcrab/body_medium_impact_hard6.wav");

	// Fix the headcrab texture no longer being preloaded in BM: Definitive
	PrecacheDecal("dev/hc_blur", true);

	// Precache our new sounds
	PrecacheSound("weapons/headcrab/latch_attack2.wav", true);
	PrecacheSound("weapons/headcrab/latch_attack3.wav", true);
	PrecacheSound("weapons/headcrab/latch_pain3.wav", true);
	PrecacheSound("weapons/headcrab/latch1.wav", true);
	PrecacheSound("weapons/headcrab/latch2.wav", true);
	PrecacheSound("weapons/headcrab/body_medium_impact_hard1.wav", true);
	PrecacheSound("weapons/headcrab/body_medium_impact_hard2.wav", true);
	PrecacheSound("weapons/headcrab/body_medium_impact_hard3.wav", true);
	PrecacheSound("weapons/headcrab/body_medium_impact_hard4.wav", true);
	PrecacheSound("weapons/headcrab/body_medium_impact_hard5.wav", true);
	PrecacheSound("weapons/headcrab/body_medium_impact_hard6.wav", true);

	AutoExecConfig(true, "bm_headcrablatch");
}

public Action PlayerActivate(Event event, const char[] name, bool dontBroadcast)
{
	SDKHook(GetClientOfUserId(GetEventInt(event, "userid")), SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);

	return Plugin_Continue;
}

public Action:NormalSoundHook(clients[64], &numClients, String:sSample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(IsValidEntity(entity))
	{
		char strSoundEntityClassname[32];
		GetEntityClassname(entity, strSoundEntityClassname, sizeof(strSoundEntityClassname));
		if(StrEqual(strSoundEntityClassname, "player"))
		{
			if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Playing sound: %s", sSample);

			// Replace audio used by BM so it can be different for NPC/Latch.
			// Thanks to Ari Bloss for the edited audio files.
			if(strncmp(sSample, "npc/headcrab/attack2.wav", 24) == 0) 
			{
				sSample = "weapons/headcrab/latch_attack2.wav";
				level = SNDLEVEL_SCREAMING;
				if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Sound replaced with: %s", sSample);
			}
			else if(strncmp(sSample, "npc/headcrab/attack3.wav", 24) == 0)
			{
				sSample = "weapons/headcrab/latch_attack3.wav";
				level = SNDLEVEL_SCREAMING;
				if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Sound replaced with: %s", sSample);
			}
			else if(strncmp(sSample, "npc/headcrab/pain3.wav", 22) == 0)
			{
				sSample = "weapons/headcrab/latch_pain3.wav";
				level = SNDLEVEL_SCREAMING;
				if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Sound replaced with: %s", sSample);
			}
		}
	}

	return Plugin_Continue; 
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	// Don't do anything if we don't have a valid victim and inflictor.
	if(!IsValidEntity(victim) || !IsValidEntity(inflictor))
	{
		return Plugin_Continue; 
	}

	char strInflictorClassname[32];
	GetEdictClassname(inflictor, strInflictorClassname, sizeof(strInflictorClassname));
	char strWeaponClassname[32];
	int iPlayer = -1;

	// Get the victim's current weapon.
	if(MaxClients == 1)
	{
		// Singleplayer workaround for GetClientWeapon. Thanks KyuuGryphon!
		int iWeaponIndex = -1;
		int iMapEntCount = GetMaxEntities();
		iMapEntCount = iMapEntCount*4;
		char strEdictClassname[32];

		for (new i = 1; i <= iMapEntCount; i++)
		{
			if(IsValidEntity(i))
			{
				GetEntityClassname(i, strEdictClassname, sizeof(strEdictClassname))
				if(StrEqual(strEdictClassname, "player"))
				{
					iPlayer = i;
				}
			}
		}

		if (IsValidEntity(iPlayer))
		{
			iWeaponIndex = GetEntPropEnt(iPlayer, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(iWeaponIndex))
			{
				GetEntityClassname(iWeaponIndex, strWeaponClassname, sizeof(strWeaponClassname));
			}
		}
	}
	else
	{
		GetClientWeapon(victim, strWeaponClassname, sizeof(strWeaponClassname));
	}

	if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Player damaged by entity with class: %s | Weapon being held: %s", strInflictorClassname, strWeaponClassname);

	// Only do our logic if we're damaged by a headcrab and aren't already latched onto.
	if(!StrEqual(strWeaponClassname, "weapon_headcrab") && StrEqual(strInflictorClassname, "npc_headcrab"))
	{
		if(GetRandomInt(1, 100) <= GetHeadcrabLatchChance())
		{
			// Remove the Headcrab NPC
			AcceptEntityInput(inflictor, "Kill");

			// Give the attacked player the weapon_headcrab item.
			// Singleplayer workaround for GivePlayerItem, thanks bAddie!
			if(MaxClients == 1)
			{
				int iWeaponHeadcrab = CreateEntityByName("weapon_headcrab");
				if(IsValidEntity(iPlayer) && IsValidEntity(iWeaponHeadcrab) && DispatchSpawn(iWeaponHeadcrab))
				{
					float playerPos[3];
					GetEntPropVector(iPlayer, Prop_Send, "m_vecOrigin", playerPos);
					TeleportEntity(iWeaponHeadcrab, playerPos);
					AcceptEntityInput(iWeaponHeadcrab, "Use", iPlayer);
					PlayLatchSound(iPlayer);
				}
			}
			else
			{
				GivePlayerItem(victim, "weapon_headcrab");
				PlayLatchSound(victim);
			}

			// Cancel the normal damage this attack would have done if desired.
			if(GetConVarBool(h_HeadcrabRemoveDamage))
			{
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue; 
}

public PlayLatchSound(int victim)
{
	char strSample[64];

	// Happy Headcrab Noise
	Format(strSample, sizeof(strSample), "weapons/headcrab/latch%i.wav", GetRandomInt(1,2));
	if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Playing latch sound: %s", strSample);
	EmitSoundToAll(strSample, victim, SNDCHAN_AUTO, SNDLEVEL_SCREAMING);

	// Impact sound
	Format(strSample, sizeof(strSample), "weapons/headcrab/body_medium_impact_hard%i.wav", GetRandomInt(1,6));
	if(GetConVarBool(h_EnableOutput)) PrintToServer("[BM Headcrab Latch] Playing latch sound: %s", strSample);
	EmitSoundToAll(strSample, victim, SNDCHAN_BODY, SNDLEVEL_NORMAL);
}

public GetHeadcrabLatchChance()
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

