#include "TradingCommon.as";
#include "Descriptions.as"

#define SERVER_ONLY

int coinsOnDamageAdd = 2;
int coinsOnKillAdd = 10;
int coinsOnDeathLose = 10;
int min_coins = 0;
int max_coins = 100;

//
string cost_config_file = "tdm_vars.cfg";

void onBlobCreated(CRules@ this, CBlob@ blob) {
	if (blob.getName() == "tradingpost") {
		MakeTradeMenu(blob);
	}
}

TradeItem@ addItemForCoin(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description) {
	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	
	if(item !is null && cost > 0) {
		AddRequirement(item.reqs, "coin", "", "Coins", cost);
		item.buyIntoInventory = true;
	}
	
	return item;
}

void MakeTradeMenu(CBlob@ trader) {
	s32 cost_bombs = 35;
	s32 cost_waterbombs = 30;
	s32 cost_keg = 80;
	s32 cost_mine = 40;

	s32 cost_arrows = 10;
	s32 cost_waterarrows = 40;
	s32 cost_firearrows = 40;
	s32 cost_bombarrows = 50;

	s32 cost_boulder = 25;
	s32 cost_burger = 75;
	s32 cost_sponge = 0;

	s32 cost_mountedbow = 100;
	s32 cost_drill = 75;
	s32 cost_catapult = -1;
	s32 cost_ballista = -1;

	s32 menu_width = 2;
	s32 menu_height = 4;

	// build menu
	CreateTradeMenu(trader, Vec2f(menu_width, menu_height), "Buy weapons");

	//
	addTradeSeparatorItem(trader, "$MENU_GENERIC$", Vec2f(3, 1));

	if (cost_bombs > 0)
		addItemForCoin(trader, "Bomb", cost_bombs, true, "$mat_bombs$", "mat_bombs", Descriptions::bomb);

	if (cost_waterbombs > 0)
		addItemForCoin(trader, "Water Bomb", cost_waterbombs, true, "$mat_waterbombs$", "mat_waterbombs", Descriptions::waterbomb);

	if (cost_keg > 0)
		addItemForCoin(trader, "Keg", cost_keg, true, "$keg$", "keg", Descriptions::keg);

	if (cost_mine > 0)
		addItemForCoin(trader, "Mine", cost_mine, true, "$mine$", "mine", Descriptions::mine);


	if (cost_arrows > 0)
		addItemForCoin(trader, "Arrows", cost_arrows, true, "$mat_arrows$", "mat_arrows", Descriptions::arrows);

	if (cost_waterarrows > 0)
		addItemForCoin(trader, "Water Arrows", cost_waterarrows, true, "$mat_waterarrows$", "mat_waterarrows", Descriptions::waterarrows);

	if (cost_firearrows > 0)
		addItemForCoin(trader, "Fire Arrows", cost_firearrows, true, "$mat_firearrows$", "mat_firearrows", Descriptions::firearrows);

	if (cost_bombarrows > 0)
		addItemForCoin(trader, "Bomb Arrow", cost_bombarrows, true, "$mat_bombarrows$", "mat_bombarrows", Descriptions::bombarrows);

	if (cost_sponge > 0)
		addItemForCoin(trader, "Sponge", cost_sponge, true, "$sponge$", "sponge", Descriptions::sponge);

	if (cost_mountedbow > 0)
		addItemForCoin(trader, "Mounted Bow", cost_mountedbow, true, "$mounted_bow$", "mounted_bow", Descriptions::mounted_bow);

	if (cost_drill > 0)
		addItemForCoin(trader, "Drill", cost_drill, true, "$drill$", "drill", Descriptions::drill);

	if (cost_boulder > 0)
		addItemForCoin(trader, "Boulder", cost_boulder, true, "$boulder$", "boulder", Descriptions::boulder);

	if (cost_burger > 0)
		addItemForCoin(trader, "Burger", cost_burger, true, "$food$", "food", Descriptions::burger);


	if (cost_catapult > 0)
		addItemForCoin(trader, "Catapult", cost_catapult, true, "$catapult$", "catapult", Descriptions::catapult);

	if (cost_ballista > 0)
		addItemForCoin(trader, "Ballista", cost_ballista, true, "$ballista$", "ballista", Descriptions::ballista);

}

// load coins amount

void Reset(CRules@ this) {
	coinsOnDamageAdd = 5;
	coinsOnKillAdd = 10;
	coinsOnDeathLose = 25;
	min_coins = 0;
	max_coins = 200;

	//clamp coin vars each round
	for (int i = 0; i < getPlayersCount(); i++) {
		CPlayer@ player = getPlayer(i);
		
		if(player is null) continue;

		s32 coins = player.getCoins();
		coins = Maths::Max(coins, min_coins);
		coins = Maths::Min(coins, max_coins);
		player.server_setCoins(coins);
	}

}

void onRestart(CRules@ this) {
	Reset(this);
}

void onInit(CRules@ this) {
	Reset(this);
}


void KillTradingPosts() {
	CBlob@[] tradingposts;
	bool found = false;
	
	if(getBlobsByName("tradingpost", @tradingposts)) {
		for (uint i = 0; i < tradingposts.length; i++) {
			CBlob @b = tradingposts[i];
			b.server_Die();
		}
	}
}

// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData) {
	if (victim !is null) {
		if (killer !is null) {
			if (killer !is victim && killer.getTeamNum() != victim.getTeamNum()) {
				killer.server_setCoins(killer.getCoins() + coinsOnKillAdd);
			}
		}
		
		victim.server_setCoins(victim.getCoins() - coinsOnDeathLose);
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale) {
	if (attacker !is null && attacker !is victim) {
		attacker.server_setCoins(attacker.getCoins() + DamageScale * coinsOnDamageAdd / this.attackdamage_modifier);
	}
	
	return DamageScale;
}
