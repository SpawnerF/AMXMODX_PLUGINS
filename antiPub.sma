/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <ColorChat>

#define PLUGIN "Anti Pub"
#define VERSION "1.0"
#define AUTHOR "Spawner"


public plugin_init() {
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say", "hook_Say")
	register_clcmd("say_team", "hook_Say")
	
}

public hook_Say( id )
{
	new _arg[ 192 ];
	read_argv(id, _arg, charsmax( _arg ) );
	
	if( stringContainsIP( _arg ) )
	{
		ColorChat( id, GREY, "^1This message was blocked due to ^3advertissement." )
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

stock stringContainsIP(const szStr[ 192 ], bool:fixedSeparation = false, bool:ignoreNegatives = false, bool:ranges = true) // bool:ipMustHavePort = true
{
	new 
		i = 0, ch, lastCh, len = strlen(szStr), trueIPInts = 0, bool:isNumNegative = false, bool:numIsValid = true, // Invalid numbers are 1-1
		numberFound = -1, numLen = 0, numStr[5], numSize = sizeof(numStr),
		lastSpacingPos = -1, numSpacingDiff, numLastSpacingDiff, numSpacingDiffCount // -225\0 (4 len)
	;
	while(i <= len)
	{
		lastCh = ch;
		ch = szStr[i];
		if(ch >= '0' && ch <= '9' || (ranges == true && ch == '*')) {
			if(numIsValid && numLen < numSize) {
				if(lastCh == '-') {
					if(numLen == 0 && ignoreNegatives == false) {
						isNumNegative = true;
					}
					else if(numLen > 0) {
						numIsValid = false;
					}
				}
				numberFound = str_to_num(numStr);
				if(numLen == (3 + _:isNumNegative) && !(numberFound >= -255 && numberFound <= 255)) { // IP Num is valid up to 4 characters.. -255
					for(numLen = 3; numLen > 0; numLen--) {
						numStr[numLen] = EOS;
					}
				}
				else if(lastCh == '-' && ignoreNegatives) {
					i++;
					continue;
				} else {
					if(numLen == 0 && numIsValid == true && isNumNegative == true && lastCh == '-') {
						numStr[numLen++] = lastCh;
					}
					numStr[numLen++] = ch;
				}
			}
		} else {
			if(numLen && numIsValid) {
				numberFound = str_to_num(numStr);
				if(numberFound >= -255 && numberFound <= 255) {
					if(fixedSeparation) {
						if(lastSpacingPos != -1) {
							numLastSpacingDiff = numSpacingDiff;
							numSpacingDiff = i - lastSpacingPos - numLen;
							if(trueIPInts == 1 || numSpacingDiff == numLastSpacingDiff) {
								++numSpacingDiffCount;
							}
						}
						lastSpacingPos = i;
					}
					if(++trueIPInts >= 4) {
						break;
					}
				}
				for(numLen = 3; numLen > 0; numLen--) {
					numStr[numLen] = EOS;
				}
				isNumNegative = false;
			} else {
				numIsValid = true;
			}
		}
		i++;
	}
	if(fixedSeparation == true && numSpacingDiffCount < 3) {
		return 0;
	}
	return (trueIPInts >= 4);
}