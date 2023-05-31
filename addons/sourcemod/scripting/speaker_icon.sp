#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

int g_unClientSprite[MAXPLAYERS+1]={INVALID_ENT_REFERENCE,...};

public Plugin myinfo =
{
    name = "Speaker Icon",
    author = "Franc1sco, rewrite by KoNLiG",
    description = "",
    version = "3.1",
    url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapStart()
{
    AddFileToDownloadsTable("materials/sprites/sg_micicon64.vmt");
    AddFileToDownloadsTable("materials/sprites/sg_micicon64.vtf");

    PrecacheModel("materials/sprites/sg_micicon64.vmt");
}

public void OnClientConnected(int client)
{
    g_unClientSprite[client]=INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect(int client)
{
    ResetSprite(client);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(!client || !IsClientInGame(client))
        return;

    ResetSprite(client);
}

void ResetSprite(int client)
{
    if(g_unClientSprite[client] == INVALID_ENT_REFERENCE)
        return;

    int m_unEnt = EntRefToEntIndex(g_unClientSprite[client]);
    g_unClientSprite[client] = INVALID_ENT_REFERENCE;
    if(m_unEnt == INVALID_ENT_REFERENCE)
        return;

    AcceptEntityInput(m_unEnt, "Kill");
}

void CreateSprite(int client)
{
    if(g_unClientSprite[client] != INVALID_ENT_REFERENCE)
        return;

    int m_unEnt = CreateEntityByName("env_sprite");
    if (IsValidEntity(m_unEnt))
    {
        DispatchKeyValue(m_unEnt, "model", "materials/sprites/sg_micicon64.vmt");
        DispatchSpawn(m_unEnt);

        float m_flPosition[3];
        GetClientEyePosition(client, m_flPosition);
        m_flPosition[2] += 20.0;

        TeleportEntity(m_unEnt, m_flPosition, NULL_VECTOR, NULL_VECTOR);

        SetVariantString("!activator");
        AcceptEntityInput(m_unEnt, "SetParent", client, m_unEnt, 0);

        SetEntPropEnt(m_unEnt, Prop_Data, "m_hOwnerEntity", client);

        g_unClientSprite[client] = EntIndexToEntRef(m_unEnt);

        SetEdictFlags(m_unEnt, 0);
        SetEdictFlags(m_unEnt, FL_EDICT_FULLCHECK);

        SDKHook(m_unEnt, SDKHook_SetTransmit, OnTrasnmit);
    }
}

Action OnTrasnmit(int entity, int client)
{
    int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
    if (owner == client || GetListenOverride(client, owner) == Listen_No || IsClientMuted(client, owner))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public void OnClientSpeakingEx(int client)
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    CreateSprite(client);
}

public void OnClientSpeakingEnd(int client)
{
    ResetSprite(client);
}