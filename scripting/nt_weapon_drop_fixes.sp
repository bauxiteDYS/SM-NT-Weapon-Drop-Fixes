#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <entity_prop_stocks>
#include <neotokyo>

bool g_lateLoad;

float g_wepDeathOrigin[3];

public Plugin myinfo = {
    name = "NT weapon drop fixes",
    author = "bauxite",
    description = "Some prevention for weapons dropping into or under the ground",
    version = "0.3.0",
    url = "https://github.com/bauxiteDYS/SM-NT-Weapon-Drop-Fixes"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_lateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if(g_lateLoad)
	{
		for(int client = 1; client <= MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				OnClientPutInServer(client);
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	SDKHook(client, SDKHook_WeaponDrop, OnWeaponDrop);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrContains(classname, "weapon_", true) == -1)
	{
		return;
	}
	
	if(StrEqual(classname, "weapon_grenade", true)
	|| StrEqual(classname, "weapon_smokegrenade", true)
	|| StrEqual(classname, "weapon_remotedet", true))
	{
		RequestFrame(SetViewOffset, entity);
	}
}

void SetViewOffset(int entity)
{
	if(!IsValidEntity(entity))
	{
		return;
	}
	
	SetEntPropVector(entity, Prop_Data, "m_vecViewOffset", {0.0, 0.0, 1.0});
}

public Action OnWeaponDrop(int client, int weapon)
{
	if(!IsClientInGame(client) || IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	if(!IsValidEntity(weapon))
	{
		return Plugin_Continue;
	}
	
	char className[64];
	GetEntityClassname(weapon, className, sizeof(className));
	
	if(StrContains(className, "weapon_", true) != 0)
	{
		return Plugin_Continue;
	}
	
	GetClientAbsOrigin(client, g_wepDeathOrigin);
	g_wepDeathOrigin[2] += 16.0;
	RequestFrame(TeleportWeapon, weapon);
	return Plugin_Continue
}

void TeleportWeapon(int weapon)
{
	if(!IsValidEntity(weapon))
	{
		return;
	}
	
	float zero[3];
	
	TeleportEntity(weapon, g_wepDeathOrigin, zero, zero);
}
