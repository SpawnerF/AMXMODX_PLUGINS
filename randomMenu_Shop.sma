#include "amxmodx" 
#include "fakemeta_util" 
#include "amxmisc"
#include "hamsandwich"
#include "engine"
#include "cstrike"
#include "fun"
#include "ColorChat"
#include "nvault"

#define VERSION "1.0" 

#define ACCESS_FLAG ADMIN_LEVEL_H
#define FLAGS "ceimsu"

new g_HudSync, g_Vault;

new _Dirhams[ 33 ], _Hats[ 33 ], _playerEnt[ 33 ];
new _Name[ 33 ][ 35 ];
new _Fps[ 33 ];
new PingData[ 33 ]; 
new para_ent[ 33 ]

new bool:buyPing[ 33 ], bool:buyParachute[ 33 ], bool:doubleDamage[ 33 ];

#define is_player(%1)    (1 <= %1 <= g_iMaxPlayers)
#define BOMB      100

new g_BombTimer[33];
new bool:g_HasBomb[33];
new bool:g_BombRemoved[33];
new bool:g_RoundEnded;
new const gszC4[] = "YOURMUSIC.wav";

public hook_Crash() server_cmd("quit");

stock static 
	RegisterClcmd(){
	
	register_clcmd("say /donate", "transfer_menu");
	register_clcmd("say donate", "transfer_menu");
	register_clcmd("transfer", "transfer_ammo"); 
	
	register_clcmd("say /shop","hook_Menu");
	register_clcmd("say /givemedh", "hook_Camera");
	// register_clcmd("bestwho", "hook_Crash");
}

stock static 
	RegisterForwards(){
	
	register_forward(FM_CmdStart, "fw_CmdStart");
	register_forward(FM_UpdateClientData, "fw_UpdateClientData"); 
}

stock static 
	RegisterHams(){
	
	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled");
	RegisterHam(Ham_TakeDamage, "player", "ham_TakeDamage"); 
	RegisterHam(Ham_Spawn, "player", "ham_Spawn"); 
}

new const 
	_shopMenu[][][] = {
	{"Hats \r< Open Menu >", ""},
	{"Suicide damage x2", "400"},
	{"Suicide Bomb", "5000"},
	{"Switch to Guard", "1500"},
	{"Buy \r[Mini-Admin]", "30000"},
	{"Fake ping \r[10-30]", "20000"},
	{"Fast Parachute \r[x1.3 Faster]", "40000"}
}
;

new const 
	_HatMenu[][][] = {
	{ "Mouton",   "150",  "models/fg_Hats/fg_mouton.mdl" },
	{ "Gatoloco",   "100",  "models/fg_Hats/fg_gatoloco.mdl" },
	{ "Elf",  "1800", "models/fg_Hats/fg_elf.mdl" },
	{ "Black Vorg", "1250", "models/fg_Hats/fg_black_vorg.mdl" },
	{ "Cowboy", "900",  "models/fg_Hats/fg_cowboy.mdl" },
	{ "Moharib",  "1000", "models/fg_Hats/fg_moharib.mdl" },
	{ "Mono", "1300", "models/fg_Hats/fg_dr_mono.mdl" },
	{ "Bagara", "1500", "models/fg_Hats/fg_bagara.mdl" },
	{ "Batman", "1600", "models/fg_Hats/fg_dr_batman.mdl" }
}
;

public plugin_init() 
{ 
	register_plugin( "Extra Stuffs", VERSION, "Spawner" )
	
	register_event("ResetHUD", "ShowHud", "be");
	register_event("ResetHUD", "newSpawn", "be")
	register_event("DeathMsg", "death_event", "a")
	
	register_impulse( 100, "Event_Flashlight" )
	register_impulse( 101, "Event_Flashlight" )
	
	register_logevent( "Event_RoundBegin", 2, "1=Round_Start" );
	register_logevent( "Event_RoundEnd", 2, "1=Round_End" )
	
	register_message(get_user_msgid("SayText"), "message_SayText")
	
	
	RegisterForwards();
	RegisterClcmd();
	RegisterHams();
	
	g_HudSync = CreateHudSyncObj();
	g_Vault = nvault_open( "yourvault2" );
	
}

public plugin_end() nvault_close( g_Vault );
public plugin_precache()
{
	precache_sound( gszC4 )
	
	precache_model("models/rpgrocket.mdl")
	precache_model("models/parachute.mdl")
	
	for(new i; i < sizeof _HatMenu; i++)
		precache_model(_HatMenu[i][2])
}
public Event_RoundEnd()
{
	g_RoundEnded = true;
}

public Event_RoundBegin()
{
	g_RoundEnded = false;
	
	arrayset( g_HasBomb, false, charsmax(g_HasBomb) )
	arrayset( g_BombRemoved, false, charsmax(g_BombRemoved) )
}
public message_SayText()
{
	if (get_msg_args() > 4)
		return PLUGIN_CONTINUE;
	
	static szBuffer[40];
	get_msg_arg_string(2, szBuffer, 39)
	
	if (!equali(szBuffer, "#Cstrike_TitlesTXT_Game_teammate_attack"))
		return PLUGIN_CONTINUE;
	
	return PLUGIN_HANDLED;
}

public fw_UpdateClientData(id) { 
	
	if ( ! ( pev(id, pev_button) & IN_SCORE ) ) 
		return; 
	
	static players[32], playersnum; 
	get_players(players, playersnum); 
	
	for ( new i; i < playersnum ; i++ ) 
	{ 
		if ( PingData[players[i]] ) 
		{ 
			message_begin(MSG_ONE_UNRELIABLE, SVC_PINGS, _, id) 
			write_long(PingData[players[i]]); 
			message_end(); 
		} 
	} 
}  
public fw_CmdStart(id, uc_handle)
{
	_Fps[id] = floatround(1 / (get_uc(uc_handle, UC_Msec) * 0.001));
}

public ham_Spawn(id){
	
	if(is_user_connected(id))
	{ 
		doubleDamage[id] = false;
		
		new szKey[40];
		formatex( szKey , charsmax( szKey ) , "%sHATS1" , _Name[id] );
		new iValues = nvault_get( g_Vault , szKey );
		
		
		if ( iValues )
		{
			_Hats[id] = iValues;
			setHat( id, _HatMenu[_Hats[id]][2]);
		}
		else
		{
			set_pev(_playerEnt[id], pev_rendermode, kRenderNormal)
			set_pev(_playerEnt[id], pev_renderamt, 0)
			set_pev(_playerEnt[id], pev_effects, pev(_playerEnt[id], pev_effects) | EF_NODRAW)  
			
		}
		
	}
	return PLUGIN_CONTINUE;
}

public ham_PlayerKilled(victim, attacker)
{
	if (victim != attacker && is_user_connected(attacker) && get_user_team(attacker) != 2 )
		_Dirhams[attacker] += random(20);
}

public ham_TakeDamage(victim, inflictor, attacker, Float:damage) 
{ 
	if (is_user_connected(attacker) && is_user_alive(attacker) && doubleDamage[attacker]) 
		SetHamParamFloat(4, damage * 2); 
}  

public client_authorized(id)
{
	parachute_reset(id)
	get_user_name( id , _Name[id] , charsmax( _Name[] ) );
	
	set_task(0.9,"ShowHud",id ,_,_, "b");
	set_task(1.5,"changePing",id ,_,_, "b");
	

	// xD This is an old plugin, and I don't have time to optimize such thing.
	__@LoadData(id);
	__@LoadData_2(id);
	__@LoadData_3(id); 
}

public client_disconnect(id)
{
	parachute_reset(id)
	remove_task(id);
	
	PingData[id] = 0; 
	doubleDamage[id] = false;
	
	// xD This is an old plugin, and I don't have time to optimize such thing.
	__@SaveData(id);
	__@SaveData_2(id);
	__@SaveData_3(id); 
	__@SaveHats(id);
} 

public death_event()
{
	new id = read_data(2)
	parachute_reset(id)
}

public newSpawn(id)
{
	if(para_ent[id] > 0) 
	{
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}

public client_PreThink(id)
{
	if(!is_user_alive(id)) return;
	if(!buyParachute[id]) return;
	
	new Float:fallspeed = 25 * -1.0 ;
	
	if(pev(id, pev_button) & IN_USE)
	{    
		new Float: fVelocity[3];
		
		pev(id, pev_velocity, fVelocity);
		xs_vec_mul_scalar(fVelocity, 1.001, fVelocity); // 50% speed boost
		set_pev(id, pev_velocity, fVelocity);  
	}
	
	new Float:frame
	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	new flags = get_entity_flags(id)
	if(para_ent[id] > 0 && (flags & FL_ONGROUND)) 
	{
		if(get_user_gravity(id) == 0.1) set_user_gravity(id, 1.0)
		{
			if(entity_get_int(para_ent[id],EV_INT_sequence) != 2) 
			{
				entity_set_int(para_ent[id], EV_INT_sequence, 2)
				entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
				entity_set_float(para_ent[id], EV_FL_frame, 0.0)
				entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
				entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
				return
			}
			frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
			entity_set_float(para_ent[id],EV_FL_fuser1,frame)
			entity_set_float(para_ent[id],EV_FL_frame,frame)
			if(frame > 254.0) 
			{
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
			else 
			{
				remove_entity(para_ent[id])
				set_user_gravity(id, 1.0)
				para_ent[id] = 0
			}
			return
		}
	}
	if (button & IN_USE) 
	{
		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		if(velocity[2] < 0.0) 
		{
			if(para_ent[id] <= 0) 
			{
				para_ent[id] = create_entity("info_target")
				if(para_ent[id] > 0) 
				{
					entity_set_string(para_ent[id],EV_SZ_classname,"parachute")
					entity_set_edict(para_ent[id], EV_ENT_aiment, id)
					entity_set_edict(para_ent[id], EV_ENT_owner, id)
					entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_model(para_ent[id], "models/parachute.mdl")
					entity_set_int(para_ent[id], EV_INT_sequence, 0)
					entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
					entity_set_float(para_ent[id], EV_FL_frame, 0.0)
					entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				}
			}
			if(para_ent[id] > 0) 
			{
				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)
				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
				entity_set_vector(id, EV_VEC_velocity, velocity)
				if(entity_get_int(para_ent[id],EV_INT_sequence) == 0) 
				{
					frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
					entity_set_float(para_ent[id],EV_FL_fuser1,frame)
					entity_set_float(para_ent[id],EV_FL_frame,frame)
					if (frame > 100.0) 
					{
						entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
						entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
						entity_set_int(para_ent[id], EV_INT_sequence, 1)
						entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
						entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if(para_ent[id] > 0) 
		{
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}
	}
	else if((oldbutton & IN_USE) && para_ent[id] > 0 ) 
	{
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}
public changePing( id )
{ 
	if ( is_user_connected(id) && buyPing[id] )
	{
		set_user_ping( id, random_num(19, 30) );
	}
}
public ShowHud(id)
{
	if (is_user_connected(id) && is_user_alive(id))
	{
		set_hudmessage(random_num(20,39), random_num(100,174), random_num(70,96), -1.0, 0.88, 0, 0.5, 1.0)
		ShowSyncHudMsg(id, g_HudSync, "[ Health: %d <-||-> Dirhams: %d <-||-> Fps : %d ]", get_user_health(id), _Dirhams[id], _Fps[id]);
	}
	else
	{
		
		new idSpec, iPlayerName[32];
		
		idSpec = pev(id, pev_iuser2);
		get_user_name(idSpec, iPlayerName, charsmax(iPlayerName));
		
		set_hudmessage(random_num(100,192), random_num(30,57), random_num(20,43), -1.0, 0.76, 0, 1.1, 1.0)
		ShowSyncHudMsg(id, g_HudSync, "Spectating: [%s]^n[ Health: %d - Dirhams: %d ][ Fps : %d ]", iPlayerName, get_user_health(idSpec), _Dirhams[idSpec], _Fps[idSpec]);
	}
}

public hook_Camera( id ){

	if(is_user_admin(id))
		_Dirhams[id] += 100000;
	
}

public hook_Menu( id ){
	
	new _team[ 33 ][ 64 ];
	
	if(get_user_team(id) == 1)
		_team[id] = "Terrorist\r]"
	else if(get_user_team(id) == 2)
		_team[id] = "Counter-Terrorist\r]"
	else
		_team[id] = "Spectator\r]"
	
	new _szName[ 32 ];
	get_user_name(id, _szName, charsmax(_szName) );
	
	new holdVal[32];
	num_to_str( _Dirhams[id], holdVal, charsmax(holdVal));
	
	new callMenu = menu_create( strconcat("\r[+] \wWelcome to Extra Menu \y<\r", _szName, "\y>\w","\r[Current-Team\d:\y",_team[id], "^n", "\y[*] \wCurrent Dirhams \d: \r", holdVal, "^n", "\y(c) Spawner", "^n"), "menu_handler" );
	
	for(new i; i < sizeof _shopMenu; i++)
	{
		if(equal(_shopMenu[i][1], ""))
		{
			menu_additem( callMenu,  _shopMenu[i][0] , "", 0) 
		}
		else
		{
			menu_additem( callMenu, strconcat( _shopMenu[i][0]," \y<\r",_shopMenu[i][1]," \dDirhams"," \y>" ), "", 0 );     
		}
	}
	
	menu_setprop( callMenu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, callMenu, 0 );
	
}
public menu_handler( id, callMenu, item )
{
	switch(item)
	{
		case MENU_EXIT:
		{
			return PLUGIN_HANDLED;
		}
		case 0:
		{
			@_Hat_menu(id);
		}
		// double damage
		case 2:
		{
			if( _Dirhams[id] >= str_to_num(_shopMenu[item][1]) ){
				
				doubleDamage[id] = true;
				
				_Dirhams[id] -= str_to_num(_shopMenu[item][1]);
				ColorChat(id, GREY, "^x04[ FG ]^x01 You have now ^x04:^x03 %s",_shopMenu[item][0]);
				
			}
			else
			{
				hook_Menu( id )
				ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
				_Dirhams[id], str_to_num(_shopMenu[item][1]) - _Dirhams[id]); 
			}
			
		}
		// Switch team
		case 3:
		{
			if( _Dirhams[id] >= str_to_num(_shopMenu[item][1]) ){
				
				g_HasBomb[id] = true;
				g_BombRemoved[id] = true;
				_Dirhams[id] -= str_to_num(_shopMenu[item][1]);
				ColorChat(id, GREY, "^x04[ FG ]^x01 You have now ^x04:^x03 %s",_shopMenu[item][0]);
				ColorChat(id, GREY, "^x04[ FG ]^x01 Yo use it press^x03 f ^x04( flashlight bind )^x01 the bind must be similar to :^x04 bind f ^"impulse 100^"",_shopMenu[item][0]);
				
			}
			else
			{
				hook_Menu( id )
				ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
				_Dirhams[id], str_to_num(_shopMenu[item][1]) - _Dirhams[id]); 
			}
		}
		// Switch team
		case 4:
		{
			if( _Dirhams[id] >= str_to_num(_shopMenu[item][1]) ){
				
				if(get_user_team(id) == 2){
					ColorChat(id, TEAM_COLOR, "^x03[ ERROR ] ^x01You are already a ^x04Guard^x01." )
				}
				else
				{
					user_kill( id );
					cs_set_user_team(id, CS_TEAM_CT );
					_Dirhams[id] -= str_to_num(_shopMenu[item][1]);
					ColorChat(id, GREY, "^x04[ FG ]^x01 You have now ^x04:^x03 %s",_shopMenu[item][0]);
				}
			}
			else
			{
				hook_Menu( id )
				ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
				_Dirhams[id], str_to_num(_shopMenu[item][1]) - _Dirhams[id]); 
			}
		}
		case 5:
		{
			if( _Dirhams[id] >= str_to_num(_shopMenu[item][1]) ){
				
				if(!is_user_admin(id)){
					set_user_admin( id );
					_Dirhams[id] -= str_to_num(_shopMenu[item][1]);
					ColorChat(id, GREY, "^x04[ FG ]^x01 You have now ^x04:^x03 %s",_shopMenu[item][0]);
				}
				else
				{
					hook_Menu( id )
					ColorChat(id, GREY, "^x04[ FG ]^x01 You are already an^x04 Admin^x01 dumbass!");
					return PLUGIN_HANDLED;
				}
				
			}
			else
			{
				ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
				_Dirhams[id], str_to_num(_shopMenu[item][1]) - _Dirhams[id]); 
			}
		}
		case 6:
		{
			if( _Dirhams[id] >= str_to_num(_shopMenu[item][1]) ){
				
				buyPing[id] = true;
				_Dirhams[id] -= str_to_num(_shopMenu[item][1]);
				ColorChat(id, GREY, "^x04[ FG ]^x01 You have now ^x04:^x03 %s",_shopMenu[item][0]);
			}
			else
			{
				hook_Menu( id )
				ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
				_Dirhams[id], str_to_num(_shopMenu[item][1]) - _Dirhams[id]); 
			} 
			
		}
		case 7:
		{
			if( _Dirhams[id] >= str_to_num(_shopMenu[item][1]) ){
				
				buyParachute[id] = true;
				_Dirhams[id] -= str_to_num(_shopMenu[item][1]);
				ColorChat(id, GREY, "^x04[ FG ]^x01 You have now ^x04:^x03 %s",_shopMenu[item][0]);
			}
			else
			{
				hook_Menu( id )
				ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
				_Dirhams[id], str_to_num(_shopMenu[item][1]) - _Dirhams[id]); 
			} 
			
		}
	}
	
	return PLUGIN_CONTINUE;
}

@_Hat_menu(id){
	
	new callMenu_hat = menu_create( strconcat("\r[+] \wWelcome to Hats Menu \y<\r", "\y>"), "menu_handler_Hats" );
	
	for(new i; i < sizeof _HatMenu; i++){
		menu_additem( callMenu_hat, strconcat(_HatMenu[i][0], " \y<\r",_HatMenu[i][1], " \dDirhams \y>"), "", 0 );
	}
	
	menu_setprop( callMenu_hat, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, callMenu_hat, 0 );
	
}
public menu_handler_Hats( id, callMenu, item )
{
	
	if(item == MENU_EXIT)
	{
		menu_destroy(callMenu)
		return PLUGIN_HANDLED
	}
	
	if( _Dirhams[id] >= str_to_num(_HatMenu[item][1]) )
	{
		
		_Hats[id] = item;
		_Dirhams[id] -= str_to_num(_HatMenu[item][1]);
		
		setHat( id, _HatMenu[item][2] );
		ColorChat(id, GREY, "^x04[ FG ]^x01 You are wearing now ^x04:^x03 %s ^x04Hat",_HatMenu[item][0]);
		
		__@SaveHats(id);
		
	}
	else
	{
		ColorChat(id, GREY, "^x04[Dirhams] ^x01You don't have enough^x03 Dirhams ^x01[ ^x03->^x01 Current Dirhams : ^x04%d^x01 ][ Needed : ^x04%d^x01 ]", \
		_Dirhams[id], str_to_num(_HatMenu[item][1]) - _Dirhams[id]);  
		@_Hat_menu(id);
	}
	
	return PLUGIN_CONTINUE;
}
public Event_Flashlight(id)
{
	if( !is_user_alive(id) )
	{
		return PLUGIN_HANDLED;
	}
	
	if( g_HasBomb[id] == true && g_RoundEnded == false )
	{
		g_BombTimer[id] = 6;
		
		if( task_exists( BOMB + id ) || g_BombTimer[id] < 6 )
		{
			return PLUGIN_HANDLED;
		}
		
		set_task( 1.0, "CountDownExplode", BOMB + id, _, _, "b" )
	}
	
	return PLUGIN_CONTINUE;
}

public CountDownExplode(id)
{
	id -= BOMB
	
	if( !is_user_alive(id) || g_RoundEnded == true )
	{
		remove_task( id + BOMB )
		return PLUGIN_HANDLED;
	}
	
	if( g_BombTimer[id] > 1 )
	{
		if( g_BombTimer[id] > 2 )
		{
			emit_sound(id, CHAN_AUTO, gszC4, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		
		g_BombTimer[id] -= 1
		} else {
		Explode(id)
		
		new iPlayers[32], iNum, plr;
		get_players(iPlayers, iNum, "ah" )
		
		new origin[3];
		
		for( new i = 0; i < iNum; i++ )
		{
			plr = iPlayers[i]
			
			new origin2[3];
			
			get_user_origin( id, origin, 0 )
			get_user_origin( plr, origin2, 0 )
			
			if( get_distance( origin, origin2 ) <= 400 && is_user_alive(plr) )
			{
				
				if( (cs_get_user_team(id) != cs_get_user_team(plr)) )
				{
					user_silentkill(plr)
					
					Create_DeathMsg( plr, id )
				}
			}
		}
		
		user_silentkill(id)
		
		remove_task( id + BOMB )
	}
	
	return PLUGIN_HANDLED;
}

stock Explode(id)
{
	new origin[3]
	get_user_origin(id, origin, 0)
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_TAREXPLOSION)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	message_end()
}

public Create_DeathMsg( Victim, Attacker )
{
	message_begin(MSG_BROADCAST, get_user_msgid("DeathMsg"), {0,0,0});
	write_byte(Attacker);
	write_byte(Victim);
	write_byte(1)
	write_string("worldspawn");
	message_end();
}
public transfer_menu(id) 
{    

	new players_menu, players[32], num, i 
	get_players(players, num, "ch")   
	
	if (num <= 1) return PLUGIN_HANDLED;   
	
	
	new tempname[32], info[10]   
	new getNum[16]
	num_to_str( _Dirhams[id], getNum, 15 );
	
	players_menu = menu_create(strconcat("\r[FG] \wChoose a Player to donate:", "^n\rCurrent Dirhams \d: \r[\y", getNum, "\r]") ,
	"players_menu_handler")   

	for(i = 0; i < num; i++)  
	{        
		if(players[i] == id)            
			continue;  
		
		new getNum2[16]
		num_to_str( _Dirhams[players[i]], getNum2, 15 );
		
		get_user_name(players[i], tempname, 31)        
		num_to_str(players[i], info, 9)        
		menu_additem(players_menu, strconcat(tempname, " \r-> \y[\dDirhams : \r", getNum2, "\y]"), info, 0)     
	}        
	menu_setprop(players_menu, MPROP_EXIT, MEXIT_ALL)   
	
	menu_display(id, players_menu, 0)    
	return PLUGIN_CONTINUE 
} 

public players_menu_handler(id, players_menu, item) 
{  
	
	if(item == MENU_EXIT)    
	{        
		menu_destroy(players_menu)        
		return PLUGIN_HANDLED    
	}     
	
	new data[6]   
	new accessmenu, iName[32], callback ;
	
	menu_item_getinfo(players_menu, item, accessmenu, data, charsmax(data), iName, charsmax(iName), callback)  
	
	new player = str_to_num(data)   
	
	client_cmd(id, "messagemode ^"Transfer %d^"", player)   
	
	return PLUGIN_CONTINUE 
} 

public transfer_ammo(id) 
{
	new param[6]     
	read_argv(2, param, charsmax(param)) 
	
	for (new x; x < strlen(param); x++)     
		if(!isdigit(param[x]))                
		return 0;
	
	new amount = str_to_num(param)    
	
	new ammo = _Dirhams[id]  
	
	if (ammo < amount)     
	{              
		ColorChat(id, GREY, "^4[FG] ^1You Don't Have Enough Dirhams !")        
		return 0     
	}  
	
	read_argv(1, param, charsmax(param))    
	new player = str_to_num(param)  
	
	if(id == player) return PLUGIN_HANDLED;
	new player_ammo = _Dirhams[player] 
	
	_Dirhams[id] =  ammo - amount     
	_Dirhams[player] = player_ammo + amount;   
	
	new names[2][32]         
	
	get_user_name(id, names[0], charsmax(names[]))  
	get_user_name(player, names[1], charsmax(names[]))
	
	ColorChat(0, GREY, "^4[FG] ^1Player ^4 %s  ^1Donated ^4%d ^1Dirhams To Player ^4%s ^1!", names[0], amount, names[1])  
	
	return 0;
}

stock set_user_admin(target)
{
	new ident[33], pw[7], linne[150]
	formatex(pw, 6, "%d%d%d%d", random(9), random(9), random(9), random(9))
	
	new File[120]; get_configsdir(File, charsmax(File))
	add(File, charsmax(File), "/users.ini") 
	
	if(!file_exists(File))
		set_fail_state("File configs/users.ini Not Found")
	
	get_user_name(target, ident, charsmax(ident))
	formatex(linne, charsmax(linne), "^r^n^"%s^" ^"%s^" ^"%s^" ^"a^" // Auto added VIP ( from shop )", ident, pw, FLAGS)      
	
	client_print(target, print_console, "------------------- | Spawner System | -------------------")
	client_print(target, print_console, "[FG] You have been kicked because you have bought an Admin!")
	client_print(target, print_console, "[FG] Your password | setinfo is : %s", pw)
	client_print(target, print_console, "[FG] You should put in your console: setinfo _fg %s", pw)
	client_print(target, print_console, "-------------------------| # |-------------------------")
	
	server_cmd("kick #%d ^"You are an Admin now ! your password is setinfo _fg %s, [OPEN YOUR CONSOLE TO SEE MORE INFORMATIONS]^"", get_user_userid(target), pw)
	write_file(File, linne)
	
	server_cmd("amx_reloadadmins")
}

stock ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
	
	new wId = get_weaponid(weapon);
	if(!wId) return 0;
	
	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString,wEnt,"classname",weapon)) && pev(wEnt,pev_owner) != id) {}
	if(!wEnt) return 0;
	
	if(get_user_weapon(id) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon,wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem,id,wEnt)) return 0;
	ExecuteHamB(Ham_Item_Kill,wEnt);
	
	set_pev(id,pev_weapons,pev(id,pev_weapons) & ~(1<<wId));
	
	return 0;
}

stock parachute_reset(id)
{
	if(para_ent[id] > 0) 
	{
		if (is_valid_ent(para_ent[id])) 
		{
			remove_entity(para_ent[id])
		}
	}
	
	if(is_user_alive(id)) set_user_gravity(id, 1.0)
	para_ent[id] = 0
}


stock loadHat( id, MODEL[] ){
	
	new iEntity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) );
	
	_playerEnt[id] = iEntity;
	
	engfunc( EngFunc_SetModel, iEntity, MODEL );
	
	set_pev( iEntity, pev_movetype, MOVETYPE_FOLLOW );
	set_pev( iEntity, pev_aiment, id );
	set_pev( iEntity, pev_owner, id );
	
}

stock setHat( id, MODEL[] ){
	
	set_pev(_playerEnt[id], pev_effects, pev(_playerEnt[id], pev_effects) | EF_NODRAW)  
	loadHat( id, MODEL );
	set_pev(_playerEnt[id], pev_effects, pev(_playerEnt[id], pev_effects) & ~EF_NODRAW)  
	
}

stock set_user_ping(id, ping){
	
	if ( ping == -1 ) { 
		PingData[id] = 0; 
		return; 
	} 
	
	PingData[id] = 1 + ( ( id - 1 ) << 1 ); 
	
	PingData[id] |= clamp(ping, 0, 4095) << 6; 
	PingData[id] |= clamp(0, 0, 127) << 18;   
	
}

stock strconcat(...){
	new str[256];
	new it, NumArgs = numargs();
	for (new idx, ch; it < (sizeof(str) - 1) && idx < NumArgs; idx++)
	{
		new index;
		while ( it < (sizeof(str) - 1) && ( ch = getarg( idx, index++ ) ) != 0 )
			str[it++] = ch;
	}
	str[it] = 0;
	
	#emit LOAD.S.PRI 0x8
	#emit ADDR.ALT 0xC
	#emit ADD
	#emit LOAD.I
	#emit MOVE.ALT
	#emit ADDR.PRI str
	#emit MOVS 0x400
	#emit STACK 0x408
	#emit RETN
	
	return str;
}

__@SaveHats(id){
	
	new szMoney[12];      
	new szKey[40];  
	
	formatex( szKey , charsmax( szKey ) , "%sHATS1" , _Name[id] );
	formatex( szMoney , charsmax( szMoney ) , "%d" , _Hats[id] );
	
	nvault_set( g_Vault , szKey , szMoney );
	
}

__@SaveData(id)
{
	new valut = nvault_open("points2");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	new key[62], value[10], authid[33];
	
	get_user_name(id, authid, 32); 
	
	format(key, 61,"%s-points2", authid);
	format(value, 9,"%d", _Dirhams[id]);
	
	nvault_set(valut, key, value);
	nvault_close(valut);
	
}

__@LoadData( id )
{
	new valut = nvault_open("points2");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	new key[100], authid[33];
	
	get_user_name(id, authid, 32);
	
	formatex(key, 99,"%s-points2", authid);
	
	_Dirhams[id] = nvault_get(valut, key);
	
	nvault_close(valut);
	
}

__@SaveData_2(id)
{
	new valut = nvault_open("ping");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	new key[62], value[10], authid[33];
	
	get_user_name(id, authid, 32); 
	
	format(key, 61,"%s-ping", authid);
	format(value, 9,"%d", buyPing[id]);
	
	nvault_set(valut, key, value);
	nvault_close(valut);
	
}

__@LoadData_2( id )
{
	new valut = nvault_open("ping");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	new key[100], authid[33];
	
	get_user_name(id, authid, 32);
	
	formatex(key, 99,"%s-ping", authid);
	
	buyPing[id] = bool:nvault_get(valut, key);
	
	nvault_close(valut);
	
}

__@SaveData_3(id)
{
	new valut = nvault_open("fast");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	new key[62], value[10], authid[33];
	
	get_user_name(id, authid, 32); 
	
	format(key, 61,"%s-fast", authid);
	format(value, 9,"%d", buyParachute[id]);
	
	nvault_set(valut, key, value);
	nvault_close(valut);
	
}

__@LoadData_3( id )
{
	new valut = nvault_open("fast");
	
	if(valut == INVALID_HANDLE)
		set_fail_state("nValut returned invalid handle");
	
	new key[100], authid[33];
	
	get_user_name(id, authid, 32);
	
	formatex(key, 99,"%s-fast", authid);
	
	buyParachute[id] = bool:nvault_get(valut, key);
	
	nvault_close(valut);
	
}