#include "Accolades.as";

void EnableCustomHeadForUser(array<Accolades>@ accolades, string username)
{
	Accolades accolade(getAccoladesConfig(), username);
	
	accolade.customHeadExists = true;
	
	accolades.push_back(accolade);
}

void onInit(CRules@ this)
{
	LoadAccolades();

	array<Accolades>@ accolades = null;
	
	if (!getRules().get("accolades_array", @accolades)) {
		error("Unable to add mod developers as accolades - the array is missing.");
	}
	
	EnableCustomHeadForUser(accolades, "merser433");
	EnableCustomHeadForUser(accolades, "Koi_");
	
	print("Registered developer heads.");
}