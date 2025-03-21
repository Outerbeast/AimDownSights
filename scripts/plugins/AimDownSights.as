/* AimDownSights - Addon for more realistic scopes
    Adds more realistic aiming for weapons that support zooming such as
    SMG, Crossbow, Sniper Rifle
- Outerbeast
*/
dictionary dictScopes, dictNoScope;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
    g_Module.ScriptInfo.SetContactInfo( "https://github.com/Outerbeast" );
    
    g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, Zoom );
    g_Hooks.RegisterHook( Hooks::Weapon::WeaponReload, Reload );
    g_Scheduler.SetInterval( "UpdateViewModel", 0.5f );
}

void MapInit()
{
    GetScopeConfig();
    Precache();
}

void GetScopeConfig()
{
    dictScopes = dictNoScope = dictionary();
    File@ fileConfig = g_FileSystem.OpenFile( "scripts/plugins/store/AimDownSights.cfg", OpenFile::READ );

    if( fileConfig is null || !fileConfig.IsOpen() )
        return;

    while( !fileConfig.EOFReached() )
    {
        string strCurrentLine;
        fileConfig.ReadLine( strCurrentLine );
        strCurrentLine.Trim();

        if( strCurrentLine == "" || strCurrentLine.StartsWith( "#" ) )
            continue;

        dictScopes[strCurrentLine.Split( ":" )[0]] = strCurrentLine.Split( ":" )[1];
    }
}

void Precache()
{
    array<string> STR_SCOPES = dictScopes.getKeys();

    for( uint i = 0; i < STR_SCOPES.length(); i++ )
        g_Game.PrecacheModel( string( dictScopes[STR_SCOPES[i]] ) );
}

void UpdateViewModel()
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.m_hActiveItem )
            continue;

        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );

        if( pWeapon is null || !dictScopes.exists( pWeapon.GetClassname() ) )
            continue;

        if( !pPlayer.IsAlive() && pPlayer.m_iHideHUD & HIDEHUD_CROSSHAIR != 0 )
            pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;

        if( !pWeapon.m_fInZoom && string( dictNoScope[pWeapon.GetClassname()] ) == "" )
            dictNoScope[pWeapon.GetClassname()] = string( pPlayer.pev.viewmodel );
    }
}

HookReturnCode Zoom(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
{
    if( pPlayer is null || pWeapon is null || pWeapon.m_fInReload || !dictScopes.exists( pWeapon.GetClassname() ) )
        return HOOK_CONTINUE;

    pPlayer.pev.viewmodel = pWeapon.m_fInZoom ? string( dictScopes[pWeapon.GetClassname()] ) : string( dictNoScope[pWeapon.GetClassname()] );

    if( pWeapon.m_fInZoom )
        pPlayer.m_iHideHUD |= HIDEHUD_CROSSHAIR;
    else
        pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;
    
    return HOOK_CONTINUE;
}

HookReturnCode Reload(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
{
    if( pPlayer is null || pWeapon is null || !dictScopes.exists( pWeapon.GetClassname() ) )
        return HOOK_CONTINUE;
    
    if( string( pPlayer.pev.viewmodel ) == string( dictScopes[pWeapon.GetClassname()] ) )
    {
        pPlayer.pev.viewmodel = string( dictNoScope[pWeapon.GetClassname()] );
        pPlayer.m_iHideHUD &= ~HIDEHUD_CROSSHAIR;
    }

    return HOOK_CONTINUE;
}
