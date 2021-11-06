#include "ModPath.as";

void LoadDefaultMapLoaders() {
	printf("### GAMEMODE " + sv_gamemode);

	//Use JuggernautPngLoader
	RegisterFileExtensionScript(MOD_PATH + "Scripts/MapLoaders/JuggernautPngLoader.as", "png");
	RegisterFileExtensionScript("Scripts/MapLoaders/GenerateFromKAGGen.as", "kaggen.cfg");
}