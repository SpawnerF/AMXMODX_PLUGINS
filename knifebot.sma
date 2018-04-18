#include < amxmodx >
#include < cstrike >
#include < engine >
#include < fakemeta >

#define PluginName 	 	"KnifeBot Detector"
#define Version 	 	"1.0"
#define Author 		 	"Spawner"

#define function<%0>(%1)	 %0(%1)

public 	plugin_init()
{
	register_plugin
	(
		.plugin_name 	= PluginName,
		.version 	= Version,
		.author		= Author
	);
}

public 	function<client_PreThink>(id)
{
	if(!is_user_alive(id)) 	return 	FMRES_IGNORED;
	
	#define PRESSED(%0) (((buttons & (%0)) == (%0)) && ((oldbuttons & (%0)) != (%0)))

	static 	buttons, oldbuttons;
	
	buttons 	= pev(id, pev_button);
	oldbuttons 	= pev(id, pev_oldbuttons);
	
	new 	iTarget , iBody;
	get_user_aiming( id , iTarget , iBody );
	
	if
	(
			( id != iTarget ) 		&&  	(1 <= iTarget <= 32)
			&&	get_user_weapon(id) 	== 	CSW_KNIFE
			&&	cs_get_user_team(id) 	!=	cs_get_user_team(iTarget)
	)	
	{
		new iDistance = get_players_dist(id, iTarget)

		if(PRESSED(IN_ATTACK))
		{
			client_print(id, print_chat, "[ATTACK1] %d", get_dist(id, iTarget));
			//if(?? <= iDistance <= ??){ }
		}
		else if(PRESSED(IN_ATTACK2))
		{
			client_print(id, print_chat, "[ATTACK2] %d", get_dist(id, iTarget) );
			//if(?? <= iDistance <= ??){ }
		}
		
	}
	
	return 	FMRES_IGNORED;
}

stock 	get_dist(id,iPlayer)
{
	static  origin1[ 3 ] ,
		origin2[ 3 ];
	
	get_user_origin( id , origin1 );
	get_user_origin( iPlayer , origin2 );
	
	return 	get_distance(origin1, origin2);
}
