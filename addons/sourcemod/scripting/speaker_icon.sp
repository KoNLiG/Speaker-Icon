#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

enum struct Player
{
    // This player slot index.
    int index;

    // Speaker icon entity reference.
    int speaker_icon_ent_ref;
    //================================//
    void Init(int client)
    {
        this.index = client;
        this.speaker_icon_ent_ref = INVALID_ENT_REFERENCE;
    }

    void Close()
    {
        this.index = 0;
        this.speaker_icon_ent_ref = 0;
    }

    void CreateSpeakerIcon()
    {
        // No need to create a second icon if one already exists.
        if (this.speaker_icon_ent_ref != INVALID_ENT_REFERENCE)
        {
            return;
        }

        int env_sprite = CreateEntityByName("env_sprite");
        if (env_sprite == -1)
        {
            return;
        }

        // Adjust icon origin.
        float origin[3];
        GetClientEyePosition(this.index, origin);
        origin[2] += 20.0;

        DispatchKeyValueVector(env_sprite, "origin", origin);

        DispatchKeyValue(env_sprite, "model", "materials/sprites/sg_micicon64.vmt");
        DispatchSpawn(env_sprite);

        // Parent the sprite to the speaker entity.
        SetVariantString("!activator");
        AcceptEntityInput(env_sprite, "SetParent", this.index, env_sprite);

        this.speaker_icon_ent_ref = EntIndexToEntRef(env_sprite);
    }

    void RemoveSpeakerIcon()
    {
        if (this.speaker_icon_ent_ref == INVALID_ENT_REFERENCE)
        {
            return;
        }

        int entity = EntRefToEntIndex(this.speaker_icon_ent_ref);
        if (entity != -1)
        {
            PrintToConsoleAll("[RemoveSpeakerIcon] %d", this.index);

            RemoveEdict(entity);
        }

        this.speaker_icon_ent_ref = INVALID_ENT_REFERENCE;
    }
}

Player g_Players[MAXPLAYERS + 1];

bool g_Lateload;

public Plugin myinfo =
{
    name = "Speaker Icon",
    author = "KoNLiG",
    description = "Creates a speaker icon above a player's head on voice activity.",
    version = "1.0",
    url = "https://steamcommunity.com/id/KoNLiG/ || KoNLiG#6417"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_Lateload = late;
    return APLRes_Success;
}

// Hook events.
public void OnPluginStart()
{
    if (g_Lateload)
    {
        Lateload();
    }

    HookEvent("player_death", Event_PlayerDeath);
}

// Add addons to download table.
public void OnMapStart()
{
    AddFileToDownloadsTable("materials/sprites/sg_micicon64.vmt");
    AddFileToDownloadsTable("materials/sprites/sg_micicon64.vtf");

    PrecacheModel("materials/sprites/sg_micicon64.vmt");
}

public void OnClientPutInServer(int client)
{
    g_Players[client].Init(client);
}

public void OnClientDisconnect(int client)
{
    g_Players[client].Close();
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client)
    {
        g_Players[client].RemoveSpeakerIcon();
    }
}

public void OnClientSpeaking(int client)
{
    if (IsPlayerAlive(client))
    {
        g_Players[client].CreateSpeakerIcon();
    }
}

public void OnClientSpeakingEnd(int client)
{
    g_Players[client].RemoveSpeakerIcon();
}

void Lateload()
{
    for (int current_client = 1; current_client <= MaxClients; current_client++)
    {
        if (IsClientInGame(current_client))
        {
            OnClientPutInServer(current_client);
        }
    }
}