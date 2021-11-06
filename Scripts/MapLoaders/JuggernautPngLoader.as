//This file implements loading of custom entities through adding new colors for maps to use.

#include "BasePNGLoader.as";

//Custom map colors
namespace Juggernaut
{
	//Colors are in ARGB HEX
	enum MapColor
	{
		Trader = 0xFF8888FF, //(136, 136, 255) / #8888FF
		TradingPost = 0xFFFF8888, //(255, 136, 136) / #FF8888
		ImpaledCorpse = 0xFF99423E, //(153, 66, 62) / #99423E
		RandomCorpse = 0xFF8E150F //(142, 21, 15) / #8E150F
	}
}

class JuggernautPngLoader : PNGLoader
{
	JuggernautPngLoader()
	{
		super();
	}

	void handlePixel(const SColor& in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);

		switch (pixel.color) {
			case Juggernaut::MapColor::Trader:
				autotile(offset);
				spawnBlob(map, "trader", offset, 0);
				break;
			case Juggernaut::MapColor::TradingPost:
				autotile(offset);
				spawnBlob(map, "tradingpost", offset, 0);
				break;
			case Juggernaut::MapColor::ImpaledCorpse:
				autotile(offset);
				spawnBlob(map, "impaledknight", offset, 0);
				break;
			case Juggernaut::RandomCorpse: {
				autotile(offset);

				string blobName;

				if (offset % 3 <= 1) {
					blobName = "randomcorpse";
				} else {
					if (offset % 2 == 0) {
						blobName = "corpsestill";
					} else {
						blobName = "corpsestillcrossbowman";
					}
				}

				spawnBlob(map, blobName, offset, 0);
				break;
			}
		};
	}
};

bool LoadMap(CMap@ map, const string &in fileName)
{
	print("### LOADING JUGGERNAUT PNG MAP " + fileName);

	Juggernaut::JuggernautPngLoader loader();

	return loader.loadMap(map, fileName);
}