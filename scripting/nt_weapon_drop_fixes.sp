#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <entity_prop_stocks>
#include <neotokyo>

bool g_lateLoad;

float g_ghostSpeed[] = {0.0, 0.0, 32.0};
float g_ghostDeathOrigin[3];

public Plugin myinfo = {
    name = "NT weapon drop fixes",
    author = "bauxite",
    description = "Some fixes for nades, det and ghost dropping into or under the ground",
    version = "0.1.0",
    url = ""
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
	
	if(!StrEqual(className, "weapon_ghost", true))
	{
		return Plugin_Continue;
	}
	
	GetClientAbsOrigin(client, g_ghostDeathOrigin);
	g_ghostDeathOrigin[2] += 16.0;
	RequestFrame(TeleportGhost, weapon);

	return Plugin_Continue
}

void TeleportGhost(int ghost)
{
	if(!IsValidEntity(ghost))
	{
		return;
	}
	
	TeleportEntity(ghost, g_ghostDeathOrigin, NULL_VECTOR, g_ghostSpeed);
}