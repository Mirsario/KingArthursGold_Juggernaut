//Crossbowman Include

namespace CrossbowmanParams
{
	enum Aim
	{
		ready = 0,
		firing,
		needsReload,
		reloading,
		stabbing
	}

	const ::s32 ready_time = 11;
	const ::s32 postFireDelay=	5;
	const ::s32 reloadTime=		30;

	const ::s32 shoot_period = 30;
	const ::s32 shoot_period_1 = CrossbowmanParams::shoot_period / 3;
	const ::s32 shoot_period_2 = 2 * CrossbowmanParams::shoot_period / 3;

	const ::s32 fired_time = 7;
	const ::f32 shoot_max_vel = 24.0f;
}

namespace ArrowType
{
	enum type
	{
		normal = 0,
		water,
		fire,
		bomb,
		count
	};
}

shared class CrossbowmanInfo
{
	s8 stateTime;
	s8 charge_time;
	u8 state;
	bool has_arrow;
	bool needsReload;
	u8 stab_delay;
	u8 fletch_cooldown;
	u8 arrow_type;
	bool dontHitMore;
	Vec2f attackDir;
	f32 attackRot;

	f32 cache_angle;

	CrossbowmanInfo()
	{
		dontHitMore=false;
		needsReload=false;
		stateTime=	0;
		charge_time = 0;
		state = 0;
		has_arrow = false;
		stab_delay = 0;
		fletch_cooldown = 0;
		arrow_type = ArrowType::normal;
		attackDir=	Vec2f(0,0);
		attackRot=	0.0f;
	}
};

const string[] arrowTypeNames = { "mat_arrows",
								"mat_waterarrows",
								"mat_firearrows",
								"mat_bombarrows"
								};

const string[] arrowNames = { "Regular arrows",
							"Water arrows",
							"Fire arrows",
							"Bomb arrow"
							};

const string[] arrowIcons = { "$Arrow$",
							"$WaterArrow$",
							"$FireArrow$",
							"$BombArrow$"
							};


bool hasArrows(CBlob@ this)
{
	CrossbowmanInfo@ crossbowman;
	if (!this.get("crossbowmanInfo", @crossbowman))
	{
		return false;
	}
	if (crossbowman.arrow_type >= 0 && crossbowman.arrow_type < arrowTypeNames.length)
	{
		return this.getBlobCount(arrowTypeNames[crossbowman.arrow_type]) > 0;
	}
	return false;
}

bool hasArrows(CBlob@ this, u8 arrowType)
{
	return this.getBlobCount(arrowTypeNames[arrowType]) > 0;
}

void SetArrowType(CBlob@ this, const u8 type)
{
	CrossbowmanInfo@ crossbowman;
	if (!this.get("crossbowmanInfo", @crossbowman))
	{
		return;
	}
	crossbowman.arrow_type = type;
}

u8 getArrowType(CBlob@ this)
{
	CrossbowmanInfo@ crossbowman;
	if (!this.get("crossbowmanInfo", @crossbowman))
	{
		return 0;
	}
	return crossbowman.arrow_type;
}
