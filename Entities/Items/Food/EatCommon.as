//Based on Base/Entities/Items/Food/EatCommon.as
//Changes: Added "cantEatFood" tag check.

const string heal_id = "heal command";

bool canEat(CBlob@ blob) {
	return blob.exists("eat sound");
}

// returns the healing amount of a certain food (in quarter hearts) or 0 for non-food
u8 getHealingAmount(CBlob@ food) {
	if (!canEat(food)) {
		return 0;
	}

	if (food.getName() == "heart") { // HACK
		return 4; // 1 heart
	}
	
	return 255; // full healing
}

void Heal(CBlob@ blob, CBlob@ food) {
	if(blob.hasTag("cantEatFood")) {
		return;
	}
	
	bool exists = getBlobByNetworkID(food.getNetworkID()) !is null;
	
	if(getNet().isServer() && blob.hasTag("player") && blob.getHealth() < blob.getInitialHealth() && !food.hasTag("healed") && exists) {
		CBitStream params;
		params.write_u16(blob.getNetworkID());
		params.write_u8(getHealingAmount(food));
		food.SendCommand(food.getCommandID(heal_id), params);

		food.Tag("healed");
	}
}
