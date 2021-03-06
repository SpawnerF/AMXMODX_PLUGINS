/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <okapi>

#define Con_Printf_linux "Con_Printf"
#define prefixProt "[HLDS-Shield][Lite]"

new const 	PLUGIN[]	= "Console String Blocker",
		VERSION[]	= "1.0",
		AUTHOR[]	= "SkillartzHD & Spawner";


new Array:cslBlock, g_ConsoleStr

new Con_Printf_f[] = {
	
	0x55,0x8B,0xEC,0xDEF,0xDEF,0xDEF,0xDEF,0xDEF,0xDEF,0x53,
	0x56,0x57,0xDEF,0x41,0xDEF,0xDEF,0x49,0xDEF,0xDEF,0x4D,
	0xDEF,0xDEF,0x45,0xDEF,0xDEF,0x5D,0xDEF,0xDEF,0xDEF,0xDEF,
	0x00,0x00,0x00,0xDEF,0xDEF,0xDEF,0xDEF,0xDEF,0xDEF,0xDEF,
	0xDEF,0xDEF,0xDEF,0xDEF
	
}

public plugin_init() {
	
	register_plugin
	(
		.plugin_name = PLUGIN, 
		.version     = VERSION, 
		.author      = AUTHOR
	)
	
	register_cvar("csl_blocker" , "1.0" ,
			FCVAR_SPONLY | FCVAR_SERVER
	);
	
}

public plugin_precache()	RegisterOkapi()

public plugin_cfg() {
	
	cslBlock = ArrayCreate(142, 1)
	
	new ConfigDir[142]
	get_configsdir(ConfigDir, charsmax(ConfigDir))
	format(ConfigDir, charsmax(ConfigDir), "%s/consoleStrBlocker.ini", ConfigDir) 
	
	
	new Data[37], File = fopen(ConfigDir, "rt")
	
	while (!feof(File)) {
		
		fgets(File, Data, charsmax(Data))
		
		trim(Data)
		if (Data[0] == ';' || !Data[0]) 
			continue;
		
		remove_quotes(Data)
		ArrayPushString(cslBlock,Data)
		g_ConsoleStr++
		
	}
	
	fclose(File)
	
}

public RegisterOkapi()
{
	new printf = okapi_engine_find_sig(Con_Printf_f,charsmax(Con_Printf_f))
	
	// linux
	if(is_linux_server())
	{
		okapi_add_hook(
		okapi_build_function(
		okapi_engine_get_symbol_ptr(Con_Printf_linux),arg_string,arg_string,arg_int),"Con_Printf_Hook")
		
	}
	else
	{
		if(printf)
		{
			okapi_add_hook(okapi_build_function(printf,arg_int,arg_string,arg_int),"Con_Printf_Hook")
		}
		else{
			server_print("%s Couldn't load [Con_Printf] Signature", prefixProt)
		}
	}
}
public Con_Printf_Hook( a[], b, c )
{
	// server_print("test : %d %d %d",a,b,c)
	
	if(b >= 9)
		return okapi_ret_supercede

	return okapi_ret_ignore
}

stock cmpStr( str[] ) {
	
	static strCsl[142], i
	
	for(i = 0; i < g_ConsoleStr; i++) {
		
		ArrayGetString(cslBlock, i, strCsl, charsmax(strCsl))
		
		if(containi(str, strCsl) != -1)
			return true
		
	}
	
	return false
}
