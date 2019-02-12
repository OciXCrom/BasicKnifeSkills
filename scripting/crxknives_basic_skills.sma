#include <amxmodx>
#include <crxknives>
#include <cstrike>
#include <fun>
#include <hamsandwich>

#if !defined MAX_PLAYERS
const MAX_PLAYERS = 32
#endif

new const PLUGIN_VERSION[]           = "1.0"

const NOT_SET                        = -1
const Float:NOT_SET_F                = -1.0
const Float:DEFAULT_GRAVITY_I        = 800.0
const Float:DEFAULT_GRAVITY_F        = 1.0
const DEFAULT_MAX_HEALTH             = 100
const DEFAULT_MAX_ARMOR              = 100
const DEFAULT_MAX_MONEY              = 16000
const DEFAULT_GLOW_AMOUNT            = 40

new const ATTRIBUTE_GRAVITY[]        = "GRAVITY"
new const ATTRIBUTE_SPEED[]          = "SPEED"
new const ATTRIBUTE_DAMAGE[]         = "DAMAGE"
new const ATTRIBUTE_SILENT_STEPS[]   = "SILENT_STEPS"
new const ATTRIBUTE_HEALTH_ON_KILL[] = "HEALTH_ON_KILL"
new const ATTRIBUTE_ARMOR_ON_KILL[]  = "ARMOR_ON_KILL"
new const ATTRIBUTE_MONEY_ON_KILL[]  = "MONEY_ON_KILL"
new const ATTRIBUTE_GLOW[]           = "GLOW"

enum Glow         { bool:is_set, fx, r, g, b, render, amount }
enum HealthOnKill { health_on_kill, max_health }
enum ArmorOnKill  { armor_on_kill, max_armor }
enum MoneyOnKill  { money_on_kill, max_money }

new g_iGravity              [MAX_PLAYERS + 1],
    Float:g_fSpeed          [MAX_PLAYERS + 1],
    g_szDamage              [MAX_PLAYERS + 1][8],
    bool:g_bSilentSteps     [MAX_PLAYERS + 1],
    g_eHealthOnKill         [MAX_PLAYERS + 1][HealthOnKill],
    g_eArmorOnKill          [MAX_PLAYERS + 1][ArmorOnKill],
    g_eMoneyOnKill          [MAX_PLAYERS + 1][MoneyOnKill],
    g_eGlow                 [MAX_PLAYERS + 1][Glow],
    bool:g_bKnifeOnlySkills

public plugin_init()
{
    register_plugin("Basic Skills", PLUGIN_VERSION, "OciXCrom")
    register_cvar("CRXBasicSkills", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
    register_event("DeathMsg", "OnPlayerKilled", "a")
    register_event("CurWeapon", "OnChangeWeapon", "be", "1=1")
    RegisterHam(Ham_TakeDamage, "player", "PreTakeDamage", 0)
}

public plugin_cfg()
{
    g_bKnifeOnlySkills = get_cvar_num("km_knife_only_skills") != 0
}

public crxknives_knife_updated(id, iKnife, bool:bOnConnect)
{
    if(bOnConnect)
    {
        g_iGravity[id]                      = NOT_SET
        g_fSpeed[id]                        = NOT_SET_F
        g_szDamage[id][0]                   = EOS
        g_bSilentSteps[id]                  = false
        g_eHealthOnKill[id][health_on_kill] = NOT_SET
        g_eArmorOnKill[id][armor_on_kill]   = NOT_SET
        g_eMoneyOnKill[id][money_on_kill]   = NOT_SET
        g_eGlow[id][is_set]                 = false
        return
    }

    static szValue[CRXKNIVES_MAX_ATTRIBUTE_LENGTH], szTemp[6][8], bool:bConnected, iValue
    bConnected = is_user_connected(id) != 0

    if(crxknives_get_attribute_int(id, ATTRIBUTE_GRAVITY, iValue))
    {
        g_iGravity[id] = iValue
    }
    else if(g_iGravity[id] != NOT_SET)
    {
        g_iGravity[id] = NOT_SET

        if(bConnected)
        {
            set_user_gravity(id)
        }
    }

    if(crxknives_get_attribute_int(id, ATTRIBUTE_SPEED, iValue))
    {
        g_fSpeed[id] = float(iValue)
    }
    else if(g_fSpeed[id] != NOT_SET_F)
    {
        g_fSpeed[id] = NOT_SET_F

        if(bConnected)
        {
            reset_maxspeed(id)
        }
    }

    if(!crxknives_get_attribute_str(id, ATTRIBUTE_DAMAGE, g_szDamage[id], charsmax(g_szDamage[])))
    {
        g_szDamage[id][0] = EOS
    }

    if(crxknives_get_attribute_int(id, ATTRIBUTE_SILENT_STEPS, iValue) && iValue == 1)
    {
        g_bSilentSteps[id] = true
    }
    else if(g_bSilentSteps[id])
    {
        g_bSilentSteps[id] = false

        if(bConnected)
        {
            set_user_footsteps(id, 0)
        }
    }

    if(crxknives_get_attribute_str(id, ATTRIBUTE_HEALTH_ON_KILL, szValue, charsmax(szValue)))
    {
        szTemp[1][0] = EOS
        parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]))
        g_eHealthOnKill[id][health_on_kill] = str_to_num(szTemp[0])
        g_eHealthOnKill[id][max_health]     = szTemp[1][0] ? str_to_num(szTemp[1]) : DEFAULT_MAX_HEALTH
    }
    else
    {
        g_eHealthOnKill[id][health_on_kill] = NOT_SET
    }

    if(crxknives_get_attribute_str(id, ATTRIBUTE_ARMOR_ON_KILL, szValue, charsmax(szValue)))
    {
        szTemp[1][0] = EOS
        parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]))
        g_eArmorOnKill[id][armor_on_kill] = str_to_num(szTemp[0])
        g_eArmorOnKill[id][max_armor]     = szTemp[1][0] ? str_to_num(szTemp[1]) : DEFAULT_MAX_ARMOR
    }
    else
    {
        g_eArmorOnKill[id][armor_on_kill] = NOT_SET
    }

    if(crxknives_get_attribute_str(id, ATTRIBUTE_MONEY_ON_KILL, szValue, charsmax(szValue)))
    {
        szTemp[1][0] = EOS
        parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]))
        g_eMoneyOnKill[id][money_on_kill] = str_to_num(szTemp[0])
        g_eMoneyOnKill[id][max_money]     = szTemp[1][0] ? str_to_num(szTemp[1]) : DEFAULT_MAX_MONEY
    }
    else
    {
        g_eMoneyOnKill[id][money_on_kill] = NOT_SET
    }

    if(crxknives_get_attribute_str(id, ATTRIBUTE_GLOW, szValue, charsmax(szValue)))
    {
        for(new i; i < sizeof(szTemp); i++)
        {
            szTemp[i][0] = EOS
        }

        parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]),\
                       szTemp[3], charsmax(szTemp[]), szTemp[4], charsmax(szTemp[]), szTemp[5], charsmax(szTemp[]))

        g_eGlow[id][is_set] = true
        g_eGlow[id][r]      = str_to_num(szTemp[0])
        g_eGlow[id][g]      = str_to_num(szTemp[1])
        g_eGlow[id][b]      = str_to_num(szTemp[2])
        g_eGlow[id][amount] = szTemp[3][0] ? str_to_num(szTemp[3]) : DEFAULT_GLOW_AMOUNT
        g_eGlow[id][fx]     = szTemp[4][0] ? str_to_num(szTemp[4]) : kRenderFxGlowShell
        g_eGlow[id][render] = str_to_num(szTemp[5])
    }
    else
    {
        g_eGlow[id][is_set] = false

        if(bConnected)
        {
            set_user_rendering(id)
        }
    }

    if(is_user_alive(id))
    {
        OnChangeWeapon(id)
    }
}

public OnPlayerKilled()
{
    new iAttacker = read_data(1), iVictim = read_data(2)

    if(!is_user_connected(iAttacker) || iAttacker == iVictim || !can_use_skill(iAttacker))
        return

    if(g_eHealthOnKill[iAttacker][health_on_kill] != NOT_SET)
    {
        set_user_health(iAttacker, clamp(get_user_health(iAttacker) + g_eHealthOnKill[iAttacker][health_on_kill], .max = g_eHealthOnKill[iAttacker][max_health]))
    }

    if(g_eArmorOnKill[iAttacker][armor_on_kill] != NOT_SET)
    {
        set_user_armor(iAttacker, clamp(get_user_armor(iAttacker) + g_eArmorOnKill[iAttacker][armor_on_kill], .max = g_eArmorOnKill[iAttacker][max_armor]))
    }

    if(g_eMoneyOnKill[iAttacker][money_on_kill] != NOT_SET)
    {
        cs_set_user_money(iAttacker, clamp(cs_get_user_money(iAttacker) + g_eMoneyOnKill[iAttacker][money_on_kill], .max = g_eMoneyOnKill[iAttacker][max_money]))
    }
}

public OnChangeWeapon(id)
{
    new bool:bCanUseSkill = can_use_skill(id)

    if(g_iGravity[id] != NOT_SET)
    {
        set_user_gravity(id, bCanUseSkill ? (float(g_iGravity[id]) / DEFAULT_GRAVITY_I) : DEFAULT_GRAVITY_F)
    }

    if(g_fSpeed[id] != NOT_SET_F)
    {
        if(bCanUseSkill)
        {
            set_user_maxspeed(id, g_fSpeed[id])
        }
        else
        {
            reset_maxspeed(id)
        }
    }

    if(g_bSilentSteps[id])
    {
        set_user_footsteps(id, bCanUseSkill ? 1 : 0)
    }

    if(g_eGlow[id][is_set])
    {
        if(bCanUseSkill)
        {
            set_user_rendering(id, g_eGlow[id][fx], g_eGlow[id][r], g_eGlow[id][g], g_eGlow[id][b], g_eGlow[id][render], g_eGlow[id][amount])
        }
        else
        {
            set_user_rendering(id)
        }
    }
}

public PreTakeDamage(iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits)
{
    if(!is_user_alive(iAttacker) || !g_szDamage[iAttacker][0] || (g_bKnifeOnlySkills && ((get_user_weapon(iAttacker) != CSW_KNIFE) || iAttacker != iInflictor)))
        return

    SetHamParamFloat(4, math_add_f(fDamage, g_szDamage[iAttacker]))
}

reset_maxspeed(id)
{
    #if defined Ham_CS_Player_ResetMaxSpeed
    ExecuteHam(Ham_CS_Player_ResetMaxSpeed, id)
    #else
    static const Float:fDefaultSpeed = 250.0
    set_user_maxspeed(id, fDefaultSpeed)
    #endif
}

bool:can_use_skill(id)
{
    return !g_bKnifeOnlySkills || (get_user_weapon(id) == CSW_KNIFE)
}

Float:math_add_f(Float:fNum, const szMath[])
{
    static szNewMath[16], Float:fMath, bool:bPercent, cOperator

    copy(szNewMath, charsmax(szNewMath), szMath)
    bPercent = szNewMath[strlen(szNewMath) - 1] == '%'
    cOperator = szNewMath[0]

    if(!isdigit(szNewMath[0]))
        szNewMath[0] = ' '

    if(bPercent)
        replace(szNewMath, charsmax(szNewMath), "%", "")

    trim(szNewMath)
    fMath = str_to_float(szNewMath)

    if(bPercent)
        fMath *= fNum / 100

    switch(cOperator)
    {
        case '+': fNum += fMath
        case '-': fNum -= fMath
        case '/': fNum /= fMath
        case '*': fNum *= fMath
        default: fNum = fMath
    }

    return fNum
}